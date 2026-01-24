# 📝 System Logowania

> **Powiązane:** [Architektura](architecture.md) | [Wdrożenie](deployment.md)

---

## Poziomy Logów

| Poziom      | Zastosowanie                            |
| ----------- | --------------------------------------- |
| **FINE**    | Debug, szczegóły techniczne (tylko dev) |
| **INFO**    | Informacje o zdarzeniach                |
| **WARNING** | Ostrzeżenia, problemy niekrytyczne      |
| **SEVERE**  | Błędy krytyczne                         |

> **Uwaga:** Nazwy poziomów pochodzą z pakietu `logging` Dart SDK.

---

## Logowanie z Flutter (Dart)

```dart
import 'services/app_logger.dart';

// Pobierz logger dla swojej klasy
final _log = AppLogger.getLogger('MyService');

// Użycie
_log.info('Operacja zakończona');
_log.warning('Brak danych');
_log.severe('Błąd krytyczny', error, stackTrace);
```

---

## Logowanie z natywnego Androida (Kotlin)

### MainActivity.kt

```kotlin
// 1. Zdefiniuj MethodChannel
private val CHANNEL = "app.karton/file_intent"
private var methodChannel: MethodChannel? = null

// 2. Funkcja logująca
private fun log(message: String) {
    methodChannel?.invokeMethod("log", "[MainActivity] $message")
}

// 3. Użycie
log("onNewIntent: action=$action, data=$data")
```

### main.dart (odbiór logów)

```dart
_fileIntentChannel.setMethodCallHandler((call) async {
  if (call.method == 'log') {
    final message = call.arguments as String?;
    if (message != null) {
      AppLogger.addNativeLog(message);  // Dodaj do buffera
    }
  }
});
```

---

## Gdzie szukać logów

| Źródło            | Lokalizacja                          |
| ----------------- | ------------------------------------ |
| Flutter (release) | **Ustawienia → Logi aplikacji**      |
| Flutter (debug)   | Konsola `flutter run`                |
| Android natywny   | Logcat: `adb logcat -s MainActivity` |

---

## Szybki debug - checklist

```markdown
1. [ ] Dodaj log w Kotlin: `log("debug: $zmienna")`
2. [ ] Przebuduj APK
3. [ ] Wykonaj akcję na telefonie
4. [ ] Sprawdź: Ustawienia → Logi aplikacji
```

---

> 📅 **Ostatnia aktualizacja:** 2026-01-24
