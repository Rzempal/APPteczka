# 🔐 Bezpieczeństwo

> **Powiązane:** [Architektura](architecture.md) | [Baza Danych](database.md) | [Disclaimers](disclaimers.md)

---

## ⚠️ Disclaimer Medyczny

> [!CAUTION]
> **Pudełko na leki NIE jest narzędziem medycznym.**
>
> - Nie zastępuje porady lekarza
> - Nie udziela rekomendacji terapeutycznych
> - Służy wyłącznie do porządkowania informacji o lekach
>
> W razie wątpliwości **zawsze skonsultuj się z lekarzem lub farmaceutą**.

---

## Ochrona Danych Użytkownika

### Faza 1: Dane Lokalne

| Mechanizm | Opis |
|-----------|------|
| **localStorage** | Dane przechowywane wyłącznie w przeglądarce użytkownika |
| **Brak wysyłki** | Żadne dane nie są wysyłane na zewnętrzne serwery |
| **Brak śledzenia** | Bez cookies analitycznych, bez telemetrii |
| **Eksport** | Użytkownik może wyeksportować dane jako JSON |

### Faza 2+: Backend (opcjonalny)

| Mechanizm | Opis |
|-----------|------|
| **Szyfrowanie transmisji** | HTTPS dla wszystkich połączeń |
| **Hasła** | Hashowanie Argon2id (jeśli konta użytkowników) |
| **Dane wrażliwe** | Brak zbierania danych medycznych/zdrowotnych |

---

## Interakcja z AI

### Faza 1: Prompty Copy-Paste

| Aspekt | Opis |
|--------|------|
| **Brak API** | Użytkownik sam wkleja dane do zewnętrznego AI |
| **Odpowiedzialność** | Użytkownik decyduje, co udostępnia AI |
| **Brak przechowywania** | Aplikacja nie zapisuje odpowiedzi AI |

### Faza 3: API Gemini

| Aspekt | Opis |
|--------|------|
| **Tylko obrazy** | Wysyłane są wyłącznie zdjęcia opakowań |
| **Minimalizacja danych** | Brak wysyłania listy leków do API |
| **Klucz API** | Przechowywany w zmiennych środowiskowych (nie w kodzie) |

---

## Zasady AI

Prompty dla AI zawierają ograniczenia:

```text
❌ Brak porad medycznych
❌ Brak sugerowania zamienników
❌ Brak ocen skuteczności
❌ Brak dawkowania
❌ Zgadywanie jest zabronione

✅ Tylko porządkowanie informacji
✅ Zawsze: "Stosować zgodnie z ulotką"
✅ Przy niepewności: pytaj użytkownika
```

---

## Retencja Danych

| Faza | Retencja |
|------|----------|
| 1 | Dane lokalne – użytkownik kontroluje całkowicie |
| 2+ | Automatyczne usuwanie nieaktywnych kont po 12 miesiącach (jeśli backend) |

---

## Komunikaty w Aplikacji

Aplikacja wyświetla disclaimer w kluczowych miejscach:

- **Import leków:** "Zweryfikuj poprawność rozpoznania przed zapisaniem"
- **Analiza objawów:** "To nie jest porada medyczna. Skonsultuj się z lekarzem."
- **Przeterminowane leki:** "Nie stosuj przeterminowanych leków"

---

## Zgłaszanie Błędów (Bug Report)

### Zbierane dane (opcjonalnie)

| Dane | Kontrola użytkownika |
|------|---------------------|
| **Screenshot** | ✅ Checkbox – można wyłączyć |
| **Logi aplikacji** | ✅ Checkbox – można wyłączyć |
| **Opis problemu** | ✅ Opcjonalny tekst |
| **Email zwrotny** | ✅ Opcjonalny (tylko dla kategorii "Pytanie") |
| **Wersja aplikacji** | Automatyczne |
| **Info o urządzeniu** | Model + wersja systemu |

### Przetwarzanie danych

| Aspekt | Opis |
|--------|------|
| **Transmisja** | HTTPS do API na Vercel |
| **Email** | Wysyłka przez Resend.com |
| **Przechowywanie** | Tylko w skrzynce odbiorczej developera |
| **Brak danych leków** | Lista leków NIE jest wysyłana w raporcie |

> [!NOTE]
> Screenshot przechwytuje aktualny widok ekranu. Użytkownik widzi podgląd i może go wyłączyć przed wysłaniem.

---

## Analiza Bezpieczeństwa Funkcji

### Wsparcie Projektu (BuyCoffee)

| Aspekt | Bezpieczeństwo |
|--------|----------------|
| **Izolacja** | Link otwiera się w **zewnętrznej przeglądarce**, w pełnej izolacji od danych aplikacji (Sandbox). |
| **Dane** | Aplikacja nie przekazuje żadnych danych użytkownika do serwisu płatności. |
| **Płatność** | Proces płatności odbywa się poza aplikacją – brak ryzyka wycieku danych karty z poziomu aplikacji. |

| Aspekt | Bezpieczeństwo |
|--------|----------------|
| **Izolacja** | Link otwiera się w **zewnętrznej przeglądarce**, w pełnej izolacji od danych aplikacji (Sandbox). |
| **Dane** | Aplikacja nie przekazuje żadnych danych użytkownika do serwisu płatności. |
| **Płatność** | Proces płatności odbywa się poza aplikacją – brak ryzyka wycieku danych karty z poziomu aplikacji. |

### Kalkulator Zapasów

| Aspekt | Bezpieczeństwo |
|--------|----------------|
| **Przetwarzanie** | Kalkulacja `(zapas / zużycie)` odbywa się w 100% lokalnie na urządzeniu. |
| **Dane zdrowotne** | Informacja o dziennym zużyciu (`dailyIntake`) jest traktowana jako dana wrażliwa i przechowywana lokalnie (Hive). |
| **Logi** | Wartość zużycia **nie jest** wysyłana w logach diagnostycznych (Bug Report). |

---

> 📅 **Ostatnia aktualizacja:** 2026-01-14

---

## 4. Google Play Data Safety

Wypełnienie formularza "Bezpieczeństwo danych" w Google Play Console.

### Deklaracja Główna

- **Does your app collect or share any of the required user data types?** → **Yes**

- **Is all of the user data collected by your app encrypted in transit?** → **Yes** (HTTPS)
- **Do you provide a way for users to request that their data be deleted?** → **No** (Nie dotyczy - brak konta i brak gromadzenia danych na serwerze).

### Szczegółowa Konfiguracja Typów Danych

#### 📷 Photos and Videos -> Photos (Zdjęcia)

Używane w funkcji: Skaner AI (OCR).

- **Is this data collected?** → **Yes**
- **Is this data processed ephemerally?** → **Yes**
    > *Informacja: Zdjęcia są przetwarzane w pamięci i wysyłane do API tylko na czas analizy, nie są zapisywane trwałe w historii konta ani na serwerze.*
- **Is this data shared?** → **No** (Korzystamy z wyjątku "Service Provider" - Gemini przetwarza dane w naszym imieniu).
- **Purposes:** App functionality.
- **Is collection required?** → **No** (Funkcja jest opcjonalna, użytkownik może wpisać dane ręcznie).
