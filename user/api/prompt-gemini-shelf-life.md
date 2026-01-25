# Prompt Gemini Shelf Life – Analiza Ulotki PDF

> **Endpoint:** `/api/gemini-shelf-life`  
> **Funkcja:** `generateShelfLifePrompt()`  
> **Model:** `gemini-3-flash-preview`  
> **Plik źródłowy:**
> [prompts.ts](file:///c:/Users/rzemp/GitHub/APPteczka/apps/web/src/lib/prompts.ts#L179-L240)

---

## Oryginalny Prompt

````markdown
# Prompt – Analiza terminu ważności produktu po pierwszym otwarciu

## Rola

Jesteś asystentem farmacji analizującym ulotki leków.

## Wejście

Ulotka leku w formacie PDF.

## Zadanie

1. Przeszukaj ulotkę w poszukiwaniu informacji o **terminie ważności produktu po pierwszym
   otwarciu**.
2. Informacja ta zazwyczaj znajduje się w sekcjach:
   - "Termin ważności"
   - "Przechowywanie"
   - "Warunki przechowywania"
   - "Okres ważności po pierwszym otwarciu"
3. Szukaj fraz takich jak:
   - "Po otwarciu zużyć w ciągu [okres]"
   - "Okres ważności po otwarciu: [okres]"
   - "Po pierwszym otwarciu należy zużyć w ciągu [okres]"
   - "Termin przydatności po otwarciu opakowania: [okres]"

## Format wyjścia (OBOWIĄZKOWY JSON)

### Gdy znaleziono informację:

```json
{
	"status": "znaleziono",
	"shelfLife": "dosłowny cytat z ulotki",
	"period": "6 miesięcy"
}
```
````

Pole `shelfLife` powinno zawierać **dosłowny cytat** z ulotki (całe zdanie). Pole `period` powinno
zawierać **tylko okres** w formacie naturalnym (np. "6 miesięcy", "30 dni", "2 tygodnie", "1 rok").

### Gdy nie znaleziono:

```json
{
	"status": "nie_znaleziono",
	"reason": "W ulotce nie znaleziono informacji o terminie ważności po pierwszym otwarciu."
}
```

## Zasady

- **DOSŁOWNY CYTAT** – nie zmieniaj, nie parafrazuj, kopiuj dokładnie jak jest w ulotce.
- Jeśli w ulotce jest kilka różnych terminów dla różnych postaci (np. "po otwarciu butelki: 30 dni",
  "po otwarciu saszetki: 24h"), wybierz najbardziej ogólny lub pierwszy wymieniony.
- Jeśli naprawdę nie ma żadnej informacji o terminie po otwarciu, zwróć "nie_znaleziono".
- Zwróć **wyłącznie JSON**, bez dodatkowego tekstu.

## Ograniczenia

- Brak interpretacji terminów.
- Brak rad medycznych.
- Wyłącznie kopiowanie faktów z ulotki.

Celem jest **wyłącznie ekstrakcja faktów z dokumentu**.

````

---

## Analiza Skuteczności

### ✅ Mocne strony

| Aspekt | Ocena | Komentarz |
|--------|-------|-----------|
| Jasność zadania | ⭐⭐⭐⭐⭐ | Jednoznaczne – znajdź termin po otwarciu |
| Wymuszenie cytatu | ⭐⭐⭐⭐⭐ | "DOSŁOWNY CYTAT" zapobiega halucynacjom |
| Lista fraz do szukania | ⭐⭐⭐⭐ | Pomaga modelowi zlokalizować informację |
| Normalizacja okresu | ⭐⭐⭐⭐ | `period` w formacie naturalnym ułatwia przetwarzanie |

### ⚠️ Luki informacyjne

| Aspekt | Dostępne z ulotki | Dostarcza ten prompt | Luka |
|--------|-------------------|----------------------|------|
| Okres ważności po otwarciu | ✅ | ✅ | – |
| Warunki przechowywania | ✅ | ❌ | **BRAKUJE** |
| Temperatura przechowywania | ✅ | ❌ | **BRAKUJE** |
| Przeciwwskazania | ✅ | ❌ | **Poza zakresem** |
| Interakcje | ✅ | ❌ | **Poza zakresem** |

### 🏥 Wyroby Medyczne – Analiza

> [!CAUTION]
> **Wyroby medyczne zazwyczaj nie mają ulotek PDF w formacie farmaceutycznym.** Ten prompt jest dedykowany lekom z ChPL (Charakterystyka Produktu Leczniczego).

**Problemy dla wyrobów medycznych:**
1. Wyroby medyczne mają instrukcje obsługi, nie ulotki
2. Format dokumentacji różni się od farmaceutycznego
3. Termin "po otwarciu" może nie mieć zastosowania (np. termometr)

**Sugestia:** Dodać osobny prompt dla wyrobów medycznych lub jasno oznaczyć że ten prompt jest tylko dla leków.

---

## Porównanie: Gemini Shelf Life vs. Dane RPL

| Aspekt | Gemini Shelf Life | RPL / ChPL | Wynik |
|--------|-------------------|-----------|-------|
| Termin po otwarciu | ✅ Ekstrahuje z PDF | ❌ Nie ma w API | **Gemini jedyna opcja** |
| Warunki przechowywania | ❌ Nie ekstrahuje | ❌ Nie ma w API | **Luka – można dodać** |
| Dokładność | ⭐⭐⭐⭐ Cytat z źródła | N/A | **Wysoka wiarygodność** |
| Automatyzacja | ✅ Pełna | N/A | **Kluczowa wartość** |

---

## Rekomendacje Ulepszenia

### 1. Dodanie ekstrakcji warunków przechowywania

```diff
## Zadanie
1. Przeszukaj ulotkę w poszukiwaniu informacji o **terminie ważności produktu po pierwszym otwarciu**.
+ 2. Dodatkowo znajdź **warunki przechowywania** (temperatura, wilgotność, światło).
...

## Format wyjścia (OBOWIĄZKOWY JSON)

### Gdy znaleziono informację:

```json
{
  "status": "znaleziono",
  "shelfLife": "dosłowny cytat z ulotki",
  "period": "6 miesięcy",
+ "storage": "Przechowywać w temperaturze poniżej 25°C. Chronić przed światłem."
}
````

````

**Uzasadnienie:** Warunki przechowywania są często obok terminu ważności i są wartościowe dla użytkownika.

---

### 2. Normalizacja `period` do dni

```diff
{
  "status": "znaleziono",
  "shelfLife": "dosłowny cytat z ulotki",
  "period": "6 miesięcy",
+ "periodDays": 180
}
````

**Uzasadnienie:** Ułatwia obliczenie daty "Zużyć przed" w aplikacji bez parsowania stringa.

---

### 3. Obsługa wielu terminów

````diff
## Zasady
...
- Jeśli w ulotce jest kilka różnych terminów dla różnych postaci (np. "po otwarciu butelki: 30 dni",
-   "po otwarciu saszetki: 24h"), wybierz najbardziej ogólny lub pierwszy wymieniony.
+ Jeśli w ulotce jest kilka różnych terminów dla różnych postaci, zwróć wszystkie:
+
+ ```json
+ {
+   "status": "znaleziono",
+   "variants": [
+     { "condition": "po otwarciu butelki", "period": "30 dni" },
+     { "condition": "po otwarciu saszetki", "period": "24 godziny" }
+   ]
+ }
+ ```
````

**Uzasadnienie:** Niektóre leki (np. syropy, krople) mają różne terminy dla różnych opakowań.

---

### 4. Wyraźne wykluczenie wyrobów medycznych

```diff
## Rola
- Jesteś asystentem farmacji analizującym ulotki leków.
+ Jesteś asystentem farmacji analizującym ulotki **leków** (produktów leczniczych).
+ Ten prompt NIE jest przeznaczony dla wyrobów medycznych.
```

---

### 5. Fallback dla brakującej informacji

````diff
### Gdy nie znaleziono:

```json
{
  "status": "nie_znaleziono",
- "reason": "W ulotce nie znaleziono informacji o terminie ważności po pierwszym otwarciu."
+ "reason": "W ulotce nie znaleziono informacji o terminie ważności po pierwszym otwarciu.",
+ "suggestion": "Dla produktów bez podanego terminu po otwarciu, stosuj ogólną zasadę: krople do oczu - 4 tygodnie, syropy - 6 miesięcy, maści - 6 miesięcy."
}
````

````

**Uzasadnienie:** Daje użytkownikowi wskazówkę gdy ulotka nie zawiera informacji.

---

## Scenariusze Testowe

| Scenariusz | Oczekiwany wynik |
|------------|------------------|
| PDF z jasnym "Po otwarciu zużyć w ciągu 28 dni" | `{ status: "znaleziono", period: "28 dni" }` |
| PDF bez informacji o terminie po otwarciu | `{ status: "nie_znaleziono" }` |
| PDF z wieloma terminami (butelka vs saszetka) | Pierwszy/najbardziej ogólny |
| PDF uszkodzony / nieczytelny | `{ status: "nie_znaleziono" }` + error handling |
| Ulotka wyrobu medycznego | Prawdopodobnie `nie_znaleziono` (brak standardowej frazy) |

---

## Integracja z Modelem Medicine

Pole `shelfLifeAfterOpening` w modelu `Medicine` przechowuje wynik:

```dart
class Medicine {
  final String? shelfLifeAfterOpening;  // Cytat z ulotki
  final String? shelfLifeStatus;        // "pending" | "completed" | "error" | "manual"
  // ...
}
````

**Flow:**

1. Po dodaniu leku z `leafletUrl` → `shelfLifeStatus = "pending"`
2. Backend wywołuje `analyzeShelfLife(pdfUrl)`
3. Jeśli sukces → `shelfLifeAfterOpening = period`, `shelfLifeStatus = "completed"`
4. Jeśli błąd → `shelfLifeStatus = "error"`
5. Użytkownik może ręcznie ustawić → `shelfLifeStatus = "manual"`

---

## Podsumowanie

| Metryka                                | Wartość                                   |
| -------------------------------------- | ----------------------------------------- |
| **Skuteczność dla leków z ulotką PDF** | 🟢 Wysoka                                 |
| **Skuteczność dla wyrobów medycznych** | 🔴 Niska (nie dotyczy)                    |
| **Wiarygodność danych**                | 🟢 Wysoka (cytat z źródła)                |
| **Kompletność**                        | 🟡 Średnia (brak warunków przechowywania) |

> [!TIP] **Rekomendacja:** Ten prompt działa dobrze dla swojego wąskiego celu. Rozważ dodanie pola
> `storage` (warunki przechowywania) i `periodDays` (normalizacja do dni) dla lepszej integracji z
> aplikacją.

---

_Ostatnia aktualizacja: 2026-01-25_
