import 'package:uuid/uuid.dart';

/// Opakowanie leku z własną datą ważności
class MedicinePackage {
  final String id;
  final String expiryDate; // ISO8601 ("2027-03-31")
  final int? pieceCount; // Ilość sztuk (tabletki)
  final int? percentRemaining; // % pozostały (syropy)

  MedicinePackage({
    String? id,
    required this.expiryDate,
    this.pieceCount,
    this.percentRemaining,
  }) : id = id ?? const Uuid().v4();

  /// Tworzy z formatu MM/YYYY → ISO ostatni dzień miesiąca
  factory MedicinePackage.fromMMYYYY(
    String mmyyyy, {
    int? pieceCount,
    int? percentRemaining,
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
      pieceCount: pieceCount,
      percentRemaining: percentRemaining,
    );
  }

  factory MedicinePackage.fromJson(Map<String, dynamic> json) {
    return MedicinePackage(
      id: json['id'] as String?,
      expiryDate: json['expiryDate'] as String,
      pieceCount: json['pieceCount'] as int?,
      percentRemaining: json['percentRemaining'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expiryDate': expiryDate,
      if (pieceCount != null) 'pieceCount': pieceCount,
      if (percentRemaining != null) 'percentRemaining': percentRemaining,
    };
  }

  MedicinePackage copyWith({
    String? id,
    String? expiryDate,
    int? pieceCount,
    int? percentRemaining,
  }) {
    return MedicinePackage(
      id: id ?? this.id,
      expiryDate: expiryDate ?? this.expiryDate,
      pieceCount: pieceCount ?? this.pieceCount,
      percentRemaining: percentRemaining ?? this.percentRemaining,
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

  /// Opis opcjonalnej wartości (sztuki lub %)
  String? get remainingDescription {
    if (pieceCount != null) return '$pieceCount szt.';
    if (percentRemaining != null) return '$percentRemaining%';
    return null;
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
  final String dataDodania;

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
    required this.dataDodania,
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
      dataDodania:
          json['dataDodania'] as String? ?? DateTime.now().toIso8601String(),
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
      'dataDodania': dataDodania,
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
    String? dataDodania,
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
      dataDodania: dataDodania ?? this.dataDodania,
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
