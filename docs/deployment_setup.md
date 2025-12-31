# Instrukcja Konfiguracji Deploymentu

Aby skrypt `scripts/deploy_apk.ps1` mógł automatycznie wysyłać pliki na serwer, wykonaj poniższe kroki.

## 1. Zainstaluj WinSCP

Skrypt używa programu WinSCP do przesyłania plików.

- Pobierz i zainstaluj: [https://winscp.net/eng/download.php](https://winscp.net/eng/download.php)
- Instalacja domyślna w `Program Files` lub `Program Files (x86)` wystarczy – skrypt sam go znajdzie.

## 2. Skonfiguruj plik `.env`

Stwórz lub edytuj plik `.env` w głównym katalogu projektu (`APPteczka/.env`). Dodaj następujące zmienne (podmieniając dane na swoje):

```ini
# --- Deployment Config ---
# Adres serwera (bez protokołu, np. michalrapala.app)
DEPLOY_HOST=michalrapala.app

# Użytkownik FTP/SFTP
DEPLOY_USER=twoj_uzytkownik

# Hasło FTP/SFTP
DEPLOY_PASS=twoje_haslo

# (Opcjonalnie) Protokół: sftp lub ftp (domyślnie sftp)
DEPLOY_PROTOCOL=sftp

# (Opcjonalnie) Ścieżka na serwerze gdzie mają trafić pliki
# Ważne: Musi kończyć się znakiem /
DEPLOY_REMOTE_PATH=/domains/michalrapala.app/public_html/releases/

# (Opcjonalnie) Publiczny adres URL do folderu releases (używany w pliku version.json)
DEPLOY_PUBLIC_URL=http://michalrapala.app/releases
```

## 3. Uruchomienie

Po konfiguracji, uruchom skrypt z PowerShella:

```powershell
.\scripts\deploy_apk.ps1
```

Skrypt automatycznie:

1. Zbuduje nową wersję APK.
2. Skopiuje ją do folderu `releases/`.
3. Zaktualizuje plik `version.json` lokalnie.
4. Połączy się z serwerem i wyśle oba pliki.

## Rozwiązywanie problemów

- **Błąd "Nie znaleziono WinSCP"**: Dodaj do `.env` zmienną `WINSCP_PATH=C:\Ścieżka\Do\WinSCP.com`.
- **Błąd połączenia**: Sprawdź log `releases/winscp_log.xml` który powstaje po próbie uploadu.
- **Host key verification**: Skrypt ustawiony jest na automatyczną akceptację kluczy (`-hostkey="*"`). Jeśli to nie działa, połącz się raz ręcznie przez WinSCP GUI i zaakceptuj klucz.
