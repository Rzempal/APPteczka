// medicine.dart v0.003 Added package units and opened date
import 'package:uuid/uuid.dart';

/// Jednostka ilości w opakowaniu
enum PackageUnit {
  none,    // Brak określonej ilości
  pieces,  // Sztuki (tabletki, kapsułki)
  ml,      // Mililitry (syropy, krople)
  sachets, // Saszetki
}

/// Opakowanie leku z własną datą ważności
class MedicinePackage {
  final String id;
  final String expiryDate; // ISO8601 ("2027-03-31")
  final bool isOpen; // true = otwarte, false = zamknięte (default)
  final int? pieceCount; // Ilość w opakowaniu (zależna od unit)
  final int? percentRemaining; // % pozostały (tylko dla otwartych)
  final PackageUnit unit; // Jednostka ilości
  final String? openedDate; // Data otwarcia (ISO8601, opcjonalne)

  MedicinePackage({
    String? id,
    required this.expiryDate,
    this.isOpen = false,
    this.pieceCount,
    this.percentRemaining,
    this.unit = PackageUnit.pieces,
    this.openedDate,
  }) : id = id ?? const Uuid().v4();

  /// Tworzy z formatu MM/YYYY → ISO ostatni dzień miesiąca
  factory MedicinePackage.fromMMYYYY(
    String mmyyyy, {
    bool isOpen = false,
    int? pieceCount,
    int? percentRemaining,
    PackageUnit unit = PackageUnit.pieces,
    String? openedDate,
  }) {
    final parts = mmyyyy.split('/');
    if (parts.length != 2) {
      throw FormatException('Invalid format: $mmyyyy. Expected MM/YYYY');
    }
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]);
    // Ostatni dzień miesiąca
    final lastDay = DateTime(year, month + 1, 0);
    return MedicinePackage(
      expiryDate: lastDay.toIso8601String().split('T')[0],
      isOpen: isOpen,
      pieceCount: pieceCount,
      percentRemaining: percentRemaining,
      unit: unit,
      openedDate: openedDate,
    );
  }

  factory MedicinePackage.fromJson(Map<String, dynamic> json) {
    // Parse unit with backward compatibility
    PackageUnit unit = PackageUnit.pieces;
    if (json['unit'] != null) {
      final unitStr = json['unit'] as String;
      unit = PackageUnit.values.firstWhere(
        (e) => e.name == unitStr,
        orElse: () => PackageUnit.pieces,
      );
    }

    return MedicinePackage(
      id: json['id'] as String?,
      expiryDate: json['expiryDate'] as String,
      isOpen: json['isOpen'] as bool? ?? false,
      pieceCount: json['pieceCount'] as int?,
      percentRemaining: json['percentRemaining'] as int?,
      unit: unit,
      openedDate: json['openedDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expiryDate': expiryDate,
      if (isOpen) 'isOpen': isOpen,
      if (pieceCount != null) 'pieceCount': pieceCount,
      if (percentRemaining != null) 'percentRemaining': percentRemaining,
      'unit': unit.name,
      if (openedDate != null) 'openedDate': openedDate,
    };
  }

  MedicinePackage copyWith({
    String? id,
    String? expiryDate,
    bool? isOpen,
    int? pieceCount,
    int? percentRemaining,
    PackageUnit? unit,
    String? openedDate,
    bool clearPieceCount = false,
    bool clearPercentRemaining = false,
    bool clearOpenedDate = false,
  }) {
    return MedicinePackage(
      id: id ?? this.id,
      expiryDate: expiryDate ?? this.expiryDate,
      isOpen: isOpen ?? this.isOpen,
      pieceCount: clearPieceCount ? null : (pieceCount ?? this.pieceCount),
      percentRemaining: clearPercentRemaining
          ? null
          : (percentRemaining ?? this.percentRemaining),
      unit: unit ?? this.unit,
      openedDate: clearOpenedDate ? null : (openedDate ?? this.openedDate),
    );
  }

  /// Formatuje datę jako MM/YYYY
  String get displayDate {
    final date = DateTime.tryParse(expiryDate);
    if (date == null) return expiryDate;
    return '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Parsuje datę do DateTime
  DateTime? get dateTime => DateTime.tryParse(expiryDate);

  /// Opis statusu opakowania
  String get remainingDescription {
    // Helper: jednostka w odpowiednim formacie
    String getUnitLabel() {
      switch (unit) {
        case PackageUnit.pieces:
          return 'szt.';
        case PackageUnit.ml:
          return 'ml';
        case PackageUnit.sachets:
          return 'saszetki';
        case PackageUnit.none:
          return '';
      }
    }

    // Helper: formatuje datę otwarcia
    String? formatOpenedDate() {
      if (openedDate == null) return null;
      try {
        final date = DateTime.parse(openedDate!);
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      } catch (_) {
        return null;
      }
    }

    final unitLabel = getUnitLabel();
    final openedDateStr = formatOpenedDate();

    if (isOpen) {
      // Opakowanie otwarte
      final parts = <String>[];

      if (openedDateStr != null) {
        parts.add('Otwarte od: $openedDateStr');
      } else {
        parts.add('Opakowanie otwarte');
      }

      if (percentRemaining != null) {
        parts.add('pozostało $percentRemaining%');
      } else if (pieceCount != null && unit != PackageUnit.none) {
        parts.add('pozostało $pieceCount $unitLabel');
      }

      return parts.join(', ');
    } else {
      // Opakowanie zamknięte
      if (pieceCount != null && unit != PackageUnit.none) {
        return 'Zamknięte: $pieceCount $unitLabel';
      }
      return 'Opakowanie zamknięte';
    }
  }
}

/// Model leku - zgodny z wersją web
class Medicine {
  final String id;
  final String? nazwa;
  final String opis;
  final List<String> wskazania;
  final List<String> tagi;
  final List<String> labels;
  final String? notatka;
  final List<MedicinePackage> packages;
  final String? _legacyTerminWaznosci; // For lazy migration
  final String? leafletUrl;
  final int? dailyIntake; // Dzienne zużycie tabletek
  final String dataDodania;
  final bool isVerifiedByBarcode; // Dane zweryfikowane po kodzie kreskowym (RPL)
  final String? verificationNote; // Monit o konflikcie nazwa/kod

  Medicine({
    required this.id,
    this.nazwa,
    required this.opis,
    required this.wskazania,
    required this.tagi,
    this.labels = const [],
    this.notatka,
    this.packages = const [],
    String? terminWaznosci,
    this.leafletUrl,
    this.dailyIntake,
    required this.dataDodania,
    this.isVerifiedByBarcode = false,
    this.verificationNote,
  }) : _legacyTerminWaznosci = terminWaznosci;

  /// Computed property - zwraca najkrótszą datę (wsteczna kompatybilność)
  String? get terminWaznosci {
    if (packages.isEmpty) return _legacyTerminWaznosci;
    // Znajdź najkrótszą datę
    return packages
        .map((p) => p.expiryDate)
        .reduce((a, b) => a.compareTo(b) < 0 ? a : b);
  }

  /// Zwraca posortowane opakowania (najkrótsza data pierwsza)
  List<MedicinePackage> get sortedPackages {
    final sorted = List<MedicinePackage>.from(packages);
    sorted.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return sorted;
  }

  /// Oblicza łączną liczbę sztuk ze wszystkich opakowań (tylko unit=pieces)
  int get totalPieceCount {
    int total = 0;
    for (final package in packages) {
      if (package.unit == PackageUnit.pieces && package.pieceCount != null) {
        total += package.pieceCount!;
      }
    }
    return total;
  }

  /// Kalkulator zapasu - oblicza do kiedy wystarczy leku (pierwszy dzien bez leku)
  /// Zwraca null jeśli brak danych (pieceCount lub dailyIntake)
  /// UWAGA: Działa tylko dla opakowań z unit=pieces
  DateTime? calculateSupplyEndDate() {
    if (dailyIntake == null || dailyIntake! <= 0) return null;
    final total = totalPieceCount; // Tylko unit=pieces
    if (total <= 0) return null;

    // ceil - ostatnia dawka + 1 dzień = pierwszy dzień bez leku
    final daysRemaining = (total / dailyIntake!).ceil();
    return DateTime.now().add(Duration(days: daysRemaining));
  }

  /// Tworzy z JSON (import/backup) - z lazy migration
  factory Medicine.fromJson(Map<String, dynamic> json) {
    final packagesJson = json['packages'] as List?;
    final legacyTermin = json['terminWaznosci'] as String?;

    List<MedicinePackage> packages = [];
    if (packagesJson != null && packagesJson.isNotEmpty) {
      packages = packagesJson.map((p) => MedicinePackage.fromJson(p)).toList();
    } else if (legacyTermin != null) {
      // Lazy migration: stary terminWaznosci → nowe packages
      packages = [MedicinePackage(expiryDate: legacyTermin)];
    }

    return Medicine(
      id: json['id'] as String,
      nazwa: json['nazwa'] as String?,
      opis: json['opis'] as String? ?? '',
      wskazania: List<String>.from(json['wskazania'] ?? []),
      tagi: List<String>.from(json['tagi'] ?? []),
      labels: List<String>.from(json['labels'] ?? []),
      notatka: json['notatka'] as String?,
      packages: packages,
      leafletUrl: json['leafletUrl'] as String?,
      dailyIntake: json['dailyIntake'] as int?,
      dataDodania:
          json['dataDodania'] as String? ?? DateTime.now().toIso8601String(),
      isVerifiedByBarcode: json['isVerifiedByBarcode'] as bool? ?? false,
      verificationNote: json['verificationNote'] as String?,
    );
  }

  /// Eksport do JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nazwa': nazwa,
      'opis': opis,
      'wskazania': wskazania,
      'tagi': tagi,
      'labels': labels,
      'notatka': notatka,
      'packages': packages.map((p) => p.toJson()).toList(),
      // Zachowaj terminWaznosci dla wstecznej kompatybilności
      'terminWaznosci': terminWaznosci,
      'leafletUrl': leafletUrl,
      if (dailyIntake != null) 'dailyIntake': dailyIntake,
      'dataDodania': dataDodania,
      if (isVerifiedByBarcode) 'isVerifiedByBarcode': isVerifiedByBarcode,
      if (verificationNote != null) 'verificationNote': verificationNote,
    };
  }

  /// Kopiuje z nowymi wartościami
  Medicine copyWith({
    String? id,
    String? nazwa,
    String? opis,
    List<String>? wskazania,
    List<String>? tagi,
    List<String>? labels,
    String? notatka,
    List<MedicinePackage>? packages,
    String? terminWaznosci,
    String? leafletUrl,
    int? dailyIntake,
    String? dataDodania,
    bool? isVerifiedByBarcode,
    String? verificationNote,
  }) {
    return Medicine(
      id: id ?? this.id,
      nazwa: nazwa ?? this.nazwa,
      opis: opis ?? this.opis,
      wskazania: wskazania ?? this.wskazania,
      tagi: tagi ?? this.tagi,
      labels: labels ?? this.labels,
      notatka: notatka ?? this.notatka,
      packages: packages ?? this.packages,
      terminWaznosci: terminWaznosci ?? _legacyTerminWaznosci,
      leafletUrl: leafletUrl ?? this.leafletUrl,
      dailyIntake: dailyIntake ?? this.dailyIntake,
      dataDodania: dataDodania ?? this.dataDodania,
      isVerifiedByBarcode: isVerifiedByBarcode ?? this.isVerifiedByBarcode,
      verificationNote: verificationNote ?? this.verificationNote,
    );
  }

  /// Sprawdza status terminu ważności (bazuje na najkrótszej dacie)
  ExpiryStatus get expiryStatus {
    final termin = terminWaznosci;
    if (termin == null) return ExpiryStatus.unknown;

    final expiry = DateTime.tryParse(termin);
    if (expiry == null) return ExpiryStatus.unknown;

    final now = DateTime.now();
    final daysUntilExpiry = expiry.difference(now).inDays;

    if (daysUntilExpiry < 0) return ExpiryStatus.expired;
    if (daysUntilExpiry <= 30) return ExpiryStatus.expiringSoon;
    return ExpiryStatus.valid;
  }

  /// Liczba opakowań
  int get packageCount => packages.isEmpty
      ? (_legacyTerminWaznosci != null ? 1 : 0)
      : packages.length;
}

/// Status terminu ważności
enum ExpiryStatus { valid, expiringSoon, expired, unknown }
