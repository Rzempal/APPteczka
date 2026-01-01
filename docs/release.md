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
│   └── version.json
└── apps/mobile/
    └── pubspec.yaml      # Major.Minor tutaj
```

## Format version.json

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
