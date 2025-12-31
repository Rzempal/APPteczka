# Release & Deployment Guide

Instrukcja tworzenia i wdrażania nowych wersji aplikacji APPteczka.

## Szybki Start

```powershell
# Z folderu głównego projektu:
.\scripts\run_deploy.bat
```

Skrypt automatycznie:

1. Buduje APK w trybie release.
2. Kopiuje plik do `releases/` z nazwą `Pudelko_na_leki_<RRRRMMDD_HHMM>.apk`.
3. Generuje/aktualizuje `version.json`.

## Wersjonowanie

### Build Number (Android versionCode)

Format: `(Rok-2024)MMDDHHmm`

| Data/Czas | Build Number |
|-----------|--------------|
| 2025-12-31 08:31 | `112310831` |
| 2026-06-15 14:00 | `206151400` |

- Unika limitu Androida (max 2.1 mld).
- Bezpieczne do 2045 roku.
- Zawsze rosnące (wymagane przez Google Play).

### Nazwa Pliku APK

`Pudelko_na_leki_<RRRRMMDD_HHMM>.apk`

Przykład: `Pudelko_na_leki_20251231_0831.apk`

## Struktura Plików

```
APPteczka/
├── scripts/
│   ├── deploy_apk.ps1    # Główny skrypt
│   └── run_deploy.bat    # Wrapper (uruchamia PowerShell)
├── releases/
│   ├── Pudelko_na_leki_*.apk
│   └── version.json      # Metadane dla OTA
└── .env                  # Konfiguracja uploadu (opcjonalne)
```

## Konfiguracja Uploadu (Opcjonalne)

Aby włączyć automatyczny upload przez WinSCP, utwórz plik `.env`:

```env
DEPLOY_HOST=michalrapala.app
DEPLOY_USER=twoj_login_ftp
DEPLOY_PASS=twoje_haslo_ftp
DEPLOY_REMOTE_PATH=/public_html/releases/
```

Następnie uruchom skrypt **bez** flagi `-SkipUpload`:

```powershell
.\scripts\deploy_apk.ps1 -SkipUpload:$false
```

## Opcje Skryptu

| Flaga | Domyślnie | Opis |
|-------|-----------|------|
| `-SkipBuild` | `$false` | Pomija budowanie APK |
| `-SkipUpload` | `$true` | Pomija upload na serwer |

## System OTA (Over-The-Air Updates)

Aplikacja automatycznie sprawdza nowe wersje z:
`http://michalrapala.app/releases/version.json`

### Format version.json

```json
{
  "version": "20251231_0831",
  "apkUrl": "http://michalrapala.app/releases/Pudelko_na_leki_20251231_0831.apk",
  "releaseDate": "2025-12-31T08:31:00Z"
}
```

### UI Aktualizacji

- **HomeScreen**: Badge "Aktualizacja" (nawiguje do ustawień).
- **SettingsScreen**: Sekcja z przyciskami "Sprawdź" i "Aktualizuj".

## Zmiany Techniczne (2025-12-31)

### Nowe Pliki

- `lib/services/update_service.dart` - Logika OTA.
- `scripts/deploy_apk.ps1` - Skrypt deploymentu.
- `scripts/run_deploy.bat` - Wrapper.

### Zmodyfikowane Pliki

- `pubspec.yaml` - Dodano `ota_update`, `package_info_plus`.
- `android/app/build.gradle.kts` - Core Library Desugaring.
- `lib/main.dart` - Integracja `UpdateService`.
- `lib/screens/home_screen.dart` - Badge aktualizacji.
- `lib/screens/settings_screen.dart` - Sekcja aktualizacji.
- `lib/widgets/neumorphic/neu_button.dart` - Parametr `child`.

## Troubleshooting

### Błąd: "buildNumber is greater than maximum"

Stary format wersjonowania (`YYYYMMDDHHmm`) przekraczał limit. Naprawione przez Offset Date.

### Błąd: "requires core library desugaring"

Dodano `isCoreLibraryDesugaringEnabled = true` i zależność `desugar_jdk_libs:2.1.4` w `build.gradle.kts`.

### Błąd: "TerminatorExpectedAtEndOfString"

Polskie znaki w skrypcie PowerShell. Naprawione przez ASCII-only.
