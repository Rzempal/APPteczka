# 📦 Karton z lekami – Nie kop w pudle. Sprawdź w telefonie

[![Landing Page](https://img.shields.io/badge/🌐_Landing_Page-kartonzlekami.resztatokod.pl-blue)](https://kartonzlekami.resztatokod.pl)

Aplikacja mobilna do zarządzania domową apteczką z integracją AI. Kataloguj leki, śledź terminy ważności, filtruj po objawach.

> ⚠️ **Ważne:** Karton z lekami to narzędzie informacyjne (wyszukiwarka w ulotkach), NIE porada medyczna. Aplikacja NIE weryfikuje interakcji międzylekowych.

---

## ✨ Funkcje

- ✅ **Skaner kodów kreskowych EAN** – ciągłe skanowanie z API Rejestru Produktów Leczniczych
- ✅ **Skaner QR/Data Matrix (GS1)** – automatyczne odczytywanie daty ważności z kodu 2D
- ✅ **Gemini AI OCR** – automatyczne rozpoznawanie leków ze zdjęć
- ✅ Filtrowanie po tagach, objawach, terminie ważności
- ✅ Wyszukiwanie tekstowe
- ✅ Edycja terminów ważności z alertami
- ✅ Eksport apteczki do JSON i PDF
- ✅ Wykrywanie duplikatów leków
- ✅ Design neumorficzny z animacjami
- ✅ **Aktualizacje OTA** – automatyczne sprawdzanie i instalacja nowych wersji APK
- ✅ 100% offline – dane lokalne na urządzeniu

---

## 🚀 Quick Start

### Mobile (Flutter) – główna aplikacja

```bash
cd apps/mobile
flutter pub get
flutter run
```

### Web (Landing + API) – development

```bash
cd apps/web
npm install
npm run dev
```

---

## 📁 Struktura projektu

```
APPteczka/
├── apps/
│   ├── mobile/              # Flutter (główna aplikacja)
│   │   ├── lib/             # Kod Dart (screens, widgets, services)
│   │   ├── android/         # Konfiguracja Android
│   │   ├── ios/             # Konfiguracja iOS
│   │   └── pubspec.yaml     # Zależności Flutter
│   └── web/                 # Next.js (Landing Page + API)
│       ├── src/app/         # App Router
│       └── src/app/api/     # API Routes (Gemini proxy)
├── docs/                    # Dokumentacja projektu
├── scripts/                 # Skrypty deploymentu (APK)
├── releases/                # Zbudowane pliki APK
└── packages/                # Wspólne schematy (opcjonalne)
```

---

## 📋 Roadmap

| Faza | Nazwa | Status |
| --- | --- | --- |
| 0-3 | MVP Mobile + Gemini API | ✅ Ukończona |
| 4 | Web → Landing Page + API | ✅ Ukończona |
| 5 | Google Play Store Release | 📋 Planowana |
| 6 | Backend + Sync | 🔮 Przyszłość |

Szczegóły: [docs/roadmap.md](docs/roadmap.md)

---

## 🛠️ Stack technologiczny

### Mobile (główna platforma)

| Warstwa | Technologia |
| --- | --- |
| Framework | Flutter (Dart) |
| UI | Material Design 3 + Neumorphism |
| Baza danych | Hive (NoSQL, offline) |
| Skaner | mobile_scanner + GS1 parser |
| Platformy | Android (iOS w przyszłości) |

### Backend (API Proxy)

| Warstwa | Technologia |
| --- | --- |
| Framework | Next.js 16 (App Router) |
| Hosting | Vercel |
| AI | Gemini API (OCR, enrichment) |
| Cel | Landing Page + API dla mobile |

---

## 📚 Dokumentacja

| Dokument | Opis |
| --- | --- |
| [Architektura](docs/architecture.md) | Stack, przepływ danych |
| [Baza Danych](docs/database.md) | Encje, schematy |
| [Konwencje](docs/conventions.md) | Standardy kodu |
| [Design System](docs/design.md) | Paleta kolorów, typografia, komponenty UI |
| [Bezpieczeństwo](docs/security.md) | Lokalne dane, disclaimer |
| [Design Review](docs/design-review.md) | Kryteria oceny UI/UX |
| [Roadmap](docs/roadmap.md) | Plan rozwoju projektu |
| [Wdrożenie](docs/deployment.md) | Setup WinSCP i APK lifecycle |
| [Contributing](docs/contributing.md) | Przewodnik dokumentacji |

---

## 🔒 Bezpieczeństwo

- Dane przechowywane **lokalnie** na urządzeniu (Hive)
- API proxy chroni klucz Gemini
- Brak kont użytkowników (w MVP)
- Jasny disclaimer medyczny

---

## 📄 Licencja

MIT License

---

## 🔗 Linki

- 🌐 **Landing Page:** [kartonzlekami.resztatokod.pl](https://kartonzlekami.resztatokod.pl)
- 📦 **Repozytorium:** [GitHub](https://github.com/Rzempal/APPteczka)

---

> 📅 **Ostatnia aktualizacja:** 2026-01-14
