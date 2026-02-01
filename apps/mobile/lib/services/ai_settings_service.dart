// ai_settings_service.dart
// Centralny gateway dla ustawień AI (Toggle AI)
// Architektura gotowa na przyszłą integrację z paywall/subskrypcją Pro

import 'package:logging/logging.dart';
import 'app_logger.dart';
import 'storage_service.dart';

/// Dostępne funkcje AI w aplikacji
enum AiFeature {
  /// Name Lookup + Background Queue Processing
  nameLookup,

  /// Barcode Scanner Fallback (gdy EAN nieznany)
  barcodeFallback,

  /// Product Photo OCR (rozpoznawanie produktu ze zdjęcia)
  productPhoto,

  /// Expiry Date OCR (rozpoznawanie daty ważności)
  expiryDateOcr,

  /// Shelf Life Analysis (analiza ulotki PDF)
  shelfLifeAnalysis,
}

/// Wyjątek rzucany gdy funkcja AI jest wyłączona
class AiDisabledException implements Exception {
  final AiFeature feature;
  final bool isGloballyDisabled;

  AiDisabledException(this.feature, {this.isGloballyDisabled = false});

  /// Przyjazna wiadomość dla użytkownika
  String get userMessage {
    if (isGloballyDisabled) {
      return 'Funkcje AI są wyłączone w ustawieniach deweloperskich.';
    }
    final featureName = switch (feature) {
      AiFeature.nameLookup => 'Wyszukiwanie po nazwie',
      AiFeature.barcodeFallback => 'Rozpoznawanie kodu kreskowego',
      AiFeature.productPhoto => 'Rozpoznawanie ze zdjęcia',
      AiFeature.expiryDateOcr => 'OCR daty ważności',
      AiFeature.shelfLifeAnalysis => 'Analiza ulotki',
    };
    return 'Funkcja "$featureName" jest wyłączona w ustawieniach deweloperskich.';
  }

  /// Kod błędu dla logowania
  String get code => 'AI_DISABLED';

  @override
  String toString() => userMessage;
}

/// Centralny serwis zarządzający dostępem do funkcji AI
///
/// Singleton sprawdzający uprawnienia przed wywołaniem API.
/// Architektura gotowa na przyszłą integrację z paywall.
class AiSettingsService {
  static final Logger _log = AppLogger.getLogger('AiSettingsService');
  static AiSettingsService? _instance;

  final StorageService _storage;

  AiSettingsService._(this._storage);

  /// Inicjalizuje singleton z podanym StorageService
  static void initialize(StorageService storage) {
    _instance = AiSettingsService._(storage);
    _log.info('AiSettingsService initialized');
  }

  /// Pobiera instancję singleton
  static AiSettingsService get instance {
    if (_instance == null) {
      throw StateError(
        'AiSettingsService not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  /// Sprawdza czy dana funkcja AI jest włączona
  bool isFeatureEnabled(AiFeature feature) {
    // Najpierw sprawdź globalny toggle
    if (!_storage.aiEnabled) {
      _log.fine('AI globally disabled');
      return false;
    }

    // Sprawdź granularny toggle dla funkcji
    final enabled = switch (feature) {
      AiFeature.nameLookup => _storage.aiNameLookupEnabled,
      AiFeature.barcodeFallback => _storage.aiBarcodeFallbackEnabled,
      AiFeature.productPhoto => _storage.aiProductPhotoEnabled,
      AiFeature.expiryDateOcr => _storage.aiExpiryDateOcrEnabled,
      AiFeature.shelfLifeAnalysis => _storage.aiShelfLifeEnabled,
    };

    _log.fine('Feature ${feature.name} enabled: $enabled');
    return enabled;
  }

  /// Rzuca wyjątek jeśli funkcja AI jest wyłączona
  ///
  /// Użycie na początku metody serwisu AI:
  /// ```dart
  /// AiSettingsService.instance.assertFeatureEnabled(AiFeature.nameLookup);
  /// ```
  void assertFeatureEnabled(AiFeature feature) {
    if (!_storage.aiEnabled) {
      _log.warning('AI disabled globally, blocking ${feature.name}');
      throw AiDisabledException(feature, isGloballyDisabled: true);
    }

    if (!isFeatureEnabled(feature)) {
      _log.warning('Feature ${feature.name} disabled, blocking request');
      throw AiDisabledException(feature);
    }
  }

  /// Czy globalny toggle AI jest włączony
  bool get isAiEnabled => _storage.aiEnabled;
}
