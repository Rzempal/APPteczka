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

## ✅ Ukonczone Funkcje (poza fazami)

### Skaner Kodow Kreskowych EAN (v1.4.0)

**Data:** 2026-01-10

**Implementacja:**
- Ciagale skanowanie kodow EAN aparatem (mobile_scanner)
- Wyszukiwanie lekow w Rejestrze Produktow Leczniczych (API CeZ)
- Batch processing: snapshot daty → OCR na koncu
- AI enrichment: Gemini uzupelnia opis, tagi, wskazania
- Haptic feedback i animacje sukcesu

**Flow (v1.4.0 - batch mode):**
```
EAN → RPL API → snapshot daty → kolejny lek → ...
                                              ↓
                              [Zakoncz i przetworz]
                                              ↓
                              Batch OCR dat (rownolegle)
                                              ↓
                              AI enrichment (rownolegle)
                                              ↓
                              Dialog reczny (fallback)
```

**Zrodlo danych:** `rejestrymedyczne.ezdrowie.gov.pl` (oficjalne API rzadowe)

**Pliki:**
- `lib/widgets/barcode_scanner.dart` - widget skanera (v1.5.0)
- `lib/services/rpl_service.dart` - serwis API RPL (v2.1.0)
- `lib/screens/add_medicine_screen.dart` - batch handler + AI enrichment

---

### Gemini AI - Wspomaganie skanera i recznego dodawania (v2.0)

**Data:** 2026-01-11

**Architektura (v2.0):**
Gemini AI dziala jako "silnik w tle" wspomagajacy:
1. **Skaner kodow kreskowych** - AI enrichment (opis, tagi, wskazania)
2. **Reczne dodawanie** - przycisk "AI" przy nazwie leku

**Flow skanera:**
```
EAN → RPL API → snapshot daty → ...
                                ↓
                [Zakoncz i przetworz]
                                ↓
                Batch OCR dat (rownolegle)
                                ↓
                AI enrichment (Gemini - opis/tagi)
                                ↓
                Zapis do bazy
```

**Flow recznego dodawania:**
```
Nazwa leku → [AI] → Gemini → opis + wskazania + tagi
```

**Usuniete w v2.0:**
- Widget GeminiScanner (skanowanie zdjec opakowan)
- Tryb "2 zdjecia" (dual photo mode)
- Sekcja "Gemini AI Vision" z ekranu dodawania

**Pliki:**
- `apps/web/src/lib/prompts.ts` - prompt z instrukcja EAN (v0.003)
- `apps/mobile/lib/services/gemini_service.dart` - serwis Gemini (v0.003)
- `apps/mobile/lib/services/gemini_name_lookup_service.dart` - lookup po nazwie
- `apps/mobile/lib/screens/add_medicine_screen.dart` - AI enrichment w skanerze

---

### Lista Lekow - Akordeon v2.2

**Data:** 2026-01-10

**Zmiany v2.0:**
- Usunięto przełącznik widoku (lista/kafelki) - tylko jeden tryb
- Usunięto bottomSheet ze szczegółami leku
- MedicineCard v2.0 z wbudowanymi wszystkimi funkcjami:
  - Tryb compact (domyślny): flat neumorphic, minimalne info
  - Tryb expanded (akordeon): pressed/inset style, pełne szczegóły
- Sekcja "Więcej" jako wewnętrzny akordeon z:
  - Zarządzanie tagami
  - Zarządzanie etykietami
  - Data dodania
  - Usuwanie leku
- Usunięto funkcję OCR daty z listy (niepotrzebna dzięki batch scanning)
- Inline edycja notatki (bez dialogu)

**Zmiany v2.1 (UX refinements):**
- Nagłówek w expanded mode: kliknięcie zwija do compact
- Long press na nazwie leku: context menu (edytuj, kopiuj, ulotka, usuń)
- Przycisk "Więcej" zmienia się na "Mniej" z odwróconą ikoną
- Sekcja "Usuń lek": CTA najpierw, warning na końcu
- Powiększone ikony edycji (18px) do rozmiaru przycisku Sortuj
- Ikony edycji w Tags/Etykiety wyrównane do prawej (align right)
- Usunięty wewnętrzny outline z notatki w trybie edycji
- Przycisk "Edytuj" na dole karty zmieniony na "Zwiń"

**Zmiany v2.2 (bug fixes):**
- Powiększone ikony edycji (padding 10, size 20) - łatwiejsze trafienie palcem
- Usunięta zielona ramka z TextField w notatce (focusedBorder: none)
- Dodany padding (left/right: 4) do sekcji "Więcej" - cienie nie są podcinane
- Zmieniona kolejność sekcji: Etykiety, Tagi, Dodano, Usuń lek

**Pliki:**
- `lib/widgets/medicine_card.dart` - v2.2 z akordeonem
- `lib/screens/home_screen.dart` - uproszczona logika widoku

---

## 💡 IDEAS BACKLOG (Pomysly na przyszlosc)

> [!NOTE]
> Pomysly zebrane podczas rozwoju, do rozważenia w przyszlosci.

### Sugestie typowego okresu waznosci

**Idea:** Na podstawie zeskanowanego leku sugerowac typowy okres waznosci (np. 2-3 lata dla tabletek).

**Korzyści:**
- Szybsze wprowadzanie dat gdy OCR zawiedzie
- Przypomnienia o weryfikacji daty

---

> 📅 **Ostatnia aktualizacja:** 2026-01-11 (Gemini AI Vision - rozpoznawanie kodow kreskowych)
