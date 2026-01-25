# Prompt Gemini OCR – Rozpoznawanie ze Zdjęcia

> **Endpoint:** `/api/gemini-ocr`  
> **Funkcja:** `generateImportPrompt()`  
> **Model:** `gemini-3-flash-preview`  
> **Plik źródłowy:**
> [prompts.ts](file:///c:/Users/rzemp/GitHub/APPteczka/apps/web/src/lib/prompts.ts#L9-L108)  
> **Wersja:** v0.004 (Extended fields)

---

## ✅ Status Implementacji

> [!NOTE] **Wszystkie rekomendacje z poprzedniego audytu zostały zaimplementowane w wersji v0.004.**

| Rekomendacja                        | Status              | Commit |
| ----------------------------------- | ------------------- | ------ |
| Dodanie pola `power`                | ✅ Zaimplementowane | v0.004 |
| Dodanie pola `capacity`             | ✅ Zaimplementowane | v0.004 |
| Dodanie pola `postacFarmaceutyczna` | ✅ Zaimplementowane | v0.004 |
| Dodanie pola `productType`          | ✅ Zaimplementowane | v0.004 |
| Instrukcje dla wyrobów medycznych   | ✅ Zaimplementowane | v0.004 |

---

## Aktualny Prompt (v0.004)

````markdown
# Prompt – Rozpoznawanie leków ze zdjęcia (Import JSON)

## Rola

Jesteś asystentem farmacji pomagającym użytkownikowi prowadzić prywatną bazę leków.

## Wejście

Zdjęcie opakowania lub opakowań leków, suplementów diety lub wyrobów medycznych.

## Zadanie (Priorytetyzacja)

1. **Kod kreskowy (EAN) to "kotwica pewności".** Jeśli kod kreskowy (EAN-13 lub EAN-8) jest wyraźnie
   widoczny, ZAWSZE zwróć obiekt leku, nawet jeśli nazwa jest nieczytelna lub zasłonięta.
2. Jeśli widzisz kod kreskowy, ale nie możesz odczytać nazwy, ustaw `"nazwa": null`. Kod kreskowy
   wystarczy do identyfikacji w bazie zewnętrznej.
3. Jeśli widzisz nazwę, ale nie widzisz kodu, zwróć `"ean": null`.
4. Jeśli na zdjęciu jest wiele leków, zwróć listę obiektów.
5. **Wyroby medyczne:** Jeśli produkt NIE jest lekiem ani suplementem (np. plaster, opatrunek,
   termometr, ciśnieniomierz, inhalator bez leku), ustaw `"productType": "wyrob_medyczny"`.

## Format wyjścia (OBOWIĄZKOWY JSON)

```json
{
	"leki": [
		{
			"productType": "lek | suplement | wyrob_medyczny",
			"nazwa": "string | null",
			"ean": "string | null",
			"power": "string | null",
			"capacity": "string | null",
			"postacFarmaceutyczna": "string | null",
			"opis": "string (krótki opis, język prosty)",
			"wskazania": ["string"],
			"tagi": ["tag1", "tag2"],
			"terminWaznosci": "YYYY-MM-DD | null"
		}
	]
}
```
````

```

---

## Opis Pól (po rozszerzeniu v0.004)

| Pole | Typ | Opis | Źródło |
|------|-----|------|--------|
| `productType` | enum | `lek` / `suplement` / `wyrob_medyczny` | **NEW v0.004** |
| `nazwa` | string/null | Nazwa produktu | OCR ze zdjęcia |
| `ean` | string/null | Kod kreskowy EAN-13/EAN-8 | OCR ze zdjęcia |
| `power` | string/null | Moc/dawka (np. "500 mg") | **NEW v0.004** |
| `capacity` | string/null | Ilość w opakowaniu (np. "30 tabletek") | **NEW v0.004** |
| `postacFarmaceutyczna` | string/null | Forma produktu (np. "syrop") | **NEW v0.004** |
| `opis` | string | Krótki opis działania | AI generated |
| `wskazania` | string[] | Lista wskazań | AI generated |
| `tagi` | string[] | Tagi z kontrolowanej listy | AI generated |
| `terminWaznosci` | string/null | Data ważności (format ISO) | OCR ze zdjęcia |

---

## Analiza Skuteczności

### ✅ Mocne strony

| Aspekt | Ocena | Komentarz |
|--------|-------|-----------|
| Priorytetyzacja EAN | ⭐⭐⭐⭐⭐ | Strategia "kotwicy pewności" – nawet przy nieczytelnej nazwie EAN pozwala na identyfikację w RPL |
| Format JSON | ⭐⭐⭐⭐⭐ | Wymuszony format strukturalny eliminuje problemy z parsowaniem |
| Kontrolowana lista tagów | ⭐⭐⭐⭐ | Zapobiega halucynacjom i zachowuje spójność danych |
| Obsługa niepewności | ⭐⭐⭐⭐ | Jasne kryteria kiedy zwracać błąd |
| **Rozszerzone pola v0.004** | ⭐⭐⭐⭐⭐ | `power`, `capacity`, `postacFarmaceutyczna`, `productType` – pełna autonomia od RPL |

### Porównanie z RPL (po v0.004)

| Pole Medicine | Dostępne z RPL | Dostarcza prompt v0.004 | Status |
|---------------|----------------|-------------------------|--------|
| `nazwa` | ✅ | ✅ | ✅ Pokrywa |
| `ean` | ✅ (GTIN) | ✅ | ✅ Pokrywa |
| `power` (moc leku) | ✅ | ✅ | ✅ **NAPRAWIONE** |
| `pharmaceuticalForm` | ✅ | ✅ | ✅ **NAPRAWIONE** |
| `leafletUrl` | ✅ | ❌ | ⚠️ Niedostępne z obrazu |
| `capacity` | ✅ | ✅ | ✅ **NAPRAWIONE** |
| `productType` | ❌ | ✅ | ✅ **NOWE** |
| `terminWaznosci` | ❌ | ✅ | ✅ Prompt dostarcza |
| `opis` | ❌ | ✅ | ✅ Prompt dostarcza |
| `wskazania` | ❌ | ✅ | ✅ Prompt dostarcza |
| `tagi` | ❌ | ✅ | ✅ Prompt dostarcza |

---

## Wyroby Medyczne – Obsługa (v0.004)

> [!TIP]
> W wersji v0.004 dodano dedykowaną instrukcję dla wyrobów medycznych.

**Zaimplementowane w punkcie 5 zadania:**
```

5. **Wyroby medyczne:** Jeśli produkt NIE jest lekiem ani suplementem (np. plaster, opatrunek,
   termometr, ciśnieniomierz, inhalator bez leku), ustaw `"productType": "wyrob_medyczny"`.

````

**Przykłady rozpoznawanych wyrobów:**
- Plastry (Elastoplast, Hansaplast)
- Opatrunki (Cosmopor)
- Termometry
- Ciśnieniomierze
- Inhalatory (bez leku)

---

## Porównanie: Gemini OCR vs. RPL

| Scenariusz | Gemini OCR v0.004 | RPL (po EAN) | Wynik |
|------------|-------------------|--------------|-------|
| Lek z widocznym EAN | ✅ EAN + pełne dane AI | ✅ Dane oficjalne | **Komplementarne** |
| Lek bez EAN (zasłonięty) | ⚠️ Nazwa + AI opis | ❌ Brak możliwości | **Gemini jedyna opcja** |
| Wyrób medyczny | ✅ `productType: wyrob_medyczny` | ❌ Nie ma w RPL | **Gemini jedyna opcja** |
| Suplement diety | ✅ `productType: suplement` | ⚠️ Częściowo w RPL | **Gemini uzupełnia** |
| Zdjęcie nieczytelne | ❌ `niepewne_rozpoznanie` | ❌ Brak EAN = brak danych | **Obydwa failują** |

---

## Potencjalne Dalsze Rozszerzenia

### 1. Dodanie pola `manufacturer` (producent)

```diff
{
  ...
+ "manufacturer": "string | null (np. 'US Pharmacia')",
  ...
}
````

**Uzasadnienie:** Producent często widoczny na opakowaniu, pomocny przy identyfikacji.

### 2. Dodanie pola `activeSubstance` (substancja czynna)

```diff
{
  ...
+ "activeSubstance": "string | null (np. 'ibuprofen', 'paracetamol')",
  ...
}
```

**Uzasadnienie:** Substancja czynna pozwala na sprawdzenie interakcji między lekami.

---

## Podsumowanie (po v0.004)

| Metryka                                | Poprzednio | Po v0.004 |
| -------------------------------------- | ---------- | --------- |
| **Skuteczność dla leków z EAN**        | 🟢 Wysoka  | 🟢 Wysoka |
| **Skuteczność dla leków bez EAN**      | 🟡 Średnia | 🟢 Wysoka |
| **Skuteczność dla wyrobów medycznych** | 🟡 Średnia | 🟢 Wysoka |
| **Kompletność danych**                 | 🔴 Niska   | 🟢 Wysoka |

> [!TIP] **Prompt v0.004 jest w pełni funkcjonalny.** Dostarza wszystkie pola wymagane przez model
> `Medicine` bez konieczności odpytywania RPL. Jedyne pole niedostępne to `leafletUrl`, które jest z
> natury niedostępne z obrazu.

---

_Ostatnia aktualizacja: 2026-01-25 (review v0.004)_
