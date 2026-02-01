// date_ocr_service.dart v0.002 Added AppLogger integration

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'ai_settings_service.dart';
import 'app_logger.dart';

/// Wynik rozpoznawania daty ważności
class DateOcrResult {
  final String? terminWaznosci;

  DateOcrResult({this.terminWaznosci});

  factory DateOcrResult.fromJson(Map<String, dynamic> json) {
    return DateOcrResult(terminWaznosci: json['terminWaznosci'] as String?);
  }
}

/// Błąd Date OCR API
class DateOcrException implements Exception {
  final String message;
  final String code;

  DateOcrException(this.message, [this.code = 'API_ERROR']);

  @override
  String toString() => message;
}

/// Serwis do rozpoznawania daty ważności ze zdjęcia przez Gemini API
class DateOcrService {
  static final Logger _log = AppLogger.getLogger('DateOcrService');

  // URL produkcyjny aplikacji webowej
  static const String _apiUrl =
      'https://pudelkonaleki.michalrapala.app/api/date-ocr';

  /// Rozpoznaje datę ważności ze zdjęcia
  Future<DateOcrResult> recognizeDate(File imageFile) async {
    // Sprawdź czy funkcja AI jest włączona
    AiSettingsService.instance.assertFeatureEnabled(AiFeature.expiryDateOcr);

    _log.info('Starting date recognition');

    try {
      // Odczytaj plik i zakoduj w base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(imageFile.path);

      _log.fine('Image encoded: ${bytes.length}B');

      // Wyślij do API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image, 'mimeType': mimeType}),
      );

      _log.fine('Response status: ${response.statusCode}');

      // Próba parsowania JSON
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException catch (e) {
        _log.severe('JSON parse error', e);
        _log.warning('Response body: ${response.body}');
        throw DateOcrException(
          'Błąd parsowania odpowiedzi serwera. Status: ${response.statusCode}',
          'PARSE_ERROR',
        );
      }

      if (response.statusCode == 200) {
        final result = DateOcrResult.fromJson(responseData);
        _log.info('Date recognized: ${result.terminWaznosci ?? "none"}');
        return result;
      } else {
        final errorMessage =
            responseData['error'] as String? ?? 'Nieznany błąd';
        final errorCode = responseData['code'] as String? ?? 'API_ERROR';
        _log.warning('API error: $errorCode - $errorMessage');
        throw DateOcrException(errorMessage, errorCode);
      }
    } on SocketException catch (e) {
      _log.severe('Network error', e);
      throw DateOcrException(
        'Brak połączenia z internetem. Sprawdź połączenie i spróbuj ponownie.',
        'NETWORK_ERROR',
      );
    } catch (e, stackTrace) {
      if (e is DateOcrException) rethrow;
      _log.severe('Unexpected error', e, stackTrace);
      throw DateOcrException('Błąd połączenia: $e', 'API_ERROR');
    }
  }

  /// Określa typ MIME na podstawie rozszerzenia
  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
