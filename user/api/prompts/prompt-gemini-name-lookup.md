# Prompt Gemini Name Lookup – Wyszukiwanie po Nazwie

> **Endpoint:** `/api/gemini-name-lookup`  
> **Funkcja:** `generateNameLookupPrompt(name)`  
> **Model:** `gemini-3-flash-preview`  
> **Plik źródłowy:**
> [prompts.ts](file:///c:/Users/rzemp/GitHub/APPteczka/apps/web/src/lib/prompts.ts#L114-L220)  
> **Wersja:** v0.004 (Extended fields)

---

## ✅ Status Implementacji

> [!NOTE] **Wszystkie rekomendacje z poprzedniego audytu zostały zaimplementowane w wersji v0.004.**

| Rekomendacja                        | Status              | Commit |
| ----------------------------------- | ------------------- | ------ |
| Dodanie pola `power`                | ✅ Zaimplementowane | v0.004 |
| Dodanie pola `postacFarmaceutyczna` | ✅ Zaimplementowane | v0.004 |
| Dodanie pola `productType`          | ✅ Zaimplementowane | v0.004 |
| Dodanie pola `capacity`             | ✅ Zaimplementowane | v0.004 |
| Instrukcje dla wyrobów medycznych   | ✅ Zaimplementowane | v0.004 |

---

## Aktualny Prompt (v0.004)

````markdown
# Prompt – Rozpoznawanie leku po nazwie

## Rola

Jesteś asystentem farmacji pomagającym użytkownikowi prowadzić prywatną bazę leków (domową
apteczkę). Użytkownik nie ma wiedzy farmaceutycznej.

## Wejście

Użytkownik wpisał nazwę: "${name}"

## Zadanie

1. Sprawdź czy wpisana nazwa odpowiada jednemu z typów: **lek OTC, lek na receptę, suplement diety,
   wyrób medyczny**.
2. Jeśli rozpoznajesz produkt, uzupełnij informacje o nim.
3. Dozwolone są literówki i skróty - spróbuj rozpoznać zamiar użytkownika.
4. **Nie zgaduj** – jeśli nazwa jest całkowicie nieznana, zwróć status "nie_rozpoznano".
5. **Wyroby medyczne:** Jeśli produkt NIE jest lekiem ani suplementem (np. plaster, opatrunek,
   termometr), ustaw `"productType": "wyrob_medyczny"`.

## Format wyjścia (OBOWIĄZKOWY)

### Gdy rozpoznano produkt:

```json
{
	"status": "rozpoznano",
	"productType": "lek | suplement | wyrob_medyczny",
	"lek": {
		"nazwa": "Poprawna nazwa produktu",
		"power": "string | null (np. '500 mg')",
		"capacity": "string | null (np. '30 tabletek')",
		"postacFarmaceutyczna": "string | null (np. 'tabletka powlekana')",
		"opis": "Krótki opis działania. Stosować zgodnie z ulotką.",
		"wskazania": ["wskazanie1", "wskazanie2"],
		"tagi": ["tag1", "tag2"]
	}
}
```
````

````

---

## Opis Pól (po rozszerzeniu v0.004)

| Pole | Typ | Opis | Źródło |
|------|-----|------|--------|
| `status` | enum | `rozpoznano` / `nie_rozpoznano` | AI decision |
| `productType` | enum | `lek` / `suplement` / `wyrob_medyczny` | **NEW v0.004** |
| `nazwa` | string | Poprawiona nazwa produktu | AI generated |
| `power` | string/null | Najpopularniejsza moc/dawka (np. "500 mg") | **NEW v0.004** |
| `capacity` | string/null | Najpopularniejsza ilość (np. "30 tabletek") | **NEW v0.004** |
| `postacFarmaceutyczna` | string/null | Forma produktu (np. "syrop") | **NEW v0.004** |
| `opis` | string | Krótki opis działania | AI generated |
| `wskazania` | string[] | Lista wskazań | AI generated |
| `tagi` | string[] | Tagi z kontrolowanej listy | AI generated |

---

## Analiza Skuteczności

### ✅ Mocne strony

| Aspekt | Ocena | Komentarz |
|--------|-------|-----------|
| Tolerancja literówek | ⭐⭐⭐⭐⭐ | Gemini dobrze radzi sobie z "Ibuprom" vs "ibuprom" vs "IBUPROM" |
| Obsługa skrótów | ⭐⭐⭐⭐ | Rozpoznaje "Apap" jako "Apap Extra" itp. |
| Kontrolowana lista tagów | ⭐⭐⭐⭐ | Spójność z promptem OCR |
| Status rozpoznania | ⭐⭐⭐⭐⭐ | Jasny kontrakt: `rozpoznano` vs `nie_rozpoznano` |
| **Rozszerzone pola v0.004** | ⭐⭐⭐⭐⭐ | `power`, `capacity`, `postacFarmaceutyczna`, `productType` – pełna autonomia od RPL |

### Porównanie z RPL (po v0.004)

| Pole Medicine | Dostępne z RPL | Dostarcza prompt v0.004 | Status |
|---------------|----------------|-------------------------|--------|
| `nazwa` | ✅ | ✅ | ✅ Pokrywa |
| `ean` | ✅ (GTIN) | ❌ | ⚠️ Niedostępne z nazwy |
| `power` (moc leku) | ✅ | ✅ | ✅ **NAPRAWIONE** |
| `pharmaceuticalForm` | ✅ | ✅ | ✅ **NAPRAWIONE** |
| `leafletUrl` | ✅ | ❌ | ⚠️ Niedostępne z nazwy |
| `capacity` | ✅ | ✅ | ✅ **NAPRAWIONE** |
| `productType` | ❌ | ✅ | ✅ **NOWE** |
| `opis` | ❌ | ✅ | ✅ Prompt dostarcza |
| `wskazania` | ❌ | ✅ | ✅ Prompt dostarcza |
| `tagi` | ❌ | ✅ | ✅ Prompt dostarcza |

---

## Porównanie: Gemini Name Lookup vs. RPL Search

| Scenariusz | Gemini Name Lookup v0.004 | RPL `searchMedicine(query)` | Wynik |
|------------|---------------------------|------------------------------|-------|
| Nazwa dokładna (np. "Apap") | ✅ Rozpoznaje + pełne dane AI | ✅ Zwraca listę wariantów | **Komplementarne** |
| Nazwa z literówką (np. "Apop") | ✅ Rozpoznaje intencję | ❌ Brak wyników | **Gemini lepszy** |
| Nazwa skrócona (np. "Ibu") | ⚠️ Może zgadnąć | ⚠️ Wiele wyników | **Remis** |
| Wyrób medyczny (np. "Hansaplast") | ✅ `productType: wyrob_medyczny` | ❌ Nie ma w RPL | **Gemini jedyna opcja** |
| Suplement (np. "Rutinoscorbin") | ✅ `productType: suplement` | ⚠️ Częściowo w RPL | **Gemini uzupełnia** |
| Nieznana nazwa (np. "Xyzabc123") | ✅ `nie_rozpoznano` | ✅ Pusta lista | **Oba obsługują** |

---

## Potencjalne Dalsze Rozszerzenia

### 1. Zwracanie wariantów (alternatywa)

```diff
{
  "status": "rozpoznano",
  "productType": "lek",
- "lek": { ... }
+ "produkty": [
+   { "nazwa": "Apap 500 mg", "power": "500 mg", ... },
+   { "nazwa": "Apap Extra 500 mg + 65 mg", "power": "500 mg + 65 mg", ... }
+ ]
}
````

**Uzasadnienie:** Użytkownik mógłby wybrać dokładny wariant.

### 2. Obsługa substancji czynnych

```diff
## Zadanie
...
+ 6. **Substancje czynne:** Jeśli użytkownik wpisze nazwę substancji (np. "ibuprofen", "paracetamol"),
+    zaproponuj najpopularniejszy lek z tą substancją i zaznacz że to sugestia.
```

---

## Scenariusze Użycia

| Scenariusz                      | Oczekiwane zachowanie                                          |
| ------------------------------- | -------------------------------------------------------------- |
| Użytkownik wpisuje "Apap"       | Rozpoznaj jako "Apap", `power`: najpopularniejsza dawka        |
| Użytkownik wpisuje "apap 500"   | Rozpoznaj jako "Apap 500 mg", `power: "500 mg"`                |
| Użytkownik wpisuje "witamina D" | Rozpoznaj jako suplement, `productType: "suplement"`           |
| Użytkownik wpisuje "plaster"    | Rozpoznaj jako wyrób medyczny, `productType: "wyrob_medyczny"` |
| Użytkownik wpisuje "xyz123"     | Zwróć `nie_rozpoznano`                                         |

---

## Podsumowanie (po v0.004)

| Metryka                                | Poprzednio | Po v0.004 |
| -------------------------------------- | ---------- | --------- |
| **Skuteczność dla znanych leków**      | 🟢 Wysoka  | 🟢 Wysoka |
| **Skuteczność dla literówek/skrótów**  | 🟢 Wysoka  | 🟢 Wysoka |
| **Skuteczność dla wyrobów medycznych** | 🟡 Średnia | 🟢 Wysoka |
| **Kompletność danych**                 | 🔴 Niska   | 🟢 Wysoka |

> [!TIP] **Prompt v0.004 jest w pełni funkcjonalny.** Ten prompt jest używany jako **fallback** gdy
> EAN nie jest dostępny lub produkt nie jest w RPL. Dostarcza pola `power`, `capacity`,
> `postacFarmaceutyczna` i `productType`, maksymalizując użyteczność bez odwoływania się do
> zewnętrznych baz.

---

_Ostatnia aktualizacja: 2026-01-25 (review v0.004)_
