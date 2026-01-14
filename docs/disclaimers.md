# 🛡️ Disclaimers

> **Powiązane:** [Bezpieczeństwo](security.md) | [Roadmap](roadmap.md)

---

## 1. Dlaczego "Karton z lekami" NIE jest Aplikacją Medyczną?

Zgodnie z wytycznymi Google Play (Health Apps vs Medical Apps) oraz EU MDR (Medical Device Regulation), aplikacja **"Karton z lekami"** kwalifikuje się jako narzędzie typu **Health Management / Inventory Tool**, a nie **Medical Device**.

### Kluczowe Różnice

| Aspekt | Medical Device (Wyrób Medyczny) | Karton (Inventory Tool) |
|--------|-------------------------------|-------------------------|
| **Cel** | Diagnoza, leczenie, monitorowanie funkcji życiowych. | Katalogowanie i przypominanie o terminach ważności. |
| **Dane** | Przetwarzanie danych fizjologicznych. | Przetwarzanie etykiet (tekst/obraz) opakowań. |
| **Rekomendacje** | "Zmień dawkę", "Skontaktuj się z lekarzem (alarm)". | Brak rekomendacji terapeutycznych. |
| **Kalkulacje** | Skomplikowane algorytmy diagnostyczne. | Prosta arytmetyka zapasów (ilość / zużycie). |

### Funkcja Kalkulatora Zapasów

Funkcja "Do kiedy wystarczy?" opiera się na prostym działaniu matematycznym:
> `Data Końcowa = Data Dzisiejsza + (Obecny Zapas / Dzienne Zużycie)`

Jest to funkcjonalność **logistyczna**, tożsama z kalkulatorem zapasów w spiżarni, i nie niesie ryzyka medycznego w rozumieniu MDR, pod warunkiem stosowania odpowiednich wyłączeń odpowiedzialności.

---

## 2. Zestawienie Disclaimerów w UI

Aplikacja stosuje wielopoziomowe informowanie użytkownika o charakterze narzędzia.

### A. Ekran Główny i Ustawienia

**Lokalizacja:** `home_screen.dart`, `settings_screen.dart` (sekcja Info)

> "Aplikacja \"Karton z lekami\" służy wyłącznie do organizacji domowej apteczki. Nie jest to wyrób medyczny. Przed użyciem leku zawsze skonsultuj się z lekarzem lub farmaceutą."

### B. Kalkulator Zapasów

**Lokalizacja:** `medicine_detail_sheet.dart` (pod wynikiem)

> "Kalkulacja szacunkowa na podstawie Twoich danych. Nie zastępuje zaleceń lekarza."

### C. Skaner AI (Gemini)

**Lokalizacja:** `gemini_scanner.dart` (przed zatwierdzeniem)

> Wyniki AI są prezentowane jako **sugestie** do edycji, nigdy jako ostateczne dane. Użytkownik musi ręcznie zatwierdzić każdy wynik.

---

## 3. Zabezpieczenia w Prompcie AI

Modele AI (Gemini) otrzymują ścisłe instrukcje systemowe (`system instructions`) uniemożliwiające generowanie porad medycznych.

**Plik źródłowy:** `apps/web/src/lib/dual-ocr.ts`

### Kluczowe Ograniczenia w Prompcie

1. **Rola:** *"Jesteś asystentem farmacji [...] Użytkownik nie ma wiedzy farmaceutycznej."*
2. **Zakaz zgadywania:** *"Zgadywanie jest zabronione. [...] Jeśli nie masz 100% pewności [...], zwróć null."*
3. **Język:** *"Język prosty, niemedyczny."*
4. **Bezpieczeństwo:**
    * ❌ *"Brak porad medycznych."*
    * ❌ *"Brak sugerowania zamienników."*
    * ❌ *"Brak ocen skuteczności."*
    * ❌ *"Nie podawaj dawkowania ani ostrzeżeń."*
5. **Obowiązkowy dopisek:** *"Na końcu opisu zawsze dodaj: „Stosować zgodnie z ulotką.”"*

---

> 📅 **Ostatnia aktualizacja:** 2026-01-14
