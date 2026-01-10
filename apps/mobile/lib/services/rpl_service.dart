// rpl_service.dart v2.0.0 - Rejestr Produktow Leczniczych API
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

  RplDrugInfo({
    required this.name,
    required this.power,
    required this.form,
    required this.activeSubstance,
    required this.marketingAuthorisationHolder,
    this.atcCode,
    this.id,
  });

  factory RplDrugInfo.fromJson(Map<String, dynamic> json) {
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

  // ==================== WYSZUKIWANIE PO EAN/GTIN ====================

  /// Wyszukuje lek po kodzie EAN/GTIN
  Future<RplDrugInfo?> fetchDrugByEan(String ean) async {
    // Sprawdz cache
    if (_eanCache.containsKey(ean)) {
      _log.fine('Cache hit for EAN: $ean');
      return _eanCache[ean];
    }

    _log.info('Fetching drug info for EAN: $ean');

    // Walidacja EAN
    if (!_isValidEan(ean)) {
      _log.warning('Invalid EAN format: $ean');
      return null;
    }

    final payload = {
      'page': 1,
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
              'User-Agent': 'KartonZLekami/1.0',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      _log.fine('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        RplDrugInfo? result;

        // API moze zwrocic liste lub obiekt z polem 'content'
        if (data is List && data.isNotEmpty) {
          result = RplDrugInfo.fromJson(data[0] as Map<String, dynamic>);
        } else if (data is Map<String, dynamic>) {
          final content = data['content'];
          if (content is List && content.isNotEmpty) {
            result = RplDrugInfo.fromJson(content[0] as Map<String, dynamic>);
          }
        }

        // Zapisz w cache (takze null - zeby nie odpytywac ponownie)
        _eanCache[ean] = result;

        if (result != null) {
          _log.info('Found drug: ${result.fullName}');
        } else {
          _log.info('No drug found for EAN: $ean');
        }

        return result;
      } else if (response.statusCode == 429) {
        _log.warning('Rate limited by API');
        throw RplException(
          'Zbyt wiele zapytan. Poczekaj chwile i sprobuj ponownie.',
          'RATE_LIMITED',
        );
      } else {
        _log.warning('API error: ${response.statusCode}');
        throw RplException(
          'Blad serwera RPL: ${response.statusCode}',
          'API_ERROR',
        );
      }
    } on SocketException catch (e) {
      _log.severe('Network error', e);
      throw RplException(
        'Brak polaczenia z internetem. Sprawdz polaczenie i sprobuj ponownie.',
        'NETWORK_ERROR',
      );
    } on http.ClientException catch (e) {
      _log.severe('HTTP client error', e);
      throw RplException(
        'Blad polaczenia z serwerem.',
        'CONNECTION_ERROR',
      );
    } catch (e) {
      if (e is RplException) rethrow;
      _log.severe('Unexpected error', e);
      throw RplException('Nieoczekiwany blad: $e', 'UNKNOWN_ERROR');
    }
  }

  /// Waliduje format kodu EAN
  bool _isValidEan(String ean) {
    // EAN-13 lub EAN-8
    if (ean.length != 13 && ean.length != 8) {
      return false;
    }

    // Tylko cyfry
    if (!RegExp(r'^\d+$').hasMatch(ean)) {
      return false;
    }

    return true;
  }

  /// Sprawdza czy kod EAN jest prawdopodobnie polskim lekiem (590...)
  bool isPolishPharmaceutical(String ean) {
    return ean.startsWith('590');
  }

  /// Czysci cache EAN
  void clearEanCache() {
    _eanCache.clear();
    _log.fine('EAN cache cleared');
  }
}
