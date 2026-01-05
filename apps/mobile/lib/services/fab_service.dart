import 'package:flutter/foundation.dart';

/// Serwis zarządzający widocznością głównego FABa zgłaszania błędów
class FabService extends ChangeNotifier {
  static final instance = FabService._();

  FabService._();

  String? _scannerError;

  /// Aktualny błąd skanera (powoduje wymuszenie pokazania FABa)
  String? get scannerError => _scannerError;

  /// Pokazuje FAB z powodu błędu
  void showError(String error) {
    if (_scannerError != error) {
      _scannerError = error;
      notifyListeners();
    }
  }

  /// Ukrywa wymuszony FAB (czyści błąd)
  void clearError() {
    if (_scannerError != null) {
      _scannerError = null;
      notifyListeners();
    }
  }
}
