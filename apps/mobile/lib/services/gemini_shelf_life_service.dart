// gemini_shelf_life_service.dart
// Serwis do analizy terminu ważności po otwarciu przez Gemini API

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'app_logger.dart';
import 'gemini_service.dart'; // Używamy GeminiException

/// Wynik analizy terminu ważności
class ShelfLifeResult {
  final bool found;
  final String? shelfLife;  // Dosłowny cytat z ulotki
  final String? period;     // Okres w formacie naturalnym (np. "6 miesięcy")
  final String? reason;

  ShelfLifeResult.found({
    required String shelfLife,
    required String period,
  })  : found = true,
        shelfLife = shelfLife,
        period = period,
        reason = null;

  ShelfLifeResult.notFound(String message)
      : found = false,
        shelfLife = null,
        period = null,
        reason = message;
}

/// Serwis do analizy terminu ważności po otwarciu przez Gemini API
class GeminiShelfLifeService {
  static final Logger _log = AppLogger.getLogger('GeminiShelfLifeService');

  // URL produkcyjny aplikacji webowej
  static const String _apiUrl =
      'https://pudelkonaleki.michalrapala.app/api/gemini-shelf-life';

  /// Analizuje ulotkę PDF w celu znalezienia terminu ważności po otwarciu
  Future<ShelfLifeResult> analyzeLeaflet(String pdfUrl) async {
    _log.info('Analyzing shelf life from leaflet: $pdfUrl');

    try {
      // Wyślij do API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pdfUrl': pdfUrl}),
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

      if (status == 'znaleziono') {
        final shelfLife = responseData['shelfLife'] as String?;
        final period = responseData['period'] as String?;

        if (shelfLife == null || period == null) {
          throw GeminiException(
            'Niepełne dane w odpowiedzi serwera',
            'PARSE_ERROR',
          );
        }

        _log.info('Shelf life found: $period');
        return ShelfLifeResult.found(
          shelfLife: shelfLife,
          period: period,
        );
      }

      if (status == 'nie_znaleziono') {
        final reason = responseData['reason'] as String? ??
            'W ulotce nie znaleziono informacji o terminie ważności po pierwszym otwarciu.';
        _log.info('Shelf life not found: $reason');
        return ShelfLifeResult.notFound(reason);
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
