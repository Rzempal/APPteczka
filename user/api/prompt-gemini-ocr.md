# Prompt Gemini OCR – Rozpoznawanie ze Zdjęcia

> **Endpoint:** `/api/gemini-ocr`  
> **Funkcja:** `generateImportPrompt()`  
> **Model:** `gemini-3-flash-preview`  
> **Plik źródłowy:**
> [prompts.ts](file:///c:/Users/rzemp/GitHub/APPteczka/apps/web/src/lib/prompts.ts#L9-L85)

---

## Oryginalny Prompt

````markdown
# Prompt – Rozpoznawanie leków ze zdjęcia (Import JSON)

## Rola

Jesteś asystentem farmacji pomagającym użytkownikowi prowadzić prywatną bazę leków.

## Wejście

Zdjęcie opakowania lub opakowań leków.

## Zadanie (Priorytetyzacja)

1. **Kod kreskowy (EAN) to "kotwica pewności".** Jeśli kod kreskowy (EAN-13 lub EAN-8) jest wyraźnie
   widoczny, ZAWSZE zwróć obiekt leku, nawet jeśli nazwa jest nieczytelna lub zasłonięta.
2. Jeśli widzisz kod kreskowy, ale nie możesz odczytać nazwy, ustaw `"nazwa": null`. Kod kreskowy
   wystarczy do identyfikacji w bazie zewnętrznej.
3. Jeśli widzisz nazwę, ale nie widzisz kodu, zwróć `"ean": null`.
4. Jeśli na zdjęciu jest wiele leków, zwróć listę obiektów.

## Zarządzanie Niepewnością

Zwróć status `"niepewne_rozpoznanie"` WYŁĄCZNIE wtedy, gdy:

- Nie potrafisz zidentyfikować ANI nazwy, ANI kodu kreskowego.
- Obraz jest tak rozmazany, że żadne dane tekstowe ani numeryczne nie są czytelne.

W pozostałych przypadkach (gdy masz EAN LUB nazwę) generuj dane.

## Format wyjścia (OBOWIĄZKOWY JSON)

Zwróć **wyłącznie poprawny JSON**, bez dodatkowego tekstu.

```json
{
	"leki": [
		{
			"nazwa": "string | null",
			"ean": "string | null",
			"opis": "string (krótki opis, język prosty)",
			"wskazania": ["string"],
			"tagi": ["tag1", "tag2"],
			"terminWaznosci": "YYYY-MM-DD | null"
		}
	]
}
```
````

### Pole ean (kod kreskowy)

- Jeśli na opakowaniu widoczny jest kod kreskowy (EAN-13 lub EAN-8), zwróć **same cyfry** (np.
  "5909990733828").
- Kody kreskowe na lekach mają zazwyczaj 13 cyfr (EAN-13) lub 8 cyfr (EAN-8).
- Jeśli kod jest niewidoczny, zwróć `null`.

### Pole terminWaznosci

- Jeśli widzisz datę (np. "EXP 03/2026", "03.2026"), zamień na ostatni dzień miesiąca w formacie
  ISO: "2026-03-31".
- Jeśli data jest niewidoczna, zwróć `null`.

## Zasady treści

- Język prosty, niemedyczny (np. „lek przeciwbólowy").
- Nie podawaj dawkowania ani ostrzeżeń.
- Na końcu opisu zawsze dodaj: **„Stosować zgodnie z ulotką."**
- Leki złożone traktuj jako jedną pozycję.

## Dozwolone tagi (kontrolowana lista)

### Klasyfikacja

- **Rodzaj leku:** bez recepty, na receptę, suplement, wyrób medyczny
- **Grupa docelowa:** dla dorosłych, dla dzieci, dla kobiet w ciąży, dla niemowląt
- **Typ infekcji:** grypa, infekcja bakteryjna, infekcja grzybicza, infekcja wirusowa, przeziębienie

### Objawy i działanie

- **Ból:** ból, ból gardła, ból głowy, ból menstruacyjny, ból mięśni, ból ucha, mięśnie i stawy,
  przeciwbólowy
- **Układ pokarmowy:** biegunka, kolka, nudności, przeczyszczający, przeciwbiegunkowy,
  przeciwwymiotny, układ pokarmowy, wzdęcia, wymioty, zaparcia, zgaga
- **Układ oddechowy:** duszność, gorączka, kaszel, katar, nos, przeciwgorączkowy, przeciwkaszlowy,
  układ oddechowy, wykrztuśny
- **Skóra i alergia:** alergia, nawilżający, oparzenie, przeciwhistaminowy, przeciwświądowy, rana,
  skóra, sucha skóra, suche oczy, świąd, ukąszenie, wysypka
- **Inne:** afty, antybiotyk, bezsenność, choroba lokomocyjna, jama ustna, odkażający, probiotyk,
  przeciwzapalny, rozkurczowy, steryd, stres, układ nerwowy, uspokajający, ząbkowanie

## Ograniczenia

- Brak porad medycznych.
- Brak sugerowania zamienników.
- Brak ocen skuteczności.

Celem jest wyłącznie **porządkowanie informacji do prywatnej bazy leków użytkownika**.

````

---

## Analiza Skuteczności

### ✅ Mocne strony

| Aspekt | Ocena | Komentarz |
|--------|-------|-----------|
| Priorytetyzacja EAN | ⭐⭐⭐⭐⭐ | Strategia "kotwicy pewności" – nawet przy nieczytelnej nazwie EAN pozwala na identyfikację w RPL |
| Format JSON | ⭐⭐⭐⭐⭐ | Wymuszony format strukturalny eliminuje problemy z parsowaniem |
| Kontrolowana lista tagów | ⭐⭐⭐⭐ | Zapobiega halucynacjom i zachowuje spójność danych |
| Obsługa niepewności | ⭐⭐⭐⭐ | Jasne kryteria kiedy zwracać błąd |

### ⚠️ Luki informacyjne vs. RPL

| Pole Medicine | Dostępne z RPL | Dostarcza ten prompt | Luka |
|---------------|----------------|----------------------|------|
| `nazwa` | ✅ | ✅ | – |
| `ean` | ✅ (GTIN) | ✅ | – |
| `power` (moc leku) | ✅ | ❌ | **BRAKUJE** |
| `pharmaceuticalForm` | ✅ | ❌ | **BRAKUJE** |
| `leafletUrl` | ✅ | ❌ | **BRAKUJE** (niedostępne z obrazu) |
| `capacity` (ilość w opakowaniu) | ✅ | ❌ | **BRAKUJE** |
| `terminWaznosci` | ❌ | ✅ | Prompt dostarcza! |
| `opis` | ❌ | ✅ | Prompt dostarcza! |
| `wskazania` | ❌ | ✅ | Prompt dostarcza! |
| `tagi` | ❌ | ✅ | Prompt dostarcza! |

### 🏥 Wyroby Medyczne – Analiza

> [!WARNING]
> **Prompt nie rozróżnia wyrobów medycznych od leków.** Wyroby medyczne (np. plaster, ciśnieniomierz, opatrunek) nie są w RPL, ale prompt nie prosi o oznaczenie tego faktu.

**Problemy:**
1. Tag `wyrób medyczny` istnieje, ale nie jest wyraźnie promowany
2. Brak instrukcji: "Jeśli produkt nie jest lekiem, oznacz jako wyrób medyczny"
3. Dla wyrobów medycznych EAN jest jedynym identyfikatorem (brak bazy jak RPL)

---

## Porównanie: Gemini OCR vs. Skanowanie RPL

| Scenariusz | Gemini OCR | RPL (po EAN) | Wynik |
|------------|-----------|--------------|-------|
| Lek z widocznym EAN | ✅ Zwraca EAN + opis AI | ✅ Pełne dane oficjalne | **RPL lepszy** – dane urzędowe |
| Lek bez EAN (zasłonięty) | ⚠️ Tylko nazwa + AI opis | ❌ Brak możliwości | **Gemini jedyna opcja** |
| Wyrób medyczny | ✅ Rozpoznaje (z tagiem) | ❌ Nie ma w RPL | **Gemini jedyna opcja** |
| Suplement diety | ✅ Rozpoznaje | ⚠️ Częściowo w RPL | **Gemini uzupełnia** |
| Zdjęcie nieczytelne | ❌ `niepewne_rozpoznanie` | ❌ Brak EAN = brak danych | **Obydwa failują** |

---

## Rekomendacje Ulepszenia

### 1. Dodanie pola `power` (moc leku)

```diff
{
  "nazwa": "string | null",
+ "power": "string | null (np. '500 mg', '10 ml')",
  "ean": "string | null",
  ...
}
````

**Uzasadnienie:** Moc leku jest kluczowa dla identyfikacji wariantu (np. Ibuprom 200mg vs 400mg).

---

### 2. Dodanie pola `capacity` (ilość w opakowaniu)

```diff
{
  ...
+ "capacity": "string | null (np. '30 tabletek', '100 ml')",
  ...
}
```

**Uzasadnienie:** Pole `capacity` jest używane do kalkulacji zapasu leku (`calculateSupplyEndDate`).

---

### 3. Dodanie pola `pharmaceuticalForm` (postać farmaceutyczna)

```diff
{
  ...
+ "postacFarmaceutyczna": "string | null (np. 'tabletka powlekana', 'syrop')",
  ...
}
```

**Uzasadnienie:** Postać determinuje ikonę w UI oraz jednostkę (`PackageUnit`).

---

### 4. Wzmocnienie instrukcji dla wyrobów medycznych

```diff
## Zadanie (Priorytetyzacja)
...
+ 5. **Wyroby medyczne:** Jeśli produkt NIE jest lekiem (np. plaster, opatrunek, ciśnieniomierz,
+    termometr), ZAWSZE dodaj tag "wyrób medyczny" i opisz przeznaczenie produktu.
```

---

### 5. Dodanie pola `productType` dla jednoznacznej klasyfikacji

```diff
{
+ "productType": "lek" | "suplement" | "wyrob_medyczny",
  "nazwa": "string | null",
  ...
}
```

**Uzasadnienie:** Umożliwia routing do odpowiedniej bazy (RPL vs. EUDAMED vs. brak bazy).

---

## Podsumowanie

| Metryka                                | Wartość                                                 |
| -------------------------------------- | ------------------------------------------------------- |
| **Skuteczność dla leków z EAN**        | 🟢 Wysoka (EAN → RPL uzupełnia brakujące dane)          |
| **Skuteczność dla leków bez EAN**      | 🟡 Średnia (tylko dane AI, brak weryfikacji)            |
| **Skuteczność dla wyrobów medycznych** | 🟡 Średnia (rozpoznaje, ale brak weryfikacji w EUDAMED) |
| **Kompletność danych**                 | 🔴 Niska (brakuje: power, capacity, pharmaceuticalForm) |

> [!TIP] **Rekomendacja:** Rozszerz strukturę JSON o pola `power`, `capacity`,
> `postacFarmaceutyczna` i `productType`. To pozwoli Gemini dostarczyć wszystkie informacje
> potrzebne bez dodatkowego zapytania do RPL.

---

_Ostatnia aktualizacja: 2026-01-25_
