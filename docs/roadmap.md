# 🗺️ Roadmap

> **Powiązane:** [Architektura](architecture.md) | [Baza Danych](database.md) | [Bezpieczeństwo](security.md)

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
| Privacy Policy URL | ✅ [docs/privacy-policy.md](privacy-policy.md) |
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

> [!TIP]
> Szczegółowy opis tego procesu znajdziesz w dokumencie: [Proces dodawania leków](guidelines/drug_addition_process.md)

**Zrodlo danych:** `rejestrymedyczne.ezdrowie.gov.pl` (oficjalne API rzadowe)

**Pliki:**

- `lib/widgets/barcode_scanner.dart` - widget skanera (v1.6.0)
- `lib/utils/gs1_parser.dart` - parser GS1 Data Matrix
- `lib/services/rpl_service.dart` - serwis API RPL (v2.3.0)
- `lib/screens/add_medicine_screen.dart` - batch handler + AI enrichment

---

### Skaner kodów QR/Data Matrix (v1.6.0)

**Data:** 2026-01-13

**Implementacja:**

- Automatyczne rozpoznawanie kodów GS1 Data Matrix (2D) z opakowań leków
- Parser GS1 wyciągający: GTIN → EAN, datę ważności (AI 17), serię (AI 10), numer seryjny (AI 21)
- Pominięcie kroku "zdjęcie daty" gdy data odczytana z kodu 2D
- Obsługa formatów: z nawiasami `(01)...`, surowe `01...`, z separatorem GS

**Flow (v1.6.0 - Data Matrix):**

```
Data Matrix → GS1 Parser → EAN + Data
                              ↓
                   RPL API → sukces + data z kodu
                              ↓
                   Pomiń zdjęcie → kolejny lek
```

**Pliki:**

- `lib/utils/gs1_parser.dart` - parser GS1 (AI 01/17/10/21)
- `lib/widgets/barcode_scanner.dart` - integracja GS1 (v1.6.0)
- `test/gs1_parser_test.dart` - 11 unit testów

---

### Gemini AI - Wspomaganie skanera i recznego dodawania (v2.1)

**Data:** 2026-01-11

**Architektura (v2.1):**
Gemini AI dziala jako "silnik w tle" wspomagajacy:

1. **Skaner kodow kreskowych** - AI enrichment (opis, tagi, wskazania)
2. **Reczne dodawanie** - automatyczne AI przy zapisie (uproszczony formularz)

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

**Flow recznego dodawania (v2.2 - weryfikacja RPL):**

```
Nazwa leku (autocomplete RPL)
                ↓
    Lista wynikow z RPL (dropdown)
                ↓
    Wybor leku → pobierz szczegoly
                ↓
    Wybor opakowania (jesli >1) → GTIN
                ↓
        [Zapisz lek]
                ↓
    Gemini → opis + wskazania + tagi
                ↓
    Polaczenie danych RPL + AI → zapis
```

**Fallback (gdy brak w RPL):**

```
Wpisana nazwa
                ↓
        [Zapisz lek]
                ↓
    AI poprawia nazwe → szukaj w RPL
                ↓
    Znaleziono? → wybor opakowania
                ↓
    Nie znaleziono? → tylko dane AI
```

**Zmiany w v2.2:**

- Autocomplete RPL podczas wpisywania nazwy (debounce 300ms)
- Lista wynikow: nazwa + moc + postac farmaceutyczna
- Pobieranie szczegolow po wyborze (packages z GTIN)
- Bottom sheet do wyboru opakowania (jesli wiecej niz 1)
- Badge weryfikacji RPL z informacja o opakowaniu i EAN
- Fallback: AI poprawia nazwe → retry szukania w RPL → tylko AI

**Zmiany w v2.1:**

- Uproszczony formularz: tylko nazwa + opcjonalna data waznosci
- Usunieto osobny przycisk "AI" - funkcjonalnosc przeniesiona do "Zapisz lek"
- Ikona sekcji: kaskadowa (olowek + AI sparkles) jak w skanerze
- Dialog przetwarzania AI podczas zapisu (jak w skanerze)
- Blad jesli AI nie rozpozna leku (nie zapisujemy)

**Usuniete w v2.0:**

- Widget GeminiScanner (skanowanie zdjec opakowan)
- Tryb "2 zdjecia" (dual photo mode)
- Sekcja "Gemini AI Vision" z ekranu dodawania

**Pliki:**

- `apps/web/src/lib/prompts.ts` - prompt z instrukcja EAN (v0.003)
- `apps/mobile/lib/services/gemini_service.dart` - serwis Gemini (v0.003)
- `apps/mobile/lib/services/gemini_name_lookup_service.dart` - lookup po nazwie
- `apps/mobile/lib/services/rpl_service.dart` - serwis API RPL (v2.2.0)
- `apps/mobile/lib/widgets/rpl_autocomplete.dart` - autocomplete z RPL
- `apps/mobile/lib/widgets/rpl_package_selector.dart` - selector opakowan
- `apps/mobile/lib/screens/add_medicine_screen.dart` - formularz z weryfikacja RPL

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
**Zmiany v2.3 (build fix):**

- Naprawiono błąd kompilacji (extra closing parenthesis) blokujący APK deployment
- Zsynchronizowano animację tap-to-expand z dekoracją neumorficzną

**Pliki:**

- `lib/widgets/medicine_card.dart` - v2.3 z fixem animacji
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

---

### Automatyzacja Deploymentu (v12.4)

**Data:** 2026-01-12

**Implementacja:**

- Automatyczny upload APK na serwer Hostido (WinSCP)
- Żywy stoper (Elapsed Time) w tytule okna terminala
- Strategia czyszczenia: retencja 3 ostatnich wersji APK (per kanał)
- Zaawansowane logowanie w `log.md`: 4 commity, czas deploymentu, status cleanupu

**Pliki:**

- `scripts/deploy_apk.ps1` - v12.4 (cleaner + timer fix)
- `docs/deployment.md` - instrukcja konfiguracji

---

### Bug Reporter Improvements (v12.5)

**Data:** 2026-01-13

**Implementacja:**

- Zwiekszenie limitu zdjęć z 1 do 5 (galeria + screenshot)
- Nowy podgląd miniatur z możliwością usuwania
- Obsługa wielu załączników w backendzie (Resend API)

**Pliki:**

- `lib/widgets/bug_report_sheet.dart` - nowy UI miniatur
- `lib/services/bug_report_service.dart` - obsługa wielu zdjęć
- `apps/web/src/app/api/bug-report/route.ts` - batch processing załączników

---

> 📅 **Ostatnia aktualizacja:** 2026-01-14
