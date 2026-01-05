import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

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
  // URL produkcyjny aplikacji webowej
  static const String _apiUrl =
      'https://pudelkonaleki.michalrapala.app/api/gemini-ocr-dual';

  /// Rozpoznaje lek i datę ważności z 2 zdjęć w jednym wywołaniu
  Future<GeminiDualResult> scanMedicineWithDate(
    File frontImage,
    File dateImage,
  ) async {
    try {
      // Enkoduj oba zdjęcia do Base64
      final frontBytes = await frontImage.readAsBytes();
      final frontBase64 = base64Encode(frontBytes);
      final frontMimeType = _getMimeType(frontImage.path);

      final dateBytes = await dateImage.readAsBytes();
      final dateBase64 = base64Encode(dateBytes);
      final dateMimeType = _getMimeType(dateImage.path);

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

      // Diagnostyka
      print('[GeminiDual] Status: ${response.statusCode}');
      print(
        '[GeminiDual] Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
      );

      // Próba parsowania JSON z obsługą błędów
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException catch (e) {
        print('[GeminiDual] JSON parse error: $e');
        print('[GeminiDual] Full response body: ${response.body}');
        throw GeminiDualException(
          'Błąd parsowania odpowiedzi serwera. Status: ${response.statusCode}',
          'PARSE_ERROR',
        );
      }

      if (response.statusCode == 200) {
        return GeminiDualResult.fromJson(responseData);
      } else {
        final errorMessage =
            responseData['error'] as String? ?? 'Nieznany błąd';
        final errorCode = responseData['code'] as String? ?? 'API_ERROR';
        throw GeminiDualException(errorMessage, errorCode);
      }
    } on GeminiDualException {
      rethrow;
    } catch (e) {
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
