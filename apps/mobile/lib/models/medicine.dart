/// Model leku - zgodny z wersją web
class Medicine {
  final String id;
  final String? nazwa;
  final String opis;
  final List<String> wskazania;
  final List<String> tagi;
  final List<String> labels;
  final String? notatka;
  final String? terminWaznosci;
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
    this.terminWaznosci,
    this.leafletUrl,
    required this.dataDodania,
  });

  /// Tworzy z JSON (import/backup)
  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      nazwa: json['nazwa'] as String?,
      opis: json['opis'] as String? ?? '',
      wskazania: List<String>.from(json['wskazania'] ?? []),
      tagi: List<String>.from(json['tagi'] ?? []),
      labels: List<String>.from(json['labels'] ?? []),
      notatka: json['notatka'] as String?,
      terminWaznosci: json['terminWaznosci'] as String?,
      leafletUrl: json['leafletUrl'] as String?,
      dataDodania: json['dataDodania'] as String? ?? DateTime.now().toIso8601String(),
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
      terminWaznosci: terminWaznosci ?? this.terminWaznosci,
      leafletUrl: leafletUrl ?? this.leafletUrl,
      dataDodania: dataDodania ?? this.dataDodania,
    );
  }

  /// Sprawdza status terminu ważności
  ExpiryStatus get expiryStatus {
    if (terminWaznosci == null) return ExpiryStatus.unknown;
    
    final expiry = DateTime.tryParse(terminWaznosci!);
    if (expiry == null) return ExpiryStatus.unknown;
    
    final now = DateTime.now();
    final daysUntilExpiry = expiry.difference(now).inDays;
    
    if (daysUntilExpiry < 0) return ExpiryStatus.expired;
    if (daysUntilExpiry <= 30) return ExpiryStatus.expiringSoon;
    return ExpiryStatus.valid;
  }
}

/// Status terminu ważności
enum ExpiryStatus {
  valid,
  expiringSoon,
  expired,
  unknown,
}
