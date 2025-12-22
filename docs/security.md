# 🔐 Bezpieczeństwo – APPteczka

> **Powiązane:** [Architektura](architecture.md) | [Model Danych](data_model.md)

---

## ⚠️ Disclaimer Medyczny

> [!CAUTION]
> **APPteczka NIE jest narzędziem medycznym.**
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

> 📅 **Ostatnia aktualizacja:** 2025-12-22
