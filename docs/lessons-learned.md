# 🧠 Lessons Learned

> **Powiązane:** [Architektura](architecture.md) | [Konwencje](conventions.md)

---

## 1. Efekt wciśnięcia w neumorfizmie

**Data:** 2025-12-24  
**Kontekst:** Karty leków - przycisk chevron w stanie zwiniętym

### ❌ Błąd

Użyłem klasy `neu-concave` dla efektu "wciśnięcia" przycisku, co dało ciemny, wklęsły wygląd -
nieprawidłowy w kontekście UI.

### ✅ Poprawne rozwiązanie

Dla interaktywnych elementów (hamburger menu, tagi, przyciski toggle) używaj:

```css
neu-tag active
```

### Różnica

| Klasa            | Wygląd                      | Zastosowanie                     |
| ---------------- | --------------------------- | -------------------------------- |
| `neu-concave`    | Ciemny, wklęsły (jak input) | Pola tekstowe, obszary wgłębione |
| `neu-tag.active` | Zielony akcent, wciśnięty   | Aktywne przyciski, toggle, tagi  |

### Lokalizacja w CSS

`globals.css` linie 277-283:

```css
.neu-tag.active {
	background: linear-gradient(145deg, var(--color-accent-light), var(--color-accent));
	color: white;
	box-shadow: inset 2px 2px 4px rgba(0, 0, 0, 0.1), inset -2px -2px 4px rgba(255, 255, 255, 0.1);
}
```

---

## 2. Ucinanie cieni neumorficznych przez brak paddingu

**Data:** 2025-12-24  
**Kontekst:** Karty leków - przyciski przy prawej krawędzi kontenera

### ❌ Błąd

Przyciski z `box-shadow` neumorficznym (`.neu-tag`) umieszczone przy prawej krawędzi kontenera mają
obcięty cień, gdy kontener ma `overflow: hidden` lub brak odpowiedniego paddingu.

### ✅ Poprawne rozwiązanie

Dodaj prawy padding do kontenerów z elementami neumorficznymi:

```css
pr-1  /* Tailwind: 0.25rem / 4px */
```

### Przykład

```jsx
/* ❌ Błędnie - cień ucięty */
<div className="flex justify-between">
    <button className="neu-tag">Edytuj</button>
</div>

/* ✅ Poprawnie - cień widoczny */
<div className="flex justify-between pr-1">
    <button className="neu-tag">Edytuj</button>
</div>
```

### Zasada ogólna

Elementy z cieniami zewnętrznymi (box-shadow) wymagają odpowiedniego paddingu w kontenerze
nadrzędnym, aby cień nie był obcinany.

---

## 3. Przyciski wychodzące poza kontener (brak flex-wrap)

**Data:** 2025-12-26  
**Kontekst:** Kontener "Twoja apteczka" - przyciski Lista, PDF, Wyczyść

### ❌ Błąd

Przyciski umieszczone w kontenerze `flex` bez `flex-wrap` są ucinane gdy nie mieszczą się w jednej
linii.

### ✅ Poprawne rozwiązanie

Zawsze dodawaj `flex-wrap` do kontenerów z przyciskami:

```jsx
/* ❌ Błędnie - przyciski ucięte */
<div className="flex gap-2">
    <button>Lista</button>
    <button>PDF</button>
    <button>Wyczyść</button>
</div>

/* ✅ Poprawnie - przyciski zawijają się */
<div className="flex flex-wrap gap-2">
    <button>Lista</button>
    <button>PDF</button>
    <button>Wyczyść</button>
</div>
```

### Zasada ogólna

Kontenery z wieloma przyciskami lub elementami inline powinny używać `flex-wrap` aby elementy
zawijały się do nowej linii zamiast być ucinane.

---

## 4. Border psuje efekt neumorficzny (Flutter mobile)

**Data:** 2025-12-29  
**Kontekst:** Karty leków i pole wyszukiwania w aplikacji mobilnej

### ❌ Błąd

Użyłem `Border.all()` w dekoracjach neumorficznych (`basin`, `statusCard`), co dodawało widoczne
obramowanie i łamało iluzję 3D.

### ✅ Poprawne rozwiązanie

W neumorphism elementy "wyłaniają się" z tła dzięki cieniom, nie obramowaniom. Usuń border i
wzmocnij cienie:

```dart
// ❌ Błędnie
BoxDecoration(
  gradient: gradient,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: borderColor.withOpacity(0.2), width: 1), // psuje efekt
  boxShadow: [...],
);

// ✅ Poprawnie - tylko cienie
BoxDecoration(
  gradient: gradient,
  borderRadius: BorderRadius.circular(16),
  // bez border!
  boxShadow: [
    BoxShadow(color: shadowDark, offset: Offset(4, 4), blurRadius: 12),
    BoxShadow(color: shadowLight, offset: Offset(-2, -2), blurRadius: 6),
  ],
);
```

### Zasada ogólna

W neumorphism nigdy nie używaj `border` - efekt 3D uzyskujesz przez:

- **Zewnętrzne cienie** (dark shadow dół-prawo, light shadow góra-lewo) dla elementów "wypukłych"
- **Gradient** (ciemny góra-lewo → jasny dół-prawo) dla elementów "wklęsłych" (pola tekstowe)

---

## 5. Unifikacja design system (Flutter mobile)

**Data:** 2025-12-29  
**Kontekst:** Niespójne spacing i border-radius w aplikacji mobilnej

### ❌ Błąd

Używanie losowych wartości spacing (4, 6, 10, 12...) i border-radius (4, 8, 10, 12, 16, 20) - chaos
wizualny.

### ✅ Poprawne rozwiązanie

Ustal i trzymaj się rytmu:

- **Spacing:** skala 8px → `8, 16, 24, 32`
- **Border-radius:** tylko 2 wartości → `12` (small), `20` (large)

```dart
// ❌ Błędnie - losowe wartości
spacing: 6,
runSpacing: 4,
borderRadius: BorderRadius.circular(4),

// ✅ Poprawnie - rytm 8px, radius 12/20
spacing: 8,
runSpacing: 8,
borderRadius: BorderRadius.circular(12),
```

### Zasada ogólna

Rytm spacingu i spójne radiusy są fundamentem jakości UI. Ich złamanie natychmiast obniża poziom
wizualny projektu.

---

## 6. Symulacja inset shadow w Flutter (basin effect)

**Data:** 2025-12-30  
**Kontekst:** Pole wyszukiwania - efekt wklęsłości (basin) w neumorfizmie

### ❌ Błąd

Użyto tylko gradientu w `NeuDecoration.basin()`, co nie dawało prawdziwego efektu wklęsłości -
Flutter `BoxDecoration` nie wspiera `inset box-shadow`.

### ✅ Poprawne rozwiązanie

Stworzono dedykowany widget `NeuBasinContainer` który symuluje inset shadow za pomocą warstw:

```dart
// Struktura warstw (Stack):
// 1. Kontener bazowy z gradientem (ciemny góra-lewo → jasny dół-prawo)
// 2. Overlay gradient (góra-lewo do centrum) - symulacja cienia
// 3. Overlay gradient (dół-prawo do centrum) - symulacja odbicia
// 4. Górna/lewa krawędź z ciemnym gradientem (2px)
// 5. Dolna krawędź z jasnym gradientem (1px highlight)
```

### Kod

```dart
// ❌ Błędnie - tylko gradient, brak efektu 3D
Container(
  decoration: NeuDecoration.basin(isDark: isDark),
  child: TextField(...),
);

// ✅ Poprawnie - prawdziwy efekt wklęsłości
NeuBasinContainer(
  borderRadius: 12,
  child: TextField(...),
);
```

### Dlaczego nie pakiet zewnętrzny?

Rozważono `flutter_inset_box_shadow`, ale odrzucono z powodów:

- Dodatkowa zależność (YAGNI, KISS)
- Brak kontroli nad kolorami (niespójność z `AppColors`)
- Ryzyko porzucenia pakietu ("unverified uploader")

### Zasada ogólna

W Flutter efekty niedostępne natywnie (jak inset shadow) można symulować przez Stack z warstwami
gradientów. Widget własny > pakiet zewnętrzny gdy:

- Potrzebujesz integracji z istniejącym design system
- Chcesz pełną kontrolę nad stylami
- Zależność zewnętrzna nie jest niezbędna

---

## 7. Parsowanie odpowiedzi AI z markdown code blocks

**Data:** 2026-01-02  
**Kontekst:** Gemini API zwraca JSON opakowany w markdown ` ```json ... ``` `

### ❌ Błąd

Pojedynczy regex zakładający konkretny format odpowiedzi AI:

````typescript
const jsonMatch = text.match(/```json\s*([\s\S]*?)\s*```/) || text.match(/\{[\s\S]*\}/);
const jsonString = jsonMatch ? jsonMatch[1] || jsonMatch[0] : text;
````

Zawiódł gdy Gemini zwrócił wieloliniowy JSON z niestandardowym formatowaniem.

### ✅ Poprawne rozwiązanie

Kaskadowe próbowanie różnych wzorców, od najbardziej specyficznego do ogólnego:

````typescript
let jsonString = text.trim();

// Wzorzec 1: ```json ... ```
const jsonCodeBlockMatch = jsonString.match(/```json\s*([\s\S]*?)\s*```/);
if (jsonCodeBlockMatch && jsonCodeBlockMatch[1]) {
	jsonString = jsonCodeBlockMatch[1].trim();
} else {
	// Wzorzec 2: ``` ... ``` (bez języka)
	const codeBlockMatch = jsonString.match(/```\s*([\s\S]*?)\s*```/);
	if (codeBlockMatch && codeBlockMatch[1]) {
		jsonString = codeBlockMatch[1].trim();
	} else {
		// Wzorzec 3: surowy JSON { ... }
		const jsonObjectMatch = jsonString.match(/\{[\s\S]*\}/);
		if (jsonObjectMatch) {
			jsonString = jsonObjectMatch[0].trim();
		}
	}
}
````

### Zasada ogólna

Odpowiedzi AI są nieprzewidywalne. Przy parsowaniu:

- Zawsze używaj `.trim()` przed i po ekstrakcji
- Loguj surową odpowiedź dla debugowania
- Implementuj fallbacki dla różnych formatów
- Nigdy nie zakładaj konkretnego formatowania markdown

---

## 8. Wąskie pole dotykowe w przełącznikach (Flutter mobile)

**Data:** 2026-01-08  
**Kontekst:** Przełącznik motywu w NeuInsetContainer + convex

### ❌ Błąd

GestureDetector owijał tylko `AnimatedContainer` z padding vertical, a nie cały `Expanded` obszar.
Kliknięcie poza ikoną/tekstem nie działało.

```dart
// ❌ Błędnie - wąskie pole dotykowe
Expanded(
  child: GestureDetector(
    onTap: () => ...,
    child: AnimatedContainer(
      padding: EdgeInsets.symmetric(vertical: 12),
      // ...
    ),
  ),
)
```

### ✅ Poprawne rozwiązanie

Dodanie `behavior: HitTestBehavior.opaque` oraz swipe gesture na całym Row:

```dart
// ✅ Poprawnie - całe Expanded jest dotykalne + swipe
NeuInsetContainer(
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onHorizontalDragEnd: (details) {
      // Swipe left/right przełącza opcje
    },
    child: Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, // Całe pole!
            onTap: () => switchOption(0),
            child: AnimatedContainer(...),
          ),
        ),
      ],
    ),
  ),
)
```

### Zasada ogólna

Przy tworzeniu przycisków w kontenerach neumorficznych:

- Zawsze używaj `behavior: HitTestBehavior.opaque`
- Dodawaj swipe gesture dla naturalizmus interakcji
- Używaj `HapticFeedback.lightImpact()` przy każdej zmianie

---

---

## 9. Race condition przy async UI z modalami (Flutter)

**Data:** 2026-01-12 **Kontekst:** Wybór opakowania leku z modala bottom sheet czyścił pole tekstowe
autocomplete

### ❌ Błąd

Flaga `_isSelecting` w autocomplete trwała tylko 100ms, podczas gdy async operacja (fetch API +
wybór przez użytkownika w modalu) trwała znacznie dłużej. Po zamknięciu modala, callback
`onTextChanged` był wywoływany gdy flaga już była `false`.

```dart
// ❌ Błędnie - timeout 100ms za krótki
void _selectResult(RplSearchResult result) {
  _isSelecting = true;
  widget.onSelected?.call(result); // async operacja trwa dłużej!
  Future.delayed(const Duration(milliseconds: 100), () {
    _isSelecting = false; // ← Za wcześnie!
  });
}
```

### ✅ Poprawne rozwiązanie

1. **Główna ochrona:** Flaga w parent widget kontrolowana przez cykl życia async operacji
   (try/finally)
2. **Backup protection:** Dłuższy timeout (2000ms) w child widget
3. **Zapobieganie przeciekaniu zdarzeń:** `Future.microtask` przed `Navigator.pop`

```dart
// ✅ Poprawnie - flaga kontrolowana przez async lifecycle
Future<void> _onRplMedicineSelected(RplSearchResult result) async {
  setState(() => _isProcessingRplSelection = true);

  try {
    final details = await fetchDetails();
    final selection = await showModal();
    // ...przetwarzanie
  } finally {
    if (mounted) {
      setState(() => _isProcessingRplSelection = false);
    }
  }
}

// W callback:
onTextChanged: (text) {
  if (_isProcessingRplSelection) return; // Ignoruj podczas async
  // ...normalna logika
}
```

### Zasada ogólna

Przy async UI flows z modalami:

1. **Nigdy nie używaj stałego timeout** dla flag synchronizacji - czas operacji jest
   nieprzewidywalny
2. **Kontroluj flagi przez async lifecycle** - ustaw na początku, resetuj w `finally`
3. **Dodaj logging** do kluczowych punktów flow dla łatwiejszego debugowania
4. **Użyj `Future.microtask`** przed `Navigator.pop` aby zapobiec przeciekaniu zdarzeń tap

---

## 10. Utrata kontekstu przez warstwowe wywołania API

**Data:** 2026-01-13  
**Kontekst:** Ręczne dodawanie leku - "Nieznany lek" zamiast wybranej nazwy

### ❌ Błąd

Wyszukiwanie zwracało poprawną nazwę leku (`RplSearchResult.nazwa`), ale przy pobieraniu szczegółów
(`fetchDetailsById`) API `/details/{id}` zwracało dane bez pola nazwy. Nazwa była tracona między
warstwami.

```dart
// ❌ Błędnie - nazwa z wyszukiwania jest tracona
final details = await _rplService.fetchDetailsById(result.id);
// details.name == '' gdy API nie zwraca nazwy
```

### ✅ Poprawne rozwiązanie

Przekazuj znane dane jako fallback przez warstwy API:

```dart
// ✅ Poprawnie - zachowaj nazwę z wyszukiwania jako fallback
final details = await _rplService.fetchDetailsById(
  result.id,
  knownName: result.nazwa,  // fallback gdy API nie zwraca nazwy
);
```

### Zasada ogólna

Przy warstwowych wywołaniach API (search → details → packages):

1. **Przekazuj znany kontekst** - dane z poprzednich warstw mogą być niedostępne w kolejnych
2. **Dodaj parametry fallback** - `knownName`, `knownId` jako zabezpieczenie
3. **Używaj kaskadowych fallbacków** w parserach JSON:

   ```dart
   final name = json['primaryField'] ?? json['alternativeField'] ?? knownName ?? '';
   ```

---

## 11. Błędy nawiasów przy refaktoryzacji zagnieżdżonych widgetów (Flutter)

**Data:** 2026-01-15 **Kontekst:** Standaryzacja bottomSheet - refaktoryzacja wielu plików z
zagnieżdżonymi strukturami

### ❌ Błąd

Przy refaktoryzacji zagnieżdżonych widgetów (DraggableScrollableSheet → Column → Expanded → ternary
operator) łatwo o:

1. **Nadmiarowy nawias** - zostaje po usunięciu warstwy
2. **Brakujący nawias** - szczególnie przy ternary `? : ` wewnątrz `child:`

```dart
// ❌ Błędnie - nadmiarowy nawias
        ),
      ),  // ← NADMIAROWY - nie pasuje do żadnego otwarcia!
    ).whenComplete(() {

// ❌ Błędnie - brakujący nawias po ternary
Expanded(
  child: isEmpty
      ? Center(...)
      : ListView.builder(...),  // ← BRAK zamknięcia Expanded!
],
```

### ✅ Poprawne rozwiązanie

1. **Przed refaktoryzacją:** policz pary nawiasów w metodzie
2. **Po refaktoryzacji:** zweryfikuj że każde `(` ma odpowiadające `)`
3. **Ternary operators:** zawsze dodaj `)` dla parent widget po obu gałęziach

```dart
// ✅ Poprawnie - struktura nawiasów
Expanded(                           // OPEN Expanded
  child: isEmpty
      ? Center(...)                 // branch 1
      : ListView.builder(...),      // branch 2
),                                  // CLOSE Expanded ← NIE ZAPOMNIJ!
],                                  // closes children array
```

### Zasada ogólna

Przy refaktoryzacji zagnieżdżonych widgetów Flutter:

- **Ternary w `child:`** = parent widget musi być zamknięty PO obu gałęziach
- **Usuwanie warstwy** = usuń ZARÓWNO otwarcie `Widget(` JAK I zamknięcie `),`
- **IDE nie zawsze pomoże** - błędy składniowe mogą wskazywać na złą linię
- **Weryfikuj strukturę** przed commit - `flutter analyze` lub IDE

## 12. Błędy typów w callbackach generycznych (Flutter)

**Data:** 2026-01-16  
**Kontekst:** Naprawa `LabelSelector` w `medicine_card.dart`

### ❌ Błąd

Przekazanie callbacku o niezgodnym typie do generycznego widgetu (np. `onChanged` oczekujący
`String?` zamiast `String`). Powoduje to błąd kompilacji:
`The argument type 'void Function(String)' can't be assigned to the parameter type 'void Function(String?)?'.`

### ✅ Poprawne rozwiązanie

Upewnij się, że typy w callbacku dokładnie odpowiadają definicji w widgetcie:

```dart
// ❌ Błędnie
onChanged: (String value) => ... // Błąd jeśli widget oczekuje String?

// ✅ Poprawnie
onChanged: (String? value) {
  if (value == null) return;
  // ...
}
```

---

## 13. Usuwanie nieużywanego kodu animacji (performance)

**Data:** 2026-01-16  
**Kontekst:** Refaktoryzacja `MedicineCard`

### ❌ Błąd

Pozostawianie nieużywanych `AnimationController`, `CurvedAnimation` oraz pól stanu w widgetach
`StatefulWidget` po zmianie logiki UI. Powoduje to zbędne zużycie pamięci i zaciemnia kod.

### ✅ Poprawne rozwiązanie

1. Usuń pola `controller` i `animation` jeśli nie są już potrzebne.
2. Usuń `dispose()` jeśli zawiera tylko `controller.dispose()`.
3. Usuń `with SingleTickerProviderStateMixin` jeśli widget nie potrzebuje już tickera.
4. Przekształć w `StatelessWidget` jeśli to możliwe (największy zysk na prostocie).

---

---

> 📅 **Ostatnia aktualizacja:** 2026-01-16
