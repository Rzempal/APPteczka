# 📝 System Logowania (APPteczka)

> **Powiązane:** [Debug Standard](standards/debug.md) | [Architektura](architecture.md) |
> [Wdrożenie](deployment.md)

---

## Poziomy Logów

Szczegóły poziomów: **[standards/debug.md#poziomy-logów](standards/debug.md#poziomy-logów)**

---

## Logowanie z Flutter (Dart)

Szczegóły wzorca AppLogger:
**[standards/debug.md#applogger-pattern](standards/debug.md#applogger-pattern)**

```dart
import 'services/app_logger.dart';

final _log = AppLogger.getLogger('MyService');
_log.info('Operacja zakończona');
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

| Źródło            | Lokalizacja                           |
| ----------------- | ------------------------------------- |
| Flutter (release) | **Ustawienia → Zaawansowane → Debug** |
| Flutter (debug)   | Konsola `flutter run`                 |
| Android natywny   | Logcat: `adb logcat -s MainActivity`  |

---

## Szybki debug - checklist

```markdown
1. [ ] Dodaj log w Kotlin: `log("debug: $zmienna")`
2. [ ] Przebuduj APK
3. [ ] Wykonaj akcję na telefonie
4. [ ] Sprawdź: Ustawienia → Zaawansowane → Debug
```

---

> 📅 **Ostatnia aktualizacja:** 2026-01-24
