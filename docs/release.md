# Release & Deployment Guide

Instrukcja tworzenia i wdrażania nowych wersji aplikacji APPteczka.

## Szybki Start

```powershell
# Z folderu głównego projektu:
.\scripts\run_deploy.bat
```

Skrypt automatycznie:

1. Buduje APK w trybie release.
2. Generuje wersję `v0.1.253651452`.
3. Kopiuje plik do `releases/`.
4. Generuje `version.json`.

## Strategia Wersjonowania

### Format

```
versionName: Major.Minor.Timestamp
versionCode: Timestamp (tylko liczba)
```

### Składniki

| Pole | Wartość | Opis |
|------|---------|------|
| `Major` | 0 | Faza rozwoju (1 = beta) |
| `Minor` | 1 | Funkcjonalna (rośnie przy nowych funkcjach) |
| `Timestamp` | `yyDDDHHmm` | yy=rok, DDD=dzień roku, HH=godz, mm=min |

### Przykład (2025-12-31 14:52)

```
versionName: 0.1.253651452
versionCode: 253651452
APK: Pudelko_na_leki_0.1.253651452.apk
```

### Co robisz jako developer

| Typ Release | Edycja pubspec.yaml? | Co się zmienia? |
|-------------|---------------------|-----------------|
| **Patch** | ❌ Nie | Tylko timestamp |
| **Minor** | ✅ `0.1` → `0.2` | Minor + timestamp |
| **Major** | ✅ `0.2` → `1.0` | Major + timestamp |

## Struktura Plików

```
APPteczka/
├── scripts/
│   ├── deploy_apk.ps1    # Główny skrypt
│   └── run_deploy.banavbar
t    # Wrapper
├── releases/
│   ├── Pudelko_na_leki_*.apk
│   └── version.json      # Metadane dla OTA
└── .env                  # Konfiguracja uploadu (opcjonalne)
```

## Konfiguracja Automatycznego Uploadu (WinSCP)

Skrypt `scripts/deploy_apk.ps1` posiada wbudowaną obsługę automatycznego uploadu na serwer FTP/SFTP (np. hostido.pl, cyberfolks.pl) przy użyciu klienta **WinSCP**.

### Wymagania

1. Zainstalowany klient **WinSCP** (domyślnie szukany w `Program Files`).
2. Konto FTP/SFTP skonfigurowane na hostingu.

### Instrukcja Krok po Kroku

1. **Przygotuj dane dostępowe** z panelu hostingu:
   - **Host**: adres serwera (np. `ftp.twoja-domena.pl` lub IP).
   - **User**: nazwa użytkownika FTP.
   - **Password**: hasło do konta FTP.
   - **Remote Path**: ścieżka do katalogu na serwerze, gdzie mają trafić pliki (np. `/public_html/releases/`).

2. **Skonfiguruj plik `.env`**:
   W głównym katalogu projektu edytuj plik `.env` i dodaj poniższe zmienne:

   ```env
   # --- Konfiguracja Deploymentu (Hostido) ---
   DEPLOY_HOST=twoj.serwer.pl
   DEPLOY_USER=uzytkownik_ftp
   DEPLOY_PASS=tajne_haslo
   DEPLOY_PROTOCOL=ftps             # opcje: sftp, ftp, ftps
   DEPLOY_REMOTE_PATH=/public_html/releases/
   DEPLOY_PUBLIC_URL=https://twoja-domena.pl/releases
   ```

   > **Wskazówka:** Upewnij się, że katalog docelowy (`/public_html/releases/`) istnieje na serwerze, w przeciwnym razie upload może się nie udać (skrypt nie tworzy folderów zdalnych).

3. **WinSCP (Opcjonalne)**:
   Jeśli WinSCP jest zainstalowany w niestandardowej lokalizacji, dodaj zmienną:

   ```env
   WINSCP_PATH="C:\Tools\WinSCP\WinSCP.com"
   ```

4. **Uruchomienie**:
   Uruchom standardowy skrypt release'u. Jeśli zmienne w `.env` są poprawne, upload wykona się automatycznie po zbudowaniu APK.

   ```powershell
   .\scripts\run_deploy.bat
   ```

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
  "version": "0.1.253651452",
  "versionCode": 253651452,
  "apkUrl": "https://michalrapala.app/releases/Pudelko_na_leki_0.1.253651452.apk",
  "releaseDate": "2025-12-31T14:52:00Z"
}
```

## System OTA

- `versionCode` porównywane jako int
- Automatyczne sprawdzanie przy starcie
- Badge "Aktualizacja" na stronie głównej
