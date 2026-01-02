import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Serwis do zbierania i wysyłania raportów błędów
class BugReportService {
  // Singleton
  static final BugReportService instance = BugReportService._();
  BugReportService._();

  // URL endpointu
  static const String _apiUrl =
      'https://pudelkonaleki.michalrapala.app/api/bug-report';

  // Circular buffer logów (max 100 wpisów)
  static const int _maxLogs = 100;
  final List<String> _logs = [];

  /// Dodaje wpis do logu
  void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    _logs.add('[$timestamp] $message');
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
  }

  /// Pobiera wszystkie logi jako string
  String getLogs() {
    return _logs.join('\n');
  }

  /// Czyści logi
  void clearLogs() {
    _logs.clear();
  }

  /// Przechwytuje screenshot widgetu
  Future<Uint8List?> captureScreenshot(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      log('Screenshot capture error: $e');
      return null;
    }
  }

  /// Pobiera informacje o urządzeniu
  Future<String> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return '${info.manufacturer} ${info.model} (Android ${info.version.release})';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return '${info.name} (iOS ${info.systemVersion})';
      }
      return 'Unknown device';
    } catch (e) {
      return 'Device info unavailable';
    }
  }

  /// Pobiera wersję aplikacji
  Future<String> getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Wysyła raport błędu
  Future<BugReportResult> sendReport({
    String? text,
    String? errorMessage,
    bool includeLogs = true,
    Uint8List? screenshot,
  }) async {
    try {
      log('Sending bug report...');

      final appVersion = await getAppVersion();
      final deviceInfo = await getDeviceInfo();

      final body = <String, dynamic>{
        'appVersion': appVersion,
        'deviceInfo': deviceInfo,
      };

      if (text != null && text.isNotEmpty) {
        body['text'] = text;
      }

      if (errorMessage != null && errorMessage.isNotEmpty) {
        body['errorMessage'] = errorMessage;
      }

      if (includeLogs && _logs.isNotEmpty) {
        body['log'] = getLogs();
      }

      if (screenshot != null) {
        body['screenshot'] = base64Encode(screenshot);
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        log('Bug report sent successfully');
        return BugReportResult.success();
      } else {
        final data = jsonDecode(response.body);
        final error = data['error'] ?? 'Nieznany błąd';
        log('Bug report failed: $error');
        return BugReportResult.failure(error);
      }
    } catch (e) {
      log('Bug report error: $e');
      return BugReportResult.failure('Błąd wysyłania: $e');
    }
  }
}

/// Wynik wysyłania raportu
class BugReportResult {
  final bool success;
  final String? error;

  BugReportResult._({required this.success, this.error});

  factory BugReportResult.success() => BugReportResult._(success: true);
  factory BugReportResult.failure(String error) =>
      BugReportResult._(success: false, error: error);
}
