# 💊 Pudełko na leki – Zarządzaj domową apteczką

Aplikacja do zarządzania domową apteczką z integracją AI. Kataloguj leki, śledź terminy ważności, filtruj po objawach.

> ⚠️ **Ważne:** Pudełko na leki to narzędzie informacyjne (wyszukiwarka w ulotkach), NIE porada medyczna. Aplikacja NIE weryfikuje interakcji międzylekowych.

---

## ✨ Funkcje (MVP)

- ✅ Import leków z JSON (przez prompt AI)
- ✅ Filtrowanie po tagach, objawach, terminie ważności
- ✅ Wyszukiwanie tekstowe
- ✅ Edycja terminów ważności z alertami
- ✅ Generator promptu OCR (rozpoznawanie leków ze zdjęcia)
- ✅ Kopiowanie listy leków do schowka
- ✅ Eksport apteczki do JSON i PDF
- ✅ Sortowanie leków (A-Z, termin ważności)
- ✅ 3-tabowa nawigacja (Apteczka, Dodaj leki, Kopia zapasowa)
- ✅ Design neumorficzny z animacjami scroll
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
│   ├── schema/           # Schematy JSON/YAML
│   └── prompts/          # Prompty dla AI
└── public/               # Statyczne zasoby
```

---

## 📋 Road Map

| Faza | Nazwa | Status |
|------|-------|--------|
| 0 | Dokumentacja | ✅ Ukończona |
| 1 | MVP Web (Next.js) | ✅ Ukończona |
| 2 | MVP Mobile (Flutter) | ⏳ Następna |
| 3 | Backend + Sync | 📋 Planowana |
| 4 | Gemini API | 📋 Planowana |

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

---

## 📚 Dokumentacja

| Dokument | Opis |
|----------|------|
| [Architektura](docs/architecture.md) | Stack, przepływ danych |
| [Road Map](docs/road_map.md) | Plan rozwoju projektu |
| [Model Danych](docs/data_model.md) | Encje, schematy |
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

> 📅 **Ostatnia aktualizacja:** 2025-12-25
