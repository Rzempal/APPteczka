# 📦 Karton z lekami – Nie kop w pudle. Sprawdź w telefonie

[![Landing Page](https://img.shields.io/badge/🌐_Landing_Page-kartonzlekami.resztatokod.pl-blue)](https://kartonzlekami.resztatokod.pl)

Aplikacja mobilna do zarządzania domową apteczką z integracją AI. Kataloguj leki, śledź terminy ważności, filtruj po objawach.

> ⚠️ **Ważne:** Karton z lekami to narzędzie informacyjne (wyszukiwarka w ulotkach), NIE porada medyczna. Aplikacja NIE weryfikuje interakcji międzylekowych.

---

## ✨ Funkcje (MVP)

- ✅ Import leków z JSON (przez prompt AI)
- ✅ **Gemini AI OCR** – automatyczne rozpoznawanie leków ze zdjęć
- ✅ Filtrowanie po tagach, objawach, terminie ważności
- ✅ Wyszukiwanie tekstowe
- ✅ Edycja terminów ważności z alertami
- ✅ Generator promptu OCR (rozpoznawanie leków ze zdjęcia)
- ✅ Kopiowanie listy leków do schowka
- ✅ Eksport apteczki do JSON i PDF
- ✅ Sortowanie leków (A-Z, termin ważności)
- ✅ Wykrywanie duplikatów leków
- ✅ 3-tabowa nawigacja (Apteczka, Dodaj leki, Kopia zapasowa)
- ✅ Design neumorficzny z animacjami scroll
- ✅ **Aktualizacje OTA** – automatyczne sprawdzanie i instalacja nowych wersji APK
- ✅ 100% offline – dane lokalne w przeglądarce

---

## 🚀 Quick Start

```bash
# Klonuj repozytorium
git clone https://github.com/[user]/APPteczka.git
cd APPteczka

# Instalacja zależności
npm install

# Uruchom serwer deweloperski
npm run dev
```

Otwórz <http://localhost:3000>

---

## 📁 Struktura projektu

```
Pudełko-na-leki/
├── src/
│   ├── app/              # Next.js App Router
│   ├── components/       # Komponenty React
│   └── lib/              # Typy, walidacja, storage
├── docs/                 # Dokumentacja
│   ├── architecture.md   # Architektura systemu
│   ├── road_map.md       # Plan rozwoju
│   ├── data_model.md     # Model danych
│   ├── tags.md           # System tagów
│   ├── schema/           # Schematy JSON/YAML
│   └── prompts/          # Prompty dla AI
└── public/               # Statyczne zasoby
```

---

## 📋 Road Map

| Faza | Nazwa | Status |
|------|-------|--------|
| 0-3 | MVP Web + Mobile + Gemini API | ✅ Ukończona |
| 4 | Web → Landing Page + API | ✅ Ukończona |
| 5 | Google Play Store Release | 📋 Planowana |
| 6 | Backend + Sync | 🔮 Przyszłość |

Szczegóły: [docs/road_map.md](docs/road_map.md)

---

## 🛠️ Stack technologiczny

| Warstwa | Technologia |
|---------|-------------|
| Framework | Next.js 16 (App Router) |
| UI | React 19 + Tailwind CSS 4 |
| Walidacja | Zod |
| Przechowywanie | localStorage (offline-first) |
| Język | TypeScript |

### Mobile (Flutter)

| Warstwa | Technologia |
|---------|-------------|
| Framework | Flutter (Dart) |
| UI | Material Design 3 |
| Baza danych | Hive (NoSQL) |
| Platformy | Android / iOS / Web |

---

## 📚 Dokumentacja

| Dokument | Opis |
|----------|------|
| [Architektura](docs/architecture.md) | Stack, przepływ danych |
| [Road Map](docs/road_map.md) | Plan rozwoju projektu |
| [Model Danych](docs/data_model.md) | Encje, schematy |
| [Release Guide](docs/release.md) | Deployment APK i OTA |
| [Bezpieczeństwo](docs/security.md) | Lokalne dane, disclaimer |

---

## 🔒 Bezpieczeństwo

- Dane przechowywane **lokalnie** w przeglądarce (localStorage)
- Brak wysyłania danych na serwer
- Brak kont użytkowników (w MVP)
- Jasny disclaimer medyczny

---

## 📄 Licencja

MIT License

---

## 🔗 Linki

- 🌐 **Wersja produkcyjna:** [pudelkonaleki.michalrapala.app](https://pudelkonaleki.michalrapala.app)
- 📦 **Repozytorium:** [GitHub](https://github.com/Rzempal/APPteczka)

---

> 📅 **Ostatnia aktualizacja:** 2026-01-02
