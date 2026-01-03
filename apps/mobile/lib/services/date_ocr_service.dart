import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Wynik rozpoznawania daty ważności
class DateOcrResult {
  final String? terminWaznosci;

  DateOcrResult({this.terminWaznosci});

  factory DateOcrResult.fromJson(Map<String, dynamic> json) {
    return DateOcrResult(
      terminWaznosci: json['terminWaznosci'] as String?,
    );
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
  // URL produkcyjny aplikacji webowej
  static const String _apiUrl =
      'https://pudelkonaleki.michalrapala.app/api/date-ocr';

  /// Rozpoznaje datę ważności ze zdjęcia
  Future<DateOcrResult> recognizeDate(File imageFile) async {
    try {
      // Odczytaj plik i zakoduj w base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(imageFile.path);

      // Wyślij do API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image, 'mimeType': mimeType}),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return DateOcrResult.fromJson(responseData);
      } else {
        final errorMessage =
            responseData['error'] as String? ?? 'Nieznany błąd';
        final errorCode = responseData['code'] as String? ?? 'API_ERROR';
        throw DateOcrException(errorMessage, errorCode);
      }
    } on SocketException {
      throw DateOcrException(
        'Brak połączenia z internetem. Sprawdź połączenie i spróbuj ponownie.',
        'NETWORK_ERROR',
      );
    } on FormatException {
      throw DateOcrException(
        'Błąd parsowania odpowiedzi serwera.',
        'PARSE_ERROR',
      );
    } catch (e) {
      if (e is DateOcrException) rethrow;
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
