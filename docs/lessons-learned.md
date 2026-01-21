<!-- markdownlint-disable MD024 -->

# 🧠 Lessons Learned

> **Powiązane:** [Architektura](architecture.md) | [Konwencje](standards/conventions.md)

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
	box-shadow:
		inset 2px 2px 4px rgba(0, 0, 0, 0.1),
		inset -2px -2px 4px rgba(255, 255, 255, 0.1);
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
2. **Brakujący nawias** - szczególnie przy ternary `? :` wewnątrz `child:`

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

## 14. Idempotentnosc skryptow z GitHub CLI (gh)

**Data:** 2026-01-17  
**Kontekst:** Skrypt `merge_pr.ps1` do automatyzacji PR i merge.

### ❌ Blad

Zakładanie, że PR nigdy nie istnieje w momencie uruchomienia skryptu. `gh pr create` wyrzuca błąd,
jeśli PR dla danego brancha już jest na GitHubie, co przerywało cały proces automatyzacji.

### ✅ Poprawne rozwiazanie

Zaimplementuj sprawdzenie przed akcją. Jeśli PR istnieje, zaktualizuj go zamiast tworzyć nowy:

1. Sprawdź numer istniejącego PR: `gh pr list --head $branch --json number`
2. Jeśli istnieje: `gh pr edit $number --title "$newTitle"`
3. Jeśli nie istnieje: `gh pr create --title "$newTitle" ...`

### Zasada ogolna

Skrypty CI/CD i automatyzacji powinny być **idempotentne** – wielokrotne uruchomienie tego samego
skryptu w tym samym stanie powinno prowadzić do tego samego (poprawnego) wyniku, a nie do błędów
spowodowanych "już istniejącymi" zasobami.

---

## 15. Nie zgaduj rozwiązania - testuj i weryfikuj (Flutter UI)

**Data:** 2026-01-17 **Kontekst:** Standaryzacja UI pól tekstowych - TextField nie dopasowuje się do
pills shape

### ❌ Błąd

Zgadywanie rozwiązań zamiast weryfikacji przez testy lub dokumentację. W przypadku TextField nie
dopasowującego się do `borderRadius: 50` (pills shape):

1. **Pierwsza próba:** Dodanie `clipBehavior: Clip.antiAlias` do `AnimatedContainer` - nie
   zadziałało
2. **Druga próba:** Dodanie `filled: false` do `InputDecoration` - niepewne, czeka na test

```dart
// ❌ Błędnie - zgadywanie bez weryfikacji
AnimatedContainer(
  clipBehavior: Clip.antiAlias,  // zgadywanie #1
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(50),
  ),
  child: TextField(
    decoration: InputDecoration(
      filled: false,  // zgadywanie #2
    ),
  ),
);
```

### ✅ Poprawne rozwiązanie

**Opcja 1:** Sprawdzić dokumentację Flutter dla `TextField` + `borderRadius` **Opcja 2:**
Przetestować lokalnie w izolowanym przykładzie **Opcja 3:** Użyć dedykowanego widgetu `ClipRRect`
(udokumentowane rozwiązanie):

```dart
// ✅ Poprawnie - ClipRRect jest dedykowany do clippingu
AnimatedContainer(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(50),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(50),
    child: TextField(...),
  ),
);
```

### Zasada ogólna

Przy problemach UI w Flutter:

1. **NIE zgaduj** - sprawdź dokumentację lub przetestuj lokalnie
2. **Iteruj z feedbackiem użytkownika** - deploy → test → poprawka → repeat
3. **Używaj dedykowanych widgetów** - `ClipRRect` do clippingu, nie `clipBehavior` w rodzicu
4. **Pytaj użytkownika o feedback** - screenshot pokazuje prawdę, zgadywanie prowadzi w ślepą
   uliczkę

### Dodatkowy problem: Utrata zmian podczas merge conflict

W tej samej sesji: podczas merge `b2c7dac` zmiany w `home_screen.dart` zostały utracone (wzięto
starą wersję pliku). Lekcja:

- **Zawsze weryfikuj** co zostało zmergowane: `git diff main..branch -- path/to/file`
- **Sprawdzaj po merge** czy wszystkie pliki zawierają oczekiwane zmiany
- **Nie zakładaj** że merge conflict został rozwiązany poprawnie bez weryfikacji

---

---

## 16. Race condition przy async UI z modalami (aktualizacja)

**Data:** 2026-01-17 **Kontekst:** Szybkie zamknięcie panelu etykiet (gest swipe) powodowało utratę
zmian w UI.

### ❌ Błąd

Wywołanie odświeżenia listy `_loadMedicines()` następowało natychmiast po zamknięciu panelu
(`.then()`), podczas gdy operacja zapisu `updateMedicineLabels` wciąż trwała w tle.

```dart
// ❌ Błędnie - race condition
onChanged: (ids) {
  storage.update(ids); // fire & forget
},
// ...
.then((_) => _loadMedicines()); // uruchamia się natychmiast po zamknięciu
```

### ✅ Poprawne rozwiązanie

Śledzenie `Future` operacji zapisu i oczekiwanie na jego zakończenie przed odświeżeniem.

```dart
// ✅ Poprawnie - czekaj na zapis
Future<void>? pendingUpdate;

onChanged: (ids) {
  pendingUpdate = storage.update(ids); // śledź Future
},
// ...
.then((_) async {
  if (pendingUpdate != null) await pendingUpdate; // czekaj na zakończenie
  _loadMedicines();
});
```

### Zasada ogólna

Przy interakcjach "fire & forget" (np. toggle switch, checkbox w modalu), jeśli zamknięcie widoku
pociąga za sobą odświeżenie danych rodzica:

1. Zawsze zachowuj referencję do `Future` operacji zapisu.
2. W bloku sprzątającym (`dispose`, `then`, `pop`) upewnij się, że operacja się zakończyła.

---

---

## 17. Blokowanie zapytań API przez brak User-Agent (Dart http)

**Data:** 2026-01-17 **Kontekst:** Wyszukiwanie ulotek w Rejestrze Produktów Leczniczych przestało
działać (brak wyników).

### ❌ Błąd

Biblioteka `http` w Dart domyślnie wysyła nagłówek `User-Agent` jako `Dart/<version>`. Niektóre
serwery (np. eZdrowie) blokują takie zapytania (zwracając puste wyniki lub błędy), traktując je jako
boty, podczas gdy zapytania z `curl` lub przeglądarki działają.

### ✅ Poprawne rozwiązanie

Zawsze dodawaj nagłówek `User-Agent` udający przeglądarkę mobilną w zapytaniach do publicznych API:

```dart
final response = await http.get(
  endpoint,
  headers: {
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
  },
);
```

### Zasada ogólna

Jeśli API działa w przeglądarce i `curl`, a nie działa w aplikacji mobilnej:

1. Sprawdź nagłówki wysyłane przez aplikację.
2. Skopiuj nagłówki (szczególnie `User-Agent`, `Accept`, `Referer`) z działającego zapytania.

---

---

## 18. Brak odświeżania StatefulWidget przy zmianie danych (didUpdateWidget)

**Data:** 2026-01-17 **Kontekst:** Karta leku (`MedicineCard`) nie odświeżała widoku po zmianie
etykiet/notatki wykonanej w modalu, mimo że rodzic (Lista) przekazywał nowy obiekt.

### ❌ Błąd

Zbyt agresywna optymalizacja w `didUpdateWidget`. Aktualizacja lokalnego stanu następowała _tylko_
gdy zmieniło się ID leku.

```dart
@override
void didUpdateWidget(covariant MedicineCard oldWidget) {
  super.didUpdateWidget(oldWidget);
  // ❌ Błąd: Ignoruje zmiany zawartości (np. nowe etykiety), jeśli ID jest to samo
  if (oldWidget.medicine.id != widget.medicine.id) {
    _medicine = widget.medicine;
  }
}
```

### ✅ Poprawne rozwiązanie

Rozdzielenie logiki aktualizacji danych od resetowania stanu UI.

```dart
@override
void didUpdateWidget(covariant MedicineCard oldWidget) {
  super.didUpdateWidget(oldWidget);

  // ✅ 1. Zawsze aktualizuj dane, jeśli obiekt jest inny (nawet jeśli to to samo ID)
  if (oldWidget.medicine != widget.medicine) {
    _medicine = widget.medicine;
  }

  // ✅ 2. Resetuj stan UI (zwinięcie, tryb edycji) TYLKO gdy zmieniło się ID
  if (oldWidget.medicine.id != widget.medicine.id) {
    _isMoreExpanded = false;
  }
}
```

### Zasada ogólna

W `StatefulWidget`, który trzyma lokalną kopię danych z `widget`:

1. Zawsze implementuj `didUpdateWidget`.
2. Aktualizuj lokalne dane gdy `oldWidget.data != widget.data`.
3. Resetuj stan interfejsu (np. scroll, expanded) tylko gdy zmienia się tożsamość obiektu (ID).

---

> 📅 **Ostatnia aktualizacja:** 2026-01-20

---

---

## 19. TextField w Custom Widget nie działa z klawiaturą (onSubmitted)

**Data:** 2026-01-17 **Kontekst:** Wyszukiwanie w "Znajdź ulotkę" nie reagowało na przycisk "Szukaj"
na klawiaturze ekranowej.

### ❌ Błąd

Custom widget `NeuSearchField` (wrapper na `TextField`) nie przekazywał callbacku `onSubmitted` do
wewnętrznego `TextField`. Przez to akcja `TextInputAction.search` była wizualnie dostępna, ale
funkcjonalnie martwa.

### ✅ Poprawne rozwiązanie

Upewnij się, że każdy wrapper na pole tekstowe eksponuje i przekazuje `onSubmitted` (lub
`onFieldSubmitted` w `TextFormField`).

```dart
// Wewnątrz NeuTextField
TextField(
  // ...
  onSubmitted: widget.onSubmitted, // ✅ Wiring niezbędny dla klawiatury
  textInputAction: widget.textInputAction,
);
```

### Zasada ogólna

Tworząc własne komponenty UI (wrappery), zawsze weryfikuj działanie akcji klawiatury (Done, Search,
Next).

---

---

## 20. Zbyt precyzyjne zapytania do oficjalnych rejetrów (RPL)

**Data:** 2026-01-17 **Kontekst:** Wyszukiwanie "Apap Extra 500mg" w Rejestrze Produktów Leczniczych
nie zwracało wyników, mimo że lek istnieje.

### ❌ Błąd

Oficjalne API często mają restrykcyjne ("głupie") wyszukiwarki, które wymagają dokładnego
dopasowania frazy i gubią się przy dodatkowych słowach (np. dawce, postaci), jeśli nie są one w
idealnej kolejności.

### ✅ Poprawne rozwiązanie

Zastosowanie prostej sanityzacji zapytania po stronie klienta - w przypadku RPL najlepiej działa
wyszukiwanie po **pierwszym słowie** nazwy (Root Name).

```dart
String _sanitizeQuery(String raw) {
  // Dla "Apap Extra 500mg" zwróć "Apap"
  // To daje szersze wyniki, z których użytkownik może łatwo wybrać właściwy
  final parts = raw.split(' ');
  return parts.isNotEmpty ? parts.first.trim() : raw.trim();
}
```

### Zasada ogólna

Przy integracji z restrykcyjnymi API wyszukiwania, "mniej znaczy więcej". Lepiej pokazać 10 wyników
do wyboru niż 0 przez zbyt szczegółowe zapytanie.

---

## 21. Ryzyko edycji dużych klas przez `replace_file_content`

**Data:** 2026-01-17 **Kontekst:** Próba dodania pola `onSubmitted` do `NeuTextField` spowodowała
przypadkowe usunięcie wszystkich innych pól klasy, ponieważ narzędzie zastąpiło blok kodu zbyt
agresywnie/niedokładnie.

### ❌ Błąd

Używanie `replace_file_content` do modyfikacji początku klasy (pola + konstruktor) bez uwzględnienia
pełnego kontekstu istniejących pól.

### ✅ Poprawne rozwiązanie

Przy edycji klasy z wieloma polami:

1. Używaj małych, precyzyjnych chunków (np. dodaj linię po linii).
2. Jeśli musisz podmienić duży blok, **ZAWSZE** najpierw pobierz aktualną zawartość pliku i upewnij
   się, że w nowym contencie zawierasz wszystkie istniejące elementy.

### Zasada ogólna

Zawsze sprawdzaj `git diff` lub podgląd zmian przed zatwierdzeniem, szczególnie w plikach
"bibliotecznych" (współdzielone widgety).

---

## 22. Interpolacja AnimatedContainer między różnymi typami właściwości (Flutter)

**Data:** 2026-01-20 **Kontekst:** Floating bottom bar - artefakty wizualne podczas animacji
przełączania zakładek

### ❌ Błąd

AnimatedContainer interpolował między dwoma różnymi typami wypełnienia BoxDecoration:

- **Stan nieaktywny**: `color: backgroundColor` + `gradient: null`
- **Stan aktywny**: `color: null` + `gradient: LinearGradient(...)`

To powodowało pojawienie się niepożądanego ciemnoszarego okręgu w trakcie animacji, gdy gradient
zanikał/pojawiał się, a `color` był widoczny w międzyczasie.

```dart
// ❌ Błędnie - przełączanie między color a gradient
BoxDecoration(
  color: isSelected ? null : backgroundColor,  // Przełączanie typu
  gradient: isSelected ? LinearGradient(...) : null,  // Drugi typ
)
```

### ✅ Poprawne rozwiązanie

Używanie **tylko gradient** dla obu stanów. Dla nieaktywnego stanu gradient ma jednolity kolor (ten
sam na początku i końcu).

```dart
// ✅ Poprawnie - ten sam typ właściwości dla obu stanów
BoxDecoration(
  // Bez color!
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isSelected
        ? [AppColors.darkSurfaceLight, AppColors.darkSurface]  // Gradient neumorficzny
        : [backgroundColor, backgroundColor],  // Jednolity kolor jako gradient
  ),
)
```

### Zasada ogólna

Przy animacjach w Flutter (AnimatedContainer, AnimatedOpacity, itp.):

1. **Interpoluj ten sam typ właściwości** - Flutter lepiej radzi sobie z interpolacją między dwoma
   gradientami niż między color a gradient
2. **Jednolity kolor jako gradient** - `[color, color]` daje ten sam efekt wizualny co `color`, ale
   pozwala na płynną interpolację
3. **Unikaj przełączania między null a wartością** - zamiast `value: condition ? x : null` użyj
   `value: x dla obu stanów`

---

## 23. Inicjalizacja DropdownButtonFormField

**Data:** 2026-01-17 **Kontekst:** Naprawa selektora roku w `MonthYearPickerDialog`.

### ❌ Błąd

Użycie `value` zamiast `initialValue` w `DropdownButtonFormField` wewnątrz `StatefulWidget`.
Powodowało to problemy z odświeżaniem widoku przy zmianie wartości przez użytkownika (widget
"walczył" ze stanem nadrzędnym lub nie reagował poprawnie).

### ✅ Poprawne rozwiązanie

Użyj `initialValue` dla wartości początkowej, jeśli `DropdownButtonFormField` ma zarządzać swoim
stanem wewnętrznie (przynajmniej wizualnie), lub upewnij się, że `value` jest ściśle powiązane z
`setState` w rodzicu. W tym przypadku `initialValue` uprościło kod.

```dart
DropdownButtonFormField<int>(
  initialValue: _selectedYear, // ✅ Ustaw raz na starcie
  // value: _selectedYear,     // ❌ Wymaga idealnego syncu ze stanem
  onChanged: (value) {
    setState(() => _selectedYear = value!);
  },
)
```

### Zasada ogólna

W formularzach Fluttera, rozróżniaj pola kontrolowane (`controller` / `value`) od niekontrolowanych
(`initialValue`). Mieszenie tych podejść to proszenie się o błędy UI.

---

## 22. Interpolacja AnimatedContainer między różnymi typami właściwości (Flutter)

**Data:** 2026-01-20 **Kontekst:** Floating bottom bar - artefakty wizualne podczas animacji
przełączania zakładek

### ❌ Błąd

AnimatedContainer interpolował między dwoma różnymi typami wypełnienia BoxDecoration:

- **Stan nieaktywny**: `color: backgroundColor` + `gradient: null`
- **Stan aktywny**: `color: null` + `gradient: LinearGradient(...)`

To powodowało pojawienie się niepożądanego ciemnoszarego okręgu w trakcie animacji, gdy gradient
zanikał/pojawiał się, a `color` był widoczny w międzyczasie.

```dart
// ❌ Błędnie - przełączanie między color a gradient
BoxDecoration(
  color: isSelected ? null : backgroundColor,  // Przełączanie typu
  gradient: isSelected ? LinearGradient(...) : null,  // Drugi typ
)
```

### ✅ Poprawne rozwiązanie

Używanie **tylko gradient** dla obu stanów. Dla nieaktywnego stanu gradient ma jednolity kolor (ten
sam na początku i końcu).

```dart
// ✅ Poprawnie - ten sam typ właściwości dla obu stanów
BoxDecoration(
  // Bez color!
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isSelected
        ? [AppColors.darkSurfaceLight, AppColors.darkSurface]  // Gradient neumorficzny
        : [backgroundColor, backgroundColor],  // Jednolity kolor jako gradient
  ),
)
```

### Zasada ogólna

Przy animacjach w Flutter (AnimatedContainer, AnimatedOpacity, itp.):

1. **Interpoluj ten sam typ właściwości** - Flutter lepiej radzi sobie z interpolacją między dwoma
   gradientami niż między color a gradient
2. **Jednolity kolor jako gradient** - `[color, color]` daje ten sam efekt wizualny co `color`, ale
   pozwala na płynną interpolację
3. **Unikaj przełączania między null a wartością** - zamiast `value: condition ? x : null` użyj
   `value: x dla obu stanów`

---

## 19. Flutter build APK exit code 1 mimo sukcesu (Windows)

**Data:** 2026-01-21  
**Kontekst:** Automatyzacja budowania APK. `flutter build apk` zwraca kod błędu 1, mimo komunikatu o
sukcesie.

### ❌ Błąd

Poleganie wyłącznie na `Exit Code` w skryptach CI/CD.

```powershell
flutter build apk
if ($LASTEXITCODE -ne 0) { throw "Build failed" } # ❌ Rzuca błąd mimo, że APK powstało
```

Gradle na Windows czasem zwraca błąd 1 (np. przez warningi lub problemy ze ścieżkami), nawet gdy
plik wynikowy został poprawnie wygenerowany.

### ✅ Poprawne rozwiązanie

Weryfikuj fizyczne istnienie pliku wynikowego i jego czas modyfikacji.

```powershell
flutter build apk
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"

if (Test-Path $apkPath) {
    $apkTime = (Get-Item $apkPath).LastWriteTime
    if ($apkTime -gt $startTime) {
        Write-Host "Build success!"
    }
}
```

### Zasada ogólna

W automatyzacji buildów mobilnych „success condition” to obecność artefaktu (APK/IPA), a nie tylko
kod wyjścia procesu buildera.

---

## 24. InkWell splash artifacts w kontenerach neumorficznych (Flutter)

**Data:** 2026-01-21 **Kontekst:** Sekcje rozwijalne w ekranie "Dodaj leki" - szary prostokąt w
narożnikach podczas kliknięcia

### ❌ Błąd

`InkWell` wewnątrz `Container` z neumorficzną dekoracją i `clipBehavior: Clip.antiAlias` powoduje
pojawienie się szarego prostokątnego artefaktu w narożnikach podczas kliknięcia. Flutter domyślnie
rysuje splash/highlight effect jako prostokąt, który przez krótką chwilę jest widoczny zanim
clipping zadziała.

```dart
// ❌ Błędnie - szary artefakt podczas kliknięcia
Container(
  decoration: NeuDecoration.flat(isDark: isDark, borderRadius: organicRadius),
  clipBehavior: Clip.antiAlias,
  child: Column(
    children: [
      InkWell(  // Splash effect jest prostokątny!
        onTap: onToggle,
        child: Padding(...),
      ),
    ],
  ),
)
```

### ✅ Poprawne rozwiązanie

Wyłącz splash i highlight effect w `InkWell` gdy jest używany w kontenerach neumorficznych:

```dart
// ✅ Poprawnie - brak artefaktów
InkWell(
  onTap: onToggle,
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  child: Padding(...),
)
```

### Alternatywne rozwiązania

1. **Material wrapper** z `borderRadius` - zachowuje efekt splash ograniczony do zaokrąglonych rogów
2. **GestureDetector** zamiast `InkWell` - brak efektu splash, ale zachowana funkcjonalność

### Zasada ogólna

Przy używaniu `InkWell` w kontenerach z niestandardowym `borderRadius` (szczególnie
organic/asymmetric):

- Splash effect jest domyślnie prostokątny i może wyciekać poza zaokrąglone rogi
- Dla kontenerów neumorficznych najprościej jest wyłączyć splash/highlight
- Alternatywnie użyj `Material` wrapper z odpowiednim `borderRadius`

---

## 25. Dart enum z LucideIcons wymaga wzorca getter (Flutter)

**Data:** 2026-01-21 **Kontekst:** FiltersSheet redesign - FilterTab enum z ikonami

### ❌ Błąd

Próba użycia `LucideIcons.xyz` jako pola `final` w enum powoduje błąd kompilacji: "Arguments of a
constant creation must be constant expressions". LucideIcons nie są `const`.

```dart
// ❌ Błędnie - LucideIcons nie są const
enum FilterTab {
  labels(LucideIcons.tag, 'Etykiety'),  // ERROR!
  expiry(LucideIcons.calendarClock, 'Termin');

  final IconData icon;
  final String label;
  const FilterTab(this.icon, this.label);
}
```

### ✅ Poprawne rozwiązanie

Użyj getterów zamiast pól `final`:

```dart
// ✅ Poprawnie - gettery dla non-const wartości
enum FilterTab {
  labels,
  expiry,
  symptoms;

  IconData get icon {
    switch (this) {
      case FilterTab.labels:
        return LucideIcons.tag;
      case FilterTab.expiry:
        return LucideIcons.calendarClock;
      case FilterTab.symptoms:
        return LucideIcons.activity;
    }
  }

  String get label {
    switch (this) {
      case FilterTab.labels:
        return 'Etykiety';
      // ...
    }
  }
}
```

### Zasada ogólna

W Dart enum z non-const wartościami (ikony z zewnętrznych pakietów, runtime-generated values):

- Użyj **getterów** zamiast pól `final`
- Gettery są ewaluowane w runtime, więc mogą zwracać non-const wartości
- Pola `final` w enum muszą być const-constructible

---

## 29. Synchronizacja tokenów kolorystycznych (design.md ↔ app_theme.dart)

**Data:** 2026-01-21  
**Kontekst:** Audyt palety kolorystycznej Light/Dark Mode

### ❌ Błąd

Dokumentacja designu (`design.md`) zawierała szczegółową paletę CSS tokens (np. `--card-bg`,
`--border`, `--chip-inactive`), podczas gdy implementacja (`app_theme.dart`) miała:

- Brakujące tokeny (np. `cardBg`, `border`)
- Rozbieżne wartości hex (np. `lightTextMuted` był szary zamiast szaro-zielonego)
- Niespójne nazewnictwo kolorów statusów (legacy vs themed)

### ✅ Poprawne rozwiązanie

Przeprowadź audyt porównawczy i zaktualizuj implementację:

```dart
// Dodane tokeny
static const lightCardBg = Color(0xFFFFFFFF);
static const darkCardBg = Color(0xFF1F1F35);
static const lightBorder = Color(0x263E514B); // rgba(62,81,75,0.15)
static const darkBorder = Color(0x3300FF9D);  // rgba(0,255,157,0.2)
static const darkChipInactive = Color(0xFF262642);

// Zaktualizowane kolory statusów (themed)
static const expiredLight = Color(0xFFE26D5C);    // ciepły koral
static const expiredDark = Color(0xFFFF7070);     // neonowy czerwony
static const expiringSoonLight = Color(0xFFDCA546); // miodowy
static const expiringSoonDark = Color(0xFFFFBD2E);  // neonowy żółty
```

### Zasada ogólna

Przy aktualizacji dokumentacji designu:

1. **Audyt 1:1** - każdy token CSS musi mieć odpowiednik w `app_theme.dart`
2. **Konwersja formatu** - CSS `rgba(r,g,b,a)` → Dart `Color(0xAARRGGBB)`
3. **Themed variants** - Light/Dark Mode wymagają osobnych stałych
4. **Backward compatibility** - zachowaj legacy tokeny z komentarzem `@deprecated`

---

> 📅 **Ostatnia aktualizacja:** 2026-01-21
