// gemini_name_lookup_service.dart
// Serwis do rozpoznawania leków po nazwie przez Gemini API

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'app_logger.dart';
import 'gemini_service.dart'; // Używamy ScannedMedicine i GeminiException

/// Wynik wyszukiwania leku po nazwie
class NameLookupResult {
  final bool found;
  final ScannedMedicine? medicine;
  final String? reason;

  NameLookupResult.found(ScannedMedicine med)
    : found = true,
      medicine = med,
      reason = null;

  NameLookupResult.notFound(String message)
    : found = false,
      medicine = null,
      reason = message;
}

/// Serwis do wyszukiwania leków po nazwie przez Gemini API
class GeminiNameLookupService {
  static final Logger _log = AppLogger.getLogger('GeminiNameLookupService');

  // URL produkcyjny aplikacji webowej
  static const String _apiUrl =
      'https://pudelkonaleki.michalrapala.app/api/gemini-name-lookup';

  /// Wyszukuje lek na podstawie nazwy
  Future<NameLookupResult> lookupByName(String name) async {
    _log.info('Looking up medicine by name: $name');

    try {
      // Wyślij do API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      );

      _log.fine('Response status: ${response.statusCode}');

      // Próba parsowania JSON z obsługą błędów
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException catch (e) {
        _log.severe('JSON parse error', e);
        _log.warning('Response body: ${response.body}');
        throw GeminiException(
          'Błąd parsowania odpowiedzi serwera. Status: ${response.statusCode}',
          'PARSE_ERROR',
        );
      }

      // Obsługa błędów HTTP
      if (response.statusCode != 200) {
        final errorMessage =
            responseData['error'] as String? ?? 'Nieznany błąd';
        final errorCode = responseData['code'] as String? ?? 'API_ERROR';
        _log.warning('API error: $errorCode - $errorMessage');
        throw GeminiException(errorMessage, errorCode);
      }

      // Parsowanie odpowiedzi
      final status = responseData['status'] as String?;

      if (status == 'rozpoznano') {
        final lekData = responseData['lek'] as Map<String, dynamic>;
        final productType = responseData['productType'] as String?;
        final medicine = ScannedMedicine(
          productType: productType,
          nazwa: lekData['nazwa'] as String?,
          power: lekData['power'] as String?,
          capacity: lekData['capacity'] as String?,
          postacFarmaceutyczna: lekData['postacFarmaceutyczna'] as String?,
          opis: lekData['opis'] as String? ?? '',
          wskazania: List<String>.from(lekData['wskazania'] ?? []),
          tagi: List<String>.from(lekData['tagi'] ?? []),
          terminWaznosci: null, // Name lookup nie zwraca daty
        );
        _log.info('Medicine found: ${medicine.nazwa} (type: $productType)');
        return NameLookupResult.found(medicine);
      }

      if (status == 'nie_rozpoznano') {
        final reason =
            responseData['reason'] as String? ?? 'Nie rozpoznano produktu.';
        _log.info('Medicine not found: $reason');
        return NameLookupResult.notFound(reason);
      }

      // Nieoczekiwany format
      throw GeminiException(
        'Nieoczekiwany format odpowiedzi od serwera.',
        'PARSE_ERROR',
      );
    } on SocketException catch (e) {
      _log.severe('Network error (SocketException)', e);
      throw GeminiException(
        'Brak połączenia z internetem. Sprawdź połączenie i spróbuj ponownie.',
        'NETWORK_ERROR',
      );
    } catch (e, stackTrace) {
      if (e is GeminiException) rethrow;
      _log.severe('Unexpected error', e, stackTrace);
      throw GeminiException('Błąd połączenia: $e', 'API_ERROR');
    }
  }
}
