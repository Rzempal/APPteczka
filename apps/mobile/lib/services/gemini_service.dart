// gemini_service.dart v0.003 Added EAN field to ScannedMedicine

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'app_logger.dart';

/// Wynik skanowania Gemini
class GeminiScanResult {
  final List<ScannedMedicine> leki;

  GeminiScanResult({required this.leki});

  factory GeminiScanResult.fromJson(Map<String, dynamic> json) {
    final lekiList = json['leki'] as List<dynamic>? ?? [];
    return GeminiScanResult(
      leki: lekiList
          .map((item) => ScannedMedicine.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Pojedynczy lek rozpoznany przez Gemini
class ScannedMedicine {
  final String? nazwa;
  final String? ean;
  final String opis;
  final List<String> wskazania;
  final List<String> tagi;
  final String? terminWaznosci;

  ScannedMedicine({
    this.nazwa,
    this.ean,
    required this.opis,
    required this.wskazania,
    required this.tagi,
    this.terminWaznosci,
  });

  factory ScannedMedicine.fromJson(Map<String, dynamic> json) {
    return ScannedMedicine(
      nazwa: json['nazwa'] as String?,
      ean: json['ean'] as String?,
      opis: json['opis'] as String? ?? '',
      wskazania: List<String>.from(json['wskazania'] ?? []),
      tagi: List<String>.from(json['tagi'] ?? []),
      terminWaznosci: json['terminWaznosci'] as String?,
    );
  }
}

/// Błąd Gemini API
class GeminiException implements Exception {
  final String message;
  final String code;

  GeminiException(this.message, [this.code = 'API_ERROR']);

  @override
  String toString() => message;
}

/// Serwis do komunikacji z Gemini API przez Vercel
class GeminiService {
  static final Logger _log = AppLogger.getLogger('GeminiService');

  // URL produkcyjny aplikacji webowej
  static const String _apiUrl =
      'https://pudelkonaleki.michalrapala.app/api/gemini-ocr';

  /// Skanuje zdjęcie i rozpoznaje leki
  Future<GeminiScanResult> scanImage(File imageFile) async {
    _log.info('Starting single image scan');

    try {
      // Odczytaj plik i zakoduj w base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(imageFile.path);

      _log.fine('Image encoded: ${bytes.length}B, mimeType=$mimeType');

      // Wyślij do API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image, 'mimeType': mimeType}),
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

      if (response.statusCode == 200) {
        final result = GeminiScanResult.fromJson(responseData);
        _log.info('Scan success: found ${result.leki.length} medicines');
        return result;
      } else {
        final errorMessage =
            responseData['error'] as String? ?? 'Nieznany błąd';
        final errorCode = responseData['code'] as String? ?? 'API_ERROR';
        _log.warning('API error: $errorCode - $errorMessage');
        throw GeminiException(errorMessage, errorCode);
      }
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
