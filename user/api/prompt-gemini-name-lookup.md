# Prompt Gemini Name Lookup – Wyszukiwanie po Nazwie

> **Endpoint:** `/api/gemini-name-lookup`  
> **Funkcja:** `generateNameLookupPrompt(name)`  
> **Model:** `gemini-3-flash-preview`  
> **Plik źródłowy:**
> [prompts.ts](file:///c:/Users/rzemp/GitHub/APPteczka/apps/web/src/lib/prompts.ts#L90-L174)

---

## Oryginalny Prompt

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

## Format wyjścia (OBOWIĄZKOWY)

### Gdy rozpoznano produkt:

```json
{
	"status": "rozpoznano",
	"lek": {
		"nazwa": "Poprawna nazwa produktu",
		"opis": "Krótki opis działania. Stosować zgodnie z ulotką.",
		"wskazania": ["wskazanie1", "wskazanie2"],
		"tagi": ["tag1", "tag2"]
	}
}
```
````

### Gdy nie rozpoznano:

```json
{
	"status": "nie_rozpoznano",
	"reason": "Nie znaleziono produktu o podanej nazwie w bazie leków, suplementów ani wyrobów medycznych."
}
```

## Zasady treści

- Język prosty, niemedyczny (np. „lek przeciwbólowy").
- Nie podawaj dawkowania ani ostrzeżeń.
- Na końcu opisu zawsze dodaj: **„Stosować zgodnie z ulotką."**

## Dozwolone tagi (kontrolowana lista)

### Klasyfikacja

#### Rodzaj leku

bez recepty, na receptę, suplement, wyrób medyczny

#### Grupa docelowa

dla dorosłych, dla dzieci, dla kobiet w ciąży, dla niemowląt

#### Typ infekcji

grypa, infekcja bakteryjna, infekcja grzybicza, infekcja wirusowa, przeziębienie

### Objawy i działanie

#### Ból

ból, ból gardła, ból głowy, ból menstruacyjny, ból mięśni, ból ucha, mięśnie i stawy, przeciwbólowy

#### Układ pokarmowy

biegunka, kolka, nudności, przeczyszczający, przeciwbiegunkowy, przeciwwymiotny, układ pokarmowy,
wzdęcia, wymioty, zaparcia, zgaga

#### Układ oddechowy

duszność, gorączka, kaszel, katar, nos, przeciwgorączkowy, przeciwkaszlowy, układ oddechowy,
wykrztuśny

#### Skóra i alergia

alergia, nawilżający, oparzenie, przeciwhistaminowy, przeciwświądowy, rana, skóra, sucha skóra,
suche oczy, świąd, ukąszenie, wysypka

#### Inne

afty, antybiotyk, bezsenność, choroba lokomocyjna, jama ustna, odkażający, probiotyk,
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
| Tolerancja literówek | ⭐⭐⭐⭐⭐ | Gemini dobrze radzi sobie z "Ibuprom" vs "ibuprom" vs "IBUPROM" |
| Obsługa skrótów | ⭐⭐⭐⭐ | Rozpoznaje "Apap" jako "Apap Extra" itp. |
| Kontrolowana lista tagów | ⭐⭐⭐⭐ | Spójność z promptem OCR |
| Status rozpoznania | ⭐⭐⭐⭐⭐ | Jasny kontrakt: `rozpoznano` vs `nie_rozpoznano` |

### ⚠️ Luki informacyjne vs. RPL

| Pole Medicine | Dostępne z RPL | Dostarcza ten prompt | Luka |
|---------------|----------------|----------------------|------|
| `nazwa` | ✅ | ✅ | – |
| `ean` | ✅ (GTIN) | ❌ | **BRAKUJE** (nie ma jak pobrać z nazwy) |
| `power` (moc leku) | ✅ | ❌ | **BRAKUJE** |
| `pharmaceuticalForm` | ✅ | ❌ | **BRAKUJE** |
| `leafletUrl` | ✅ | ❌ | **BRAKUJE** |
| `capacity` | ✅ | ❌ | **BRAKUJE** |
| `opis` | ❌ | ✅ | Prompt dostarcza! |
| `wskazania` | ❌ | ✅ | Prompt dostarcza! |
| `tagi` | ❌ | ✅ | Prompt dostarcza! |

### 🏥 Wyroby Medyczne – Analiza

> [!NOTE]
> Prompt explicite wymienia `wyrób medyczny` jako dozwolony typ, ale nie daje szczegółowych instrukcji jak je rozpoznawać.

**Przykłady wyrobów medycznych do rozpoznania:**
- Plastry (np. "Elastoplast", "Hansaplast")
- Opatrunki (np. "Cosmopor")
- Termometry
- Ciśnieniomierze
- Maseczki ochronne
- Inhalatory (bez leku)

---

## Porównanie: Gemini Name Lookup vs. RPL Search

| Scenariusz | Gemini Name Lookup | RPL `searchMedicine(query)` | Wynik |
|------------|-------------------|---------------------------|-------|
| Nazwa dokładna (np. "Apap") | ✅ Rozpoznaje + opis AI | ✅ Zwraca listę wariantów | **RPL lepszy** – oficjalne dane |
| Nazwa z literówką (np. "Apop") | ✅ Rozpoznaje intencję | ❌ Brak wyników | **Gemini lepszy** |
| Nazwa skrócona (np. "Ibu") | ⚠️ Może zgadnąć | ⚠️ Wiele wyników | **Remis** – oba niepewne |
| Wyrób medyczny (np. "Hansaplast") | ✅ Rozpoznaje | ❌ Nie ma w RPL | **Gemini jedyna opcja** |
| Suplement (np. "Rutinoscorbin") | ✅ Rozpoznaje | ⚠️ Częściowo w RPL | **Gemini uzupełnia** |
| Nieznana nazwa (np. "Xyzabc123") | ✅ `nie_rozpoznano` | ✅ Pusta lista | **Oba obsługują** |

---

## Rekomendacje Ulepszenia

### 1. Dodanie pól `power` i `pharmaceuticalForm`

```diff
{
  "status": "rozpoznano",
  "lek": {
    "nazwa": "Poprawna nazwa produktu",
+   "power": "500 mg | null",
+   "postacFarmaceutyczna": "tabletka powlekana | null",
    "opis": "Krótki opis działania...",
    ...
  }
}
````

**Uzasadnienie:** Użytkownik wpisując "Apap" prawdopodobnie ma konkretny wariant. Gemini może
spróbować "domyślić się" najbardziej popularnego.

---

### 2. Dodanie pola `productType` dla jednoznacznej klasyfikacji

```diff
{
  "status": "rozpoznano",
+ "productType": "lek" | "suplement" | "wyrob_medyczny",
  "lek": { ... }
}
```

**Uzasadnienie:** Umożliwia routing – dla leków można później szukać w RPL, dla wyrobów medycznych w
EUDAMED.

---

### 3. Zwracanie wariantów (alternatywa)

```diff
{
  "status": "rozpoznano",
- "lek": { ... }
+ "produkty": [
+   { "nazwa": "Apap 500 mg", ... },
+   { "nazwa": "Apap Extra 500 mg + 65 mg", ... }
+ ]
}
```

**Uzasadnienie:** RPL zwraca listę wariantów. Gemini mógłby robić to samo, zostawiając użytkownikowi
wybór.

---

### 4. Instrukcja dla nazw wieloznacznych

```diff
## Zadanie
...
+ 5. **Nazwy wieloznaczne:** Jeśli nazwa pasuje do wielu produktów (np. "Aspirin" = tabletki,
+    musujące, cardio), zwróć najpopularniejszy wariant i zaznacz w opisie że istnieją inne.
```

---

### 5. Obsługa substancji czynnych

```diff
## Zadanie
...
+ 6. **Substancje czynne:** Jeśli użytkownik wpisze nazwę substancji (np. "ibuprofen", "paracetamol"),
+    zaproponuj najpopularniejszy lek z tą substancją i zaznacz że to sugestia.
```

---

## Scenariusze Użycia

| Scenariusz                      | Oczekiwane zachowanie                                              |
| ------------------------------- | ------------------------------------------------------------------ |
| Użytkownik wpisuje "Apap"       | Rozpoznaj jako "Apap" (bez wariantu), opisz jako lek przeciwbólowy |
| Użytkownik wpisuje "apap 500"   | Rozpoznaj jako "Apap 500 mg", uwzględnij moc                       |
| Użytkownik wpisuje "witamina D" | Rozpoznaj jako suplement, tag "suplement"                          |
| Użytkownik wpisuje "plaster"    | Rozpoznaj jako wyrób medyczny, tag "wyrób medyczny"                |
| Użytkownik wpisuje "xyz123"     | Zwróć `nie_rozpoznano`                                             |

---

## Podsumowanie

| Metryka                                | Wartość                                            |
| -------------------------------------- | -------------------------------------------------- |
| **Skuteczność dla znanych leków**      | 🟢 Wysoka                                          |
| **Skuteczność dla literówek/skrótów**  | 🟢 Wysoka (przewaga nad RPL)                       |
| **Skuteczność dla wyrobów medycznych** | 🟡 Średnia (rozpoznaje, ale brak szczegółów)       |
| **Kompletność danych**                 | 🔴 Niska (brakuje: power, pharmaceuticalForm, ean) |

> [!TIP] **Rekomendacja:** Ten prompt jest używany jako **fallback** gdy EAN nie jest dostępny lub
> produkt nie jest w RPL. Warto go rozszerzyć o pola `power`, `postacFarmaceutyczna` i `productType`
> żeby maksymalizować użyteczność bez odwoływania się do zewnętrznych baz.

---

_Ostatnia aktualizacja: 2026-01-25_
