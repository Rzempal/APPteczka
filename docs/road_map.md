# 🗺️ Road Map – Karton (Pudełko na leki)

> **Powiązane:** [Architektura](architecture.md) | [Model Danych](data_model.md) | [Feature Lists](feature-lists.md)

---

## Wizja Produktu

**Karton** to aplikacja mobilna do zarządzania domową apteczką z integracją AI. Umożliwia:

- 📦 Katalogowanie leków w domu
- 🔍 Filtrowanie po objawach, działaniu, grupie użytkowników
- ⏰ Śledzenie terminów ważności
- 📷 Automatyczne rozpoznawanie leków ze zdjęć (Gemini AI)
- 🏷️ Własne etykiety i notatki

---

## Strategia Rozwoju

**Platforma docelowa:** Android (Google Play Store)  
**Backend:** Vercel (API-only) – Gemini OCR proxy  
**Model:** Darmowa aplikacja, offline-first

```
┌────────────────────────────────────────────────────┐
│                   ARCHITEKTURA                     │
├────────────────────────────────────────────────────┤
│                                                    │
│   Google Play ──► Flutter APK (offline-first)      │
│                        │                           │
│                        ▼                           │
│               Vercel API (proxy)                   │
│               ├── /api/gemini-ocr                  │
│               └── /api/pdf-proxy                   │
│                        │                           │
│                        ▼                           │
│               Gemini API (Google)                  │
│                                                    │
│   Landing Page ──► kartonzlekami.resztatokod.pl    │
│               ├── Hero + Features                  │
│               ├── Screenshots                      │
│               └── Privacy Policy                   │
│                                                    │
└────────────────────────────────────────────────────┘
```

---

## Status Faz

| Faza | Nazwa | Status |
|------|-------|--------|
| 0 | Dokumentacja i Schematy | ✅ Ukończona |
| 1 | MVP Web (Next.js) | ✅ Ukończona |
| 2 | MVP Mobile (Flutter) | ✅ Ukończona |
| 3 | Gemini API Integration | ✅ Ukończona |
| 4 | Web → Landing Page + API | ✅ Ukończona |
| 5 | Google Play Store Release | 📋 Planowana |
| 6 | Backend + Sync (opcjonalne) | 🔮 Przyszłość |

---

## ✅ FAZA 0-3: Zakończone

<details>
<summary>Szczegóły ukończonych faz</summary>

### Faza 0: Dokumentacja

- Schema danych (JSON/YAML)
- Prompty dla AI
- Kontrolowana lista tagów

### Faza 1: MVP Web (Next.js)

- Pełna aplikacja webowa z design neumorficznym
- Import/eksport JSON, PDF
- Etykiety, notatki, filtrowanie

### Faza 2: MVP Mobile (Flutter)

- Natywna aplikacja Android
- Hive local storage
- Design neumorficzny
- Wykrywanie duplikatów leków (fuzzy matching)

### Faza 3: Gemini API

- Backend proxy na Vercel
- Automatyczne rozpoznawanie leków ze zdjęć
- Rozpoznawanie leków po wpisanej nazwie (AI name lookup)
- Rate limiting

</details>

---

## ✅ FAZA 4: Web → Landing Page + API (Ukończona)

**Cel:** Przekształcenie wersji webowej w stronę promocyjną + zachowanie API dla aplikacji mobilnej

### Wykonane

- ✅ Usunięto stare UI aplikacji webowej (`page.tsx`, `dodaj/`, `backup/`, `components/`)
- ✅ Zachowano API endpoints (`gemini-ocr/`, `pdf-proxy/`, `bug-report/`, `gemini-name-lookup/`, `date-ocr/`)
- ✅ Stworzono Landing Page z animowanym SVG kartonu
- ✅ Stworzono stronę Privacy Policy (`/privacy`)
- ✅ Dodano SEO meta tagi + Open Graph
- ✅ Theme toggle (light/dark) z autodetekcją
- ✅ CTA do pobrania APK z dynamicznym linkiem wersji

### Subdomena

- URL: `kartonzlekami.resztatokod.pl`
- Hosting: Vercel

---

## 📋 FAZA 5: Google Play Store Release

### Checklist Wymagań

#### Prawne

| Element | Status |
|---------|--------|
| Privacy Policy URL | ✅ [docs/privacy_policy.md](privacy_policy.md) |
| Target Age Group (nie dla dzieci <13) | ⬜ |
| Data Safety Form | ✅ [docs/security.md](security.md) |

#### Graficzne

| Element | Wymiary | Status |
|---------|---------|--------|
| App Icon | 512×512 | ✅ |
| Feature Graphic | 1024×500 | ⬜ |
| Screenshots (min. 2) | 1080×1920 | ⬜ |

#### Tekstowe

| Element | Limit | Status |
|---------|-------|--------|
| App Name | 30 znaków | ✅ "Karton z lekami - domowa apteczka" |
| Short Description | 80 znaków | ✅ [docs/store_listing.md](store_listing.md) |
| Full Description | 4000 znaków | ✅ [docs/store_listing.md](store_listing.md) |
| Contact Email | - | ⬜ |

#### Techniczne

| Element | Status |
|---------|--------|
| App Bundle (.aab) | ⬜ |
| Signing Keystore | ⬜ |
| Content Rating (IARC) | ⬜ |

#### Opłaty

| Element | Koszt | Status |
|---------|-------|--------|
| Google Play Developer | $25 jednorazowo | ⬜ |

#### Polityka Darowizn (BuyCoffee)

> [!IMPORTANT]
> Funkcja "Wesprzyj projekt" otwiera link w **zewnętrznej przeglądarce** i nie oferuje nic w zamian (brak dóbr cyfrowych). Zgodnie z **Payments Policy**, nie wymaga to użycia Google Play Billing. W ankiecie App Content należy zadeklarować brak zakupów w aplikacji (In-App Purchases).

---

## � FAZA 6: Backend + Sync (Przyszłość)

**Cel:** Opcjonalne konta użytkowników i synchronizacja cross-device

> [!NOTE]
> Ta faza jest opcjonalna i planowana na przyszłość, gdy baza użytkowników wzrośnie.

| Element | Technologia |
|---------|-------------|
| Autentykacja | Firebase Auth / Supabase |
| Baza danych | Firestore / PostgreSQL |
| Sync | Real-time synchronization |

---

## 💡 IDEAS BACKLOG (Pomysły na przyszłość)

> [!NOTE]
> Pomysły zebrane podczas rozwoju, do rozważenia w przyszłości.

### EAN Lookup - Automatyczne uzupełnianie dat ważności

**Idea:** Skanowanie kodu EAN opakowania i pobieranie informacji o leku z zewnętrznego API.

**Potencjalne źródła:**

- [Open Food Facts](https://openfoodfacts.org/) - otwarty, ale głównie żywność
- [Rejestr Leków MZ](https://rejestrymedyczne.cez.gov.pl/) - oficjalny, ale bez API dla dat ważności
- Własna baza danych budowana przez użytkowników

**Korzyści:**

- Automatyczne uzupełnianie nazwy i opisu leku
- Możliwość sugerowania typowego okresu ważności
- Weryfikacja autentyczności opakowania

**Wymagania:**

- Integracja z zewnętrznym API
- Fallback gdy produkt nie znaleziony
- Możliwość zgłaszania nowych produktów

---

> 📅 **Ostatnia aktualizacja:** 2026-01-07
