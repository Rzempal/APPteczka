// gemini_dual_service.dart v0.002 Replaced print() with AppLogger

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'app_logger.dart';

/// Wynik rozpoznania leku z 2 zdjęć (front + data)
class GeminiDualResult {
  final String? nazwa;
  final String opis;
  final List<String> wskazania;
  final List<String> tagi;
  final String? terminWaznosci;

  GeminiDualResult({
    this.nazwa,
    required this.opis,
    required this.wskazania,
    required this.tagi,
    this.terminWaznosci,
  });

  factory GeminiDualResult.fromJson(Map<String, dynamic> json) {
    return GeminiDualResult(
      nazwa: json['nazwa'] as String?,
      opis: json['opis'] as String? ?? 'Stosować zgodnie z ulotką.',
      wskazania:
          (json['wskazania'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tagi:
          (json['tagi'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      terminWaznosci: json['terminWaznosci'] as String?,
    );
  }
}

/// Błąd Gemini Dual OCR API
class GeminiDualException implements Exception {
  final String message;
  final String code;

  GeminiDualException(this.message, [this.code = 'API_ERROR']);

  @override
  String toString() => message;
}

/// Serwis do rozpoznawania leku + daty z 2 zdjęć przez Gemini API
class GeminiDualService {
  static final Logger _log = AppLogger.getLogger('GeminiDualService');

  // URL produkcyjny aplikacji webowej
  static const String _apiUrl =
      'https://pudelkonaleki.michalrapala.app/api/gemini-ocr-dual';

  /// Rozpoznaje lek i datę ważności z 2 zdjęć w jednym wywołaniu
  Future<GeminiDualResult> scanMedicineWithDate(
    File frontImage,
    File dateImage,
  ) async {
    _log.info('Starting dual scan');

    try {
      // Enkoduj oba zdjęcia do Base64
      final frontBytes = await frontImage.readAsBytes();
      final frontBase64 = base64Encode(frontBytes);
      final frontMimeType = _getMimeType(frontImage.path);

      final dateBytes = await dateImage.readAsBytes();
      final dateBase64 = base64Encode(dateBytes);
      final dateMimeType = _getMimeType(dateImage.path);

      _log.fine(
        'Images encoded: front=${frontBytes.length}B, date=${dateBytes.length}B',
      );

      // Wyślij request do API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'frontImage': frontBase64,
          'frontMimeType': frontMimeType,
          'dateImage': dateBase64,
          'dateMimeType': dateMimeType,
        }),
      );

      _log.fine('Response status: ${response.statusCode}');
      _log.fine(
        'Response body (first 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
      );

      // Próba parsowania JSON z obsługą błędów
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException catch (e) {
        _log.severe('JSON parse error', e);
        _log.warning('Full response body: ${response.body}');
        throw GeminiDualException(
          'Błąd parsowania odpowiedzi serwera. Status: ${response.statusCode}',
          'PARSE_ERROR',
        );
      }

      if (response.statusCode == 200) {
        final result = GeminiDualResult.fromJson(responseData);
        _log.info(
          'Scan success: ${result.nazwa ?? "no name"}, exp=${result.terminWaznosci}',
        );
        return result;
      } else {
        final errorMessage =
            responseData['error'] as String? ?? 'Nieznany błąd';
        final errorCode = responseData['code'] as String? ?? 'API_ERROR';
        _log.warning('API error: $errorCode - $errorMessage');
        throw GeminiDualException(errorMessage, errorCode);
      }
    } on GeminiDualException {
      rethrow;
    } catch (e, stackTrace) {
      _log.severe('Connection error', e, stackTrace);
      throw GeminiDualException('Błąd połączenia: $e', 'NETWORK_ERROR');
    }
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
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
