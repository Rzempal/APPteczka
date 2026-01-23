import 'package:flutter/foundation.dart';

/// Globalny serwis do kontroli stanu pauzy skanera kodów kreskowych.
///
/// Używany gdy user otwiera modalne okna edycji (np. szczegóły opakowania),
/// aby skaner w tle nie triggerował monitów "Nie rozpoznano".
class ScannerPauseService extends ChangeNotifier {
  ScannerPauseService._();
  static final ScannerPauseService instance = ScannerPauseService._();

  bool _isPaused = false;

  /// Czy skaner jest obecnie spauzowany
  bool get isPaused => _isPaused;

  /// Pauzuje skaner (wywołaj przed otwarciem modalnego okna edycji)
  void pauseScanner() {
    if (!_isPaused) {
      _isPaused = true;
      notifyListeners();
    }
  }

  /// Wznawia skaner (wywołaj po zamknięciu modalnego okna edycji)
  void resumeScanner() {
    if (_isPaused) {
      _isPaused = false;
      notifyListeners();
    }
  }
}
