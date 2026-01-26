# OTA Update System - Instrukcja Implementacji dla Aplikacji Desktopowej Flutter

## Architektura Źródłowa (Aplikacja Mobilna)

System OTA update w APPteczka opiera się na następujących komponentach:

### 1. Model Stanu (`UpdateService extends ChangeNotifier`)

```dart
// Stan wewnętrzny
String? _currentVersion;      // versionCode do porównania (format: yyDDDHHmm)
String? _currentVersionName;  // versionName do wyświetlania (format: 0.1.xxx)
String? _latestVersion;       // Najnowsza wersja z serwera
String? _downloadUrl;         // URL do pobrania pakietu
bool _updateAvailable;        // Flaga dostępności aktualizacji
double _downloadProgress;     // Postęp pobierania (0.0 - 100.0)
UpdateStatus _status;         // Aktualny status procesu
String? _errorMessage;        // Komunikat błędu
DateTime? _lastCheckTime;     // Czas ostatniego sprawdzenia
bool _isUpToDate;             // Flaga aktualności

enum UpdateStatus { idle, checking, downloading, launchingInstaller, error }
```

### 2. Plik Manifestu na Serwerze (`version.json`)

```json
{
	"version": "0.1.253651505",
	"versionCode": 253651505,
	"apkUrl": "https://your-server.com/releases/app_latest.apk"
}
```

### 3. Przepływ Aktualizacji

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   init()    │ ──▶ │ checkForUpdate() │ ──▶ │  startUpdate()  │
│ (on start)  │     │ (fetch JSON)     │     │ (download+run)  │
└─────────────┘     └──────────────────┘     └─────────────────┘
       │                     │                        │
       ▼                     ▼                        ▼
 PackageInfo          HTTP GET version.json    Download stream
 .fromPlatform()      Compare versionCode      + Launch installer
```

---

## Adaptacja dla Aplikacji Desktopowej

### Kluczowe Różnice Desktop vs Mobile

| Aspekt          | Mobile (Android)           | Desktop (Windows/macOS/Linux)                             |
| --------------- | -------------------------- | --------------------------------------------------------- |
| **Pakiet**      | `.apk`                     | `.exe`/`.msix` (Win), `.dmg` (macOS), `.AppImage` (Linux) |
| **Instalacja**  | `ota_update` plugin        | `Process.run()` uruchamia instalator                      |
| **Uprawnienia** | `REQUEST_INSTALL_PACKAGES` | Standardowe uprawnienia systemu plików                    |
| **Pobieranie**  | Plugin stream              | `http.Client` + `StreamedResponse`                        |

### Wymagane Zależności

```yaml
dependencies:
  http: ^1.2.0
  package_info_plus: ^8.0.0
  path_provider: ^2.1.0
  path: ^1.9.0
```

### Implementacja - Szkielet Serwisu

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DesktopUpdateService extends ChangeNotifier {
  // ... (stan identyczny jak w mobile)

  /// Pobiera instalator i uruchamia go
  Future<void> startUpdate() async {
    if (_downloadUrl == null) return;

    _status = UpdateStatus.downloading;
    notifyListeners();

    try {
      // 1. Określ ścieżkę docelową
      final tempDir = await getTemporaryDirectory();
      final fileName = _getInstallerFileName();
      final filePath = p.join(tempDir.path, fileName);

      // 2. Pobierz plik ze śledzeniem postępu
      final client = http.Client();
      final response = await client.send(
        http.Request('GET', Uri.parse(_downloadUrl!)),
      );

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final sink = File(filePath).openWrite();

      await response.stream.listen(
        (chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          _downloadProgress = (receivedBytes / totalBytes) * 100;
          notifyListeners();
        },
        onDone: () async {
          await sink.close();
          client.close();
          await _launchInstaller(filePath);
        },
        onError: (e) {
          _status = UpdateStatus.error;
          _errorMessage = 'Błąd pobierania: $e';
          notifyListeners();
        },
      );
    } catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = 'Błąd: $e';
      notifyListeners();
    }
  }

  /// Uruchamia instalator odpowiedni dla platformy
  Future<void> _launchInstaller(String filePath) async {
    _status = UpdateStatus.launchingInstaller;
    notifyListeners();

    if (Platform.isWindows) {
      // Windows: uruchom .exe lub .msix
      await Process.run(filePath, [], runInShell: true);
    } else if (Platform.isMacOS) {
      // macOS: otwórz .dmg
      await Process.run('open', [filePath]);
    } else if (Platform.isLinux) {
      // Linux: ustaw uprawnienia i uruchom AppImage
      await Process.run('chmod', ['+x', filePath]);
      await Process.run(filePath, []);
    }

    // Opcjonalnie: zamknij aplikację po uruchomieniu instalatora
    // exit(0);
  }

  String _getInstallerFileName() {
    if (Platform.isWindows) return 'update_installer.exe';
    if (Platform.isMacOS) return 'update_installer.dmg';
    return 'update_installer.AppImage';
  }
}
```

### Format `version.json` dla Desktop

```json
{
	"version": "1.0.0",
	"versionCode": 253651505,
	"downloads": {
		"windows": "https://server.com/releases/app-1.0.0-win.exe",
		"macos": "https://server.com/releases/app-1.0.0-mac.dmg",
		"linux": "https://server.com/releases/app-1.0.0-linux.AppImage"
	},
	"releaseNotes": "Lista zmian...",
	"minVersion": 250000000
}
```

### Wybór URL na podstawie platformy

```dart
String? _getDownloadUrlForPlatform(Map<String, dynamic> downloads) {
  if (Platform.isWindows) return downloads['windows'];
  if (Platform.isMacOS) return downloads['macos'];
  if (Platform.isLinux) return downloads['linux'];
  return null;
}
```

---

## Checklist Implementacji

- [ ] Skopiuj `UpdateService` jako bazę
- [ ] Zamień import `ota_update` na `dart:io` + `path_provider`
- [ ] Zmodyfikuj `startUpdate()` - pobieranie przez HTTP stream
- [ ] Dodaj `_launchInstaller()` z logiką per-platforma
- [ ] Rozszerz `version.json` o sekcję `downloads` per OS
- [ ] Dodaj `_getDownloadUrlForPlatform()`
- [ ] Przetestuj na każdej platformie docelowej
- [ ] (Opcjonalnie) Dodaj weryfikację sumy kontrolnej (SHA256)
- [ ] (Opcjonalnie) Dodaj auto-restart po instalacji

---

## Uwagi Bezpieczeństwa

1. **HTTPS** - zawsze używaj szyfrowanego połączenia
2. **Checksum** - weryfikuj SHA256 pobranego pliku przed instalacją
3. **Code signing** - podpisuj instalatory (Windows: Authenticode, macOS: notarization)
4. **Rollback** - zachowaj poprzednią wersję na wypadek błędów

---

## Referencje

- Źródło:
  [`apps/mobile/lib/services/update_service.dart`](../../apps/mobile/lib/services/update_service.dart)
- Dokumentacja: `package_info_plus`, `path_provider`

> 📅 **Utworzono:** 2026-01-26
