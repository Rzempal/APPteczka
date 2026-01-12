# 💊 Proces dodawania leków – Jak to działa?

> **Powiązane:** [Architektura](architecture.md) | [Model Danych](data_model.md) | [Road Map](road_map.md) | [Tagi](tags.md)

---

Ten dokument wyjaśnia krok po kroku, co dzieje się "pod maską" aplikacji Karton z lekami podczas dodawania nowych produktów.

---

## 🏗️ Główne komponenty (Aktorzy)

| Aktor | Rola (Dla nietechnicznych) | Co robi? |
| :--- | :--- | :--- |
| **📱 Aplikacja (Frontend)** | **Twój asystent** | To, co widzisz na ekranie telefonu. Zbiera dane od Ciebie i pokazuje wyniki. |
| **🌐 Rejestr RPL (API)** | **Urzędowa biblioteka** | Oficjalna polska baza leków (Rejestr Produktów Leczniczych). Zawiera nazwy, ulotki i producentów. |
| **🤖 Gemini AI** | **Ekspert medyczny** | Sztuczna inteligencja od Google. Czyta daty ze zdjęć i wie, na co pomaga dany lek (np. "ból głowy"). |
| **🛡️ Serwer (Vercel Proxy)** | **Bramka bezpieczeństwa** | Łącznik między telefonem a AI. Dba o to, by nikt niepowołany nie korzystał z naszych "mocy" AI. |

---

## 1️⃣ Ścieżka: Skaner kodów kreskowych (Batch Mode)

To najszybszy sposób na dodanie wielu leków naraz.

### Krok 1: Skanowanie kodu (EAN)

* **Użytkownik:** Celuje aparatem w czarno-biały kod paskowy na pudełku.
* **Aplikacja:** Odczytuje numer kodu.
* **API RPL:** Aplikacja pyta "urzędową bibliotekę", co to za lek. Biblioteka odpowiada: *"To Paracetamol 500mg, producent: X, ulotka jest pod tym linkiem"*.

### Krok 2: Zdjęcie daty (Snapshot)

* **Użytkownik:** Celuje aparatem w datę ważności na boku pudełka i klika przycisk.
* **Aplikacja:** Robi małe, czarno-białe zdjęcie (wycinek) samej daty i zapisuje je w pamięci tymczasowej.

### Krok 3: Przetwarzanie zbiorcze (Batch Processing)

* **Użytkownik:** Klika "Zakończ i przetwórz".
* **AI (Gemini - OCR):** Serwer wysyła zdjęcia dat do AI. Gemini "patrzy" na nie i zamienia obrazek na tekst: *"To jest 12.2026"*.
* **AI (Gemini - Wiedza):** Aplikacja pyta Gemini: *"Mam lek Paracetamol 500mg. Powiedz mi o nim więcej"*. Gemini odpowiada: *"Pomaga na gorączkę i ból, dodaj mu tagi #gorączka, #ból"*.

### Krok 4: Zapis

* **Aplikacja:** Łączy dane urzędowe (z biblioteki RPL), datę (od AI) i opisy (od AI). Następnie wkłada to do **Twojego prywatnego pudełka** (pamięć lokalna telefonu).

---

## 2️⃣ Ścieżka: Dodaj ręcznie (Wspomagane AI)

Gdy nie masz pudełka lub kod jest zniszczony.

### Krok 1: Wpisanie nazwy

* **Użytkownik:** Wpisuje np. "Ibuprom" i opcjonalnie wybiera datę z kalendarza.
* **Użytkownik:** Klika "Zapisz".

### Krok 2: Analiza AI (Lookup)

* **AI (Gemini):** Aplikacja wysyła nazwę do Gemini.
* **AI (Gemini):** AI przeszukuje swoją wiedzę i przygotowuje gotową kartę leku: opis działania, na co pomaga (np. "przeciwzapalny") i odpowiednie tagi.

### Krok 3: Walidacja i zapis

* **Aplikacja:** Sprawdza, czy AI rozpoznało lek. Jeśli tak – automatycznie uzupełnia całą kartę i zapisuje ją na telefonie.

---

## 💡 Podsumowanie - dlaczego to jest super?

1. **Nie musisz pisać:** AI robi to za Ciebie, na podstawie zdjęcia lub samej nazwy.
2. **Oficjalne dane:** Aplikacja pobiera dane z prawdziwego polskiego rejestru leków.
3. **Prywatność:** Wszystkie Twoje leki są zapisane **tylko na Twoim telefonie**. AI widzi tylko nazwę leku lub małe zdjęcie daty, aby móc je "przetłumaczyć".

> [!NOTE]
> **Dlaczego Gemini?** Wybraliśmy Gemini, ponieważ najlepiej radzi sobie z językiem polskim i rozumie kontekst medyczny, co pozwala na precyzyjne dopasowanie tagów (np. kojarzy "Paracetamol" z "Grypą").
