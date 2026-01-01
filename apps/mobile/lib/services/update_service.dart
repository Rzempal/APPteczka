import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';

/// Service for checking and installing OTA updates.
/// Version format: YYYYMMDD_HHMM (e.g., 20251230_2248)
class UpdateService extends ChangeNotifier {
  static const String _versionUrl =
      'https://michalrapala.app/releases/version.json';

  String? _currentVersion;
  String? _currentVersionName; // Full version like 0.1.253651505
  String? _latestVersion;
  String? _apkUrl;
  bool _updateAvailable = false;
  double _downloadProgress = 0.0;
  UpdateStatus _status = UpdateStatus.idle;
  String? _errorMessage;
  DateTime? _lastCheckTime;
  bool _isUpToDate = false;

  // Getters
  String? get currentVersion => _currentVersion;
  String? get currentVersionName => _currentVersionName; // User-visible version
  String? get latestVersion => _latestVersion;
  bool get updateAvailable => _updateAvailable;
  double get downloadProgress => _downloadProgress;
  UpdateStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DateTime? get lastCheckTime => _lastCheckTime;
  bool get isUpToDate => _isUpToDate;

  /// Initialize and load current app version, then check for updates
  Future<void> init() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      // buildNumber for comparison (versionCode: yyDDDHHmm)
      _currentVersion = packageInfo.buildNumber;
      // version for display (versionName: 0.1.253651505)
      _currentVersionName = packageInfo.version;
      notifyListeners();

      // Auto-check for updates on init
      await checkForUpdate();
    } catch (e) {
      debugPrint('UpdateService init error: $e');
    }
  }

  /// Check for updates by fetching version.json from server
  Future<bool> checkForUpdate() async {
    _status = UpdateStatus.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_versionUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _latestVersion = data['version'] as String?;
        _apkUrl = data['apkUrl'] as String?;

        // Read versionCode from JSON for comparison (yyDDDHHmm format)
        final latestVersionCode = data['versionCode'] as int?;

        if (latestVersionCode != null && _currentVersion != null) {
          // Parse current version (buildNumber) as int for comparison
          final currentVersionCode = int.tryParse(_currentVersion!) ?? 0;
          _updateAvailable = latestVersionCode > currentVersionCode;
          _isUpToDate = !_updateAvailable;
        }

        _lastCheckTime = DateTime.now();
        _status = UpdateStatus.idle;
        notifyListeners();
        return _updateAvailable;
      } else {
        _errorMessage = 'Błąd serwera: ${response.statusCode}';
        _status = UpdateStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Błąd połączenia: $e';
      _status = UpdateStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Compare two version strings in YYYYMMDD_HHMM format
  /// Returns: >0 if v1 > v2, <0 if v1 < v2, 0 if equal
  int _compareVersions(String v1, String v2) {
    // Simple string comparison works for YYYYMMDD_HHMM format
    return v1.compareTo(v2);
  }

  /// Start downloading and installing the update
  Future<void> startUpdate() async {
    if (_apkUrl == null) {
      _errorMessage = 'Brak URL do pobrania';
      _status = UpdateStatus.error;
      notifyListeners();
      return;
    }

    _status = UpdateStatus.downloading;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      OtaUpdate()
          .execute(_apkUrl!, destinationFilename: 'karton_z_lekami_update.apk')
          .listen(
            (OtaEvent event) {
              switch (event.status) {
                case OtaStatus.DOWNLOADING:
                  _downloadProgress = double.tryParse(event.value ?? '0') ?? 0;
                  _status = UpdateStatus.downloading;
                  notifyListeners();
                  break;
                case OtaStatus.INSTALLING:
                  _status = UpdateStatus.installing;
                  notifyListeners();
                  break;
                case OtaStatus.INSTALLATION_DONE:
                  _status = UpdateStatus.idle;
                  notifyListeners();
                  break;
                case OtaStatus.ALREADY_RUNNING_ERROR:
                  _errorMessage = 'Aktualizacja już w toku';
                  _status = UpdateStatus.error;
                  notifyListeners();
                  break;
                case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                  _errorMessage = 'Brak uprawnień do instalacji';
                  _status = UpdateStatus.error;
                  notifyListeners();
                  break;
                case OtaStatus.INTERNAL_ERROR:
                  _errorMessage = 'Błąd wewnętrzny: ${event.value}';
                  _status = UpdateStatus.error;
                  notifyListeners();
                  break;
                case OtaStatus.DOWNLOAD_ERROR:
                  _errorMessage = 'Błąd pobierania: ${event.value}';
                  _status = UpdateStatus.error;
                  notifyListeners();
                  break;
                case OtaStatus.CHECKSUM_ERROR:
                  _errorMessage = 'Błąd sumy kontrolnej';
                  _status = UpdateStatus.error;
                  notifyListeners();
                  break;
                case OtaStatus.INSTALLATION_ERROR:
                  _errorMessage = 'Błąd instalacji: ${event.value}';
                  _status = UpdateStatus.error;
                  notifyListeners();
                  break;
                case OtaStatus.CANCELED:
                  _errorMessage = 'Pobieranie anulowane';
                  _status = UpdateStatus.error;
                  notifyListeners();
                  break;
              }
            },
            onError: (e) {
              _errorMessage = 'Błąd: $e';
              _status = UpdateStatus.error;
              notifyListeners();
            },
          );
    } catch (e) {
      _errorMessage = 'Błąd uruchomienia aktualizacji: $e';
      _status = UpdateStatus.error;
      notifyListeners();
    }
  }

  /// Reset update state
  void reset() {
    _updateAvailable = false;
    _downloadProgress = 0.0;
    _status = UpdateStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}

enum UpdateStatus { idle, checking, downloading, installing, error }
