// bug_report_service.dart v0.002 Integrated with AppLogger

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'app_logger.dart';

/// Kategoria zgłoszenia
enum ReportCategory {
  bug(LucideIcons.bug, 'Bug', 'Coś nie działa'),
  suggestion(LucideIcons.lightbulb, 'Sugestia', 'Mam pomysł'),
  question(
    LucideIcons.messageCircleQuestionMark,
    'Pytanie',
    'Potrzebuję pomocy',
  );

  final IconData icon;
  final String label;
  final String description;
  const ReportCategory(this.icon, this.label, this.description);
}

/// Serwis do zbierania i wysyłania raportów błędów
class BugReportService {
  // Singleton
  static final BugReportService instance = BugReportService._();
  static final Logger _log = AppLogger.getLogger('BugReportService');

  BugReportService._();

  // URL endpointu
  static const String _apiUrl =
      'https://pudelkonaleki.michalrapala.app/api/bug-report';

  // UWAGA: Logi są teraz przechowywane w AppLogger.
  // Metody log(), getLogs(), clearLogs() zachowane dla kompatybilności wstecznej,
  // ale delegują do AppLoggera.

  /// Dodaje wpis do logu (deleguje do AppLogger)
  @Deprecated('Use AppLogger.getLogger() instead')
  void log(String message) {
    _log.info(message);
  }

  /// Pobiera wszystkie logi jako string (z AppLogger)
  String getLogs() {
    return AppLogger.getLogBuffer();
  }

  /// Czyści logi
  void clearLogs() {
    AppLogger.clearBuffer();
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
      _log.warning('Screenshot capture error: $e');
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
      return info.version;
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Wysyła raport błędu
  Future<BugReportResult> sendReport({
    String? text,
    String? topic,
    String? errorMessage,
    ReportCategory category = ReportCategory.bug,
    String? replyEmail,
    bool includeLogs = true,
    Uint8List? screenshot,
  }) async {
    try {
      _log.info('Sending bug report (category=${category.name})');

      final appVersion = await getAppVersion();
      final deviceInfo = await getDeviceInfo();

      final body = <String, dynamic>{
        'appVersion': appVersion,
        'deviceInfo': deviceInfo,
        'category': category.name,
        'channel': const String.fromEnvironment(
          'CHANNEL',
          defaultValue: 'production',
        ),
      };

      if (replyEmail != null && replyEmail.isNotEmpty) {
        body['replyEmail'] = replyEmail;
      }

      if (text != null && text.isNotEmpty) {
        body['text'] = text;
      }

      if (topic != null && topic.isNotEmpty) {
        body['topic'] = topic;
      }

      if (errorMessage != null && errorMessage.isNotEmpty) {
        body['errorMessage'] = errorMessage;
      }

      // Pobierz logi z AppLoggera
      if (includeLogs) {
        final logs = AppLogger.getLogBuffer();
        if (logs.isNotEmpty) {
          body['log'] = logs;
          _log.fine('Including ${AppLogger.bufferSize} log entries');
        }
      }

      if (screenshot != null) {
        body['screenshot'] = base64Encode(screenshot);
        _log.fine('Including screenshot (${screenshot.length}B)');
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      _log.fine('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _log.info('Bug report sent successfully');
        return BugReportResult.success();
      } else {
        // Bezpieczne parsowanie odpowiedzi
        String errorMsg = 'Błąd serwera (${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            errorMsg = data['error'] ?? errorMsg;
          } catch (_) {
            // Ignoruj błędy parsowania
          }
        }
        _log.warning('Bug report failed: $errorMsg');
        return BugReportResult.failure(errorMsg);
      }
    } on SocketException catch (e) {
      _log.severe('Network error', e);
      return BugReportResult.failure('Brak połączenia z internetem');
    } catch (e, stackTrace) {
      _log.severe('Unexpected error', e, stackTrace);
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
