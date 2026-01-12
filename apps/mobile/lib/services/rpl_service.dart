// rpl_service.dart v2.2.0 - Rejestr Produktow Leczniczych API
// Serwis do wyszukiwania lekow po nazwie i kodzie EAN/GTIN

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'app_logger.dart';

/// Wynik wyszukiwania w Rejestrze Produktow Leczniczych (po nazwie)
class RplSearchResult {
  final int id;
  final String nazwa;
  final String moc;
  final String postac;
  final String ulotkaUrl;

  RplSearchResult({
    required this.id,
    required this.nazwa,
    required this.moc,
    required this.postac,
    required this.ulotkaUrl,
  });

  factory RplSearchResult.fromApiJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    return RplSearchResult(
      id: id,
      nazwa: json['medicinalProductName'] as String? ?? '',
      moc: json['medicinalProductPower'] as String? ?? '',
      postac: json['pharmaceuticalFormName'] as String? ?? '',
      ulotkaUrl:
          'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/$id/leaflet',
    );
  }

  /// Pelna nazwa leku z dawka (np. "Paracetamol 500mg")
  String get fullName {
    if (moc.isNotEmpty) {
      return '$nazwa $moc';
    }
    return nazwa;
  }

  /// Wyswietlana etykieta: nazwa + postac
  String get displayLabel => '$nazwa $moc'.trim();
  String get displaySubtitle => postac;
}

/// Opakowanie leku z RPL (packaging + GTIN)
class RplPackage {
  final String packaging;
  final String gtin;
  final String? accessibilityCategory; // "OTC", "Rp", "Rpz"

  RplPackage({
    required this.packaging,
    required this.gtin,
    this.accessibilityCategory,
  });

  factory RplPackage.fromJson(Map<String, dynamic> json) {
    return RplPackage(
      packaging: json['packaging'] as String? ?? '',
      gtin: json['gtin'] as String? ?? '',
      accessibilityCategory: json['accessibilityCategory'] as String?,
    );
  }
}

/// Szczegoly leku z RPL (z packages)
class RplDrugDetails {
  final int id;
  final String name;
  final String power;
  final String form;
  final String activeSubstance;
  final String marketingAuthorisationHolder;
  final String? accessibilityCategory;
  final List<RplPackage> packages;
  final String? leafletUrl;

  RplDrugDetails({
    required this.id,
    required this.name,
    required this.power,
    required this.form,
    required this.activeSubstance,
    required this.marketingAuthorisationHolder,
    this.accessibilityCategory,
    required this.packages,
    this.leafletUrl,
  });

  factory RplDrugDetails.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final packagesRaw = json['packages'] as List<dynamic>? ?? [];
    final packages = packagesRaw
        .map((p) => RplPackage.fromJson(p as Map<String, dynamic>))
        .toList();

    return RplDrugDetails(
      id: id,
      name: json['medicinalProductName'] as String? ?? '',
      power: json['medicinalProductPower'] as String? ?? '',
      form: json['pharmaceuticalFormName'] as String? ?? '',
      activeSubstance: json['activeSubstanceName'] as String? ?? '',
      marketingAuthorisationHolder:
          json['subjectMedicinalProductName'] as String? ?? '',
      accessibilityCategory: json['accessibilityCategory'] as String?,
      packages: packages,
      leafletUrl:
          'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/$id/leaflet',
    );
  }

  /// Pelna nazwa leku z dawka
  String get fullName {
    if (power.isNotEmpty) {
      return '$name $power';
    }
    return name;
  }

  /// Konwertuje do RplDrugInfo (dla kompatybilnosci)
  RplDrugInfo toRplDrugInfo({RplPackage? selectedPackage}) {
    return RplDrugInfo(
      id: id,
      name: name,
      power: power,
      form: form,
      activeSubstance: activeSubstance,
      marketingAuthorisationHolder: marketingAuthorisationHolder,
      accessibilityCategory:
          selectedPackage?.accessibilityCategory ?? accessibilityCategory,
      packaging: selectedPackage?.packaging ?? packages.firstOrNull?.packaging,
    );
  }
}

/// Informacje o leku z Rejestru Produktow Leczniczych (po EAN)
class RplDrugInfo {
  final String name;
  final String power;
  final String form;
  final String activeSubstance;
  final String marketingAuthorisationHolder;
  final String? atcCode;
  final int? id;
  // Nowe pola z details API
  final String? accessibilityCategory; // "OTC", "Rp", "Rpz"
  final String? packaging; // "28 tabl. (2 x 14)", "1 butelka 120 ml"

  RplDrugInfo({
    required this.name,
    required this.power,
    required this.form,
    required this.activeSubstance,
    required this.marketingAuthorisationHolder,
    this.atcCode,
    this.id,
    this.accessibilityCategory,
    this.packaging,
  });

  /// Tworzy RplDrugInfo z JSON.
  /// [targetEan] - opcjonalny kod EAN do dopasowania opakowania z listy packages[].
  factory RplDrugInfo.fromJson(Map<String, dynamic> json, {String? targetEan}) {
    // Parsowanie packaging z tablicy packages (jesli dostepna)
    String? packaging;
    final packages = json['packages'] as List<dynamic>?;
    if (packages != null && packages.isNotEmpty) {
      Map<String, dynamic>? matchedPackage;

      // Jesli mamy targetEan, szukaj dopasowania po gtin
      if (targetEan != null) {
        final targetNormalized = _stripLeadingZeros(targetEan);
        for (final pkg in packages) {
          final pkgMap = pkg as Map<String, dynamic>;
          final gtin = pkgMap['gtin'] as String?;
          if (gtin != null && _stripLeadingZeros(gtin) == targetNormalized) {
            matchedPackage = pkgMap;
            break;
          }
        }
      }

      // Fallback do pierwszego opakowania
      matchedPackage ??= packages[0] as Map<String, dynamic>;
      packaging = matchedPackage['packaging'] as String?;
    }

    return RplDrugInfo(
      id: json['id'] as int?,
      name: json['medicinalProductName'] as String? ??
          json['name'] as String? ??
          'Nieznana nazwa',
      power: json['medicinalProductPower'] as String? ??
          json['power'] as String? ??
          '',
      form: json['pharmaceuticalFormName'] as String? ??
          json['pharmaceuticalForm'] as String? ??
          '',
      activeSubstance: json['activeSubstanceName'] as String? ??
          json['activeSubstance'] as String? ??
          '',
      marketingAuthorisationHolder:
          json['subjectMedicinalProductName'] as String? ??
              json['marketingAuthorisationHolder'] as String? ??
              '',
      atcCode: json['atcCode'] as String?,
      accessibilityCategory: json['accessibilityCategory'] as String?,
      packaging: packaging,
    );
  }

  /// Kopiuje z nowymi wartosciami (merge details)
  RplDrugInfo copyWith({
    String? name,
    String? power,
    String? form,
    String? activeSubstance,
    String? marketingAuthorisationHolder,
    String? atcCode,
    int? id,
    String? accessibilityCategory,
    String? packaging,
  }) {
    return RplDrugInfo(
      name: name ?? this.name,
      power: power ?? this.power,
      form: form ?? this.form,
      activeSubstance: activeSubstance ?? this.activeSubstance,
      marketingAuthorisationHolder:
          marketingAuthorisationHolder ?? this.marketingAuthorisationHolder,
      atcCode: atcCode ?? this.atcCode,
      id: id ?? this.id,
      accessibilityCategory:
          accessibilityCategory ?? this.accessibilityCategory,
      packaging: packaging ?? this.packaging,
    );
  }

  /// Pelna nazwa leku z dawka (np. "Paracetamol 500mg")
  String get fullName {
    if (power.isNotEmpty) {
      return '$name $power';
    }
    return name;
  }

  /// Opis leku do wyswietlenia
  String get description {
    final parts = <String>[];
    if (form.isNotEmpty) parts.add(form);
    if (activeSubstance.isNotEmpty) parts.add('Substancja: $activeSubstance');
    if (marketingAuthorisationHolder.isNotEmpty) {
      parts.add('Producent: $marketingAuthorisationHolder');
    }
    return parts.join('\n');
  }

  /// URL do ulotki leku (jesli dostepne id)
  String? get leafletUrl {
    if (id != null) {
      return 'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/$id/leaflet';
    }
    return null;
  }

  /// Usuwa wiodace zera z kodu EAN/GTIN dla porownania
  /// Np. "05908229303481" -> "5908229303481"
  static String _stripLeadingZeros(String code) {
    return code.replaceFirst(RegExp('^0+'), '');
  }
}

/// Blad API RPL
class RplException implements Exception {
  final String message;
  final String code;

  RplException(this.message, [this.code = 'API_ERROR']);

  @override
  String toString() => message;
}

/// Serwis do wyszukiwania lekow w Rejestrze Produktow Leczniczych (CeZ)
class RplService {
  static final Logger _log = AppLogger.getLogger('RplService');

  // Oficjalny endpoint Rejestru Produktow Leczniczych (Centrum e-Zdrowia)
  static const String _baseUrl =
      'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products';

  static const String _searchUrl =
      'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/search/public';

  // Timeout dla zapytan
  static const Duration _timeout = Duration(seconds: 10);

  /// Cache wynikow EAN (EAN -> RplDrugInfo) - unika powtornych zapytan
  final Map<String, RplDrugInfo?> _eanCache = {};

  // ==================== WYSZUKIWANIE PO NAZWIE ====================

  /// Wyszukuje leki w RPL po nazwie
  /// [query] - Nazwa leku do wyszukania (min. 3 znaki)
  /// Zwraca liste pasujacych lekow z linkami do ulotek
  Future<List<RplSearchResult>> searchMedicine(String query) async {
    if (query.trim().length < 3) {
      return [];
    }

    final endpoint = Uri.parse(
      '$_baseUrl/search/public?name=${Uri.encodeComponent(query.trim())}&size=10&page=0',
    );

    try {
      final response = await http
          .get(endpoint, headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List<dynamic>?;

      if (content == null || content.isEmpty) {
        return [];
      }

      return content
          .map(
            (item) => RplSearchResult.fromApiJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      // Blad sieci lub parsowania - zwroc pusta liste
      _log.warning('Search error: $e');
      return [];
    }
  }

  // ==================== POBIERANIE SZCZEGOŁÓW PO ID ====================

  /// Pobiera szczegolowe informacje o leku po ID (publiczna metoda)
  /// Zwraca pelne dane leku wlacznie z lista opakowan (packages)
  Future<RplDrugDetails?> fetchDetailsById(int id) async {
    final endpoint = Uri.parse('$_baseUrl/search/public/details/$id');

    try {
      final response = await http
          .get(endpoint, headers: {
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
          })
          .timeout(_timeout);

      _log.fine('GET details by ID response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = RplDrugDetails.fromJson(data);
        _log.info(
            'Fetched details by ID: ${result.fullName}, packages: ${result.packages.length}');
        return result;
      } else {
        _log.warning('GET details by ID error: ${response.statusCode}');
      }
    } catch (e) {
      _log.warning('GET details by ID error: $e');
    }

    return null;
  }

  // ==================== WYSZUKIWANIE PO EAN/GTIN ====================

  /// Wyszukuje lek po kodzie EAN/GTIN
  /// Prubuje kilka endpointow API RPL, nastepnie pobiera szczegoly
  Future<RplDrugInfo?> fetchDrugByEan(String ean) async {
    // Normalizacja EAN - UPC-A (12 cyfr) -> EAN-13 (dodaj wiodace zero)
    final normalizedEan = _normalizeEan(ean);
    if (normalizedEan == null) {
      _log.warning('Invalid EAN format: $ean');
      return null;
    }

    // Sprawdz cache
    if (_eanCache.containsKey(normalizedEan)) {
      _log.fine('Cache hit for EAN: $normalizedEan');
      return _eanCache[normalizedEan];
    }

    _log.info('Fetching drug info for EAN: $normalizedEan (original: $ean)');

    // Proba 1: GET z parametrem eanGtin (glowna metoda - dziala!)
    var result = await _tryFetchByGtinGet(normalizedEan);
    if (result == null) {
      // Proba 2: POST do search/public (fallback)
      result = await _tryFetchByGtinPost(normalizedEan);
    }

    if (result != null) {
      // Pobierz szczegoly (accessibilityCategory, packaging, activeSubstance)
      // Przekaz normalizedEan do dopasowania opakowania po GTIN
      if (result.id != null) {
        final details = await _fetchDetails(result.id!, targetEan: normalizedEan);
        if (details != null) {
          result = result.copyWith(
            accessibilityCategory: details.accessibilityCategory,
            packaging: details.packaging,
            activeSubstance: details.activeSubstance.isNotEmpty
                ? details.activeSubstance
                : result.activeSubstance,
          );
        }
      }
      _eanCache[normalizedEan] = result;
      return result;
    }

    // Nie znaleziono - zapisz null w cache
    _eanCache[normalizedEan] = null;
    _log.info('No drug found for EAN: $normalizedEan');
    return null;
  }

  /// Pobiera szczegolowe informacje o leku po ID
  /// [targetEan] - kod EAN do dopasowania opakowania z listy packages[]
  Future<RplDrugInfo?> _fetchDetails(int id, {String? targetEan}) async {
    final endpoint = Uri.parse('$_baseUrl/search/public/details/$id');

    try {
      final response = await http
          .get(endpoint, headers: {
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
          })
          .timeout(_timeout);

      _log.fine('GET details response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = RplDrugInfo.fromJson(data, targetEan: targetEan);
        _log.info(
            'Fetched details: accessibilityCategory=${result.accessibilityCategory}, packaging=${result.packaging}');
        return result;
      } else {
        _log.warning('GET details error: ${response.statusCode}');
      }
    } catch (e) {
      _log.warning('GET details error: $e');
    }

    return null;
  }

  /// Normalizuje kod EAN - konwertuje UPC-A na EAN-13
  String? _normalizeEan(String ean) {
    // Usun spacje i inne znaki
    final cleaned = ean.replaceAll(RegExp(r'[^0-9]'), '');

    // UPC-A (12 cyfr) -> EAN-13 (dodaj wiodace zero)
    if (cleaned.length == 12) {
      return '0$cleaned';
    }

    // EAN-13 lub EAN-8
    if (cleaned.length == 13 || cleaned.length == 8) {
      return cleaned;
    }

    return null;
  }

  /// Proba GET z parametrem eanGtin (glowna metoda - dziala!)
  Future<RplDrugInfo?> _tryFetchByGtinGet(String ean) async {
    // Poprawny endpoint i parametry zgodnie z dokumentacja API
    final endpoint = Uri.parse(
      '$_baseUrl/search/public?eanGtin=${Uri.encodeComponent(ean)}&isAdvancedSearch=false&size=10&page=0',
    );

    try {
      final response = await http
          .get(endpoint, headers: {
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
          })
          .timeout(_timeout);

      _log.fine('GET eanGtin response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List<dynamic>?;

        if (content != null && content.isNotEmpty) {
          // API filtruje po eanGtin po stronie serwera - bierzemy pierwszy wynik
          final result =
              RplDrugInfo.fromJson(content[0] as Map<String, dynamic>);
          _log.info('Found drug via GET: ${result.fullName}');
          return result;
        }
      } else {
        _log.warning('GET eanGtin error: ${response.statusCode}');
      }
    } catch (e) {
      _log.warning('GET eanGtin error: $e');
    }

    return null;
  }

  /// Proba POST do search/public
  Future<RplDrugInfo?> _tryFetchByGtinPost(String ean) async {
    // Oryginalny format z dokumentacji - searchValues z konkretnym polem gtin
    final payload = {
      'page': 0,
      'size': 10,
      'searchValues': [
        {'name': 'gtin', 'value': ean}
      ]
    };

    try {
      final response = await http
          .post(
            Uri.parse(_searchUrl),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
              'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
              'Origin': 'https://rejestrymedyczne.ezdrowie.gov.pl',
              'Referer': 'https://rejestrymedyczne.ezdrowie.gov.pl/rpl/search/public',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      _log.fine('POST search response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        RplDrugInfo? result;

        if (data is List && data.isNotEmpty) {
          result = RplDrugInfo.fromJson(data[0] as Map<String, dynamic>);
        } else if (data is Map<String, dynamic>) {
          final content = data['content'];
          if (content is List && content.isNotEmpty) {
            // API filtruje po gtin po stronie serwera - bierzemy pierwszy wynik
            result =
                RplDrugInfo.fromJson(content[0] as Map<String, dynamic>);
          }
        }

        if (result != null) {
          _log.info('Found drug via POST: ${result.fullName}');
          return result;
        }
      } else if (response.statusCode == 500) {
        _log.warning('API RPL zwrocilo blad 500 - serwer chwilowo niedostepny');
      } else {
        _log.warning('POST response: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      _log.severe('Network error', e);
      throw RplException(
        'Brak polaczenia z internetem.',
        'NETWORK_ERROR',
      );
    } catch (e) {
      _log.warning('POST search error: $e');
    }

    return null;
  }

  /// Sprawdza czy kod EAN jest prawdopodobnie polskim lekiem (590...)
  bool isPolishPharmaceutical(String ean) {
    final normalized = _normalizeEan(ean);
    return normalized != null && normalized.startsWith('590');
  }

  /// Czysci cache EAN
  void clearEanCache() {
    _eanCache.clear();
    _log.fine('EAN cache cleared');
  }
}
