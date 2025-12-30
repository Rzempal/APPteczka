# Lessons Learned

Dokument zawiera wnioski z popełnionych błędów, aby nie powtarzać ich w przyszłości.

---

## 1. Efekt wciśnięcia w neumorfizmie

**Data:** 2025-12-24  
**Kontekst:** Karty leków - przycisk chevron w stanie zwiniętym

### ❌ Błąd

Użyłem klasy `neu-concave` dla efektu "wciśnięcia" przycisku, co dało ciemny, wklęsły wygląd - nieprawidłowy w kontekście UI.

### ✅ Poprawne rozwiązanie

Dla interaktywnych elementów (hamburger menu, tagi, przyciski toggle) używaj:

```css
neu-tag active
```

### Różnica

| Klasa           | Wygląd                        | Zastosowanie                   |
|-----------------|-------------------------------|--------------------------------|
| `neu-concave`   | Ciemny, wklęsły (jak input)   | Pola tekstowe, obszary wgłębione |
| `neu-tag.active`| Zielony akcent, wciśnięty     | Aktywne przyciski, toggle, tagi  |

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

Przyciski z `box-shadow` neumorficznym (`.neu-tag`) umieszczone przy prawej krawędzi kontenera mają obcięty cień, gdy kontener ma `overflow: hidden` lub brak odpowiedniego paddingu.

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

Elementy z cieniami zewnętrznymi (box-shadow) wymagają odpowiedniego paddingu w kontenerze nadrzędnym, aby cień nie był obcinany.

---

## 3. Przyciski wychodzące poza kontener (brak flex-wrap)

**Data:** 2025-12-26  
**Kontekst:** Kontener "Twoja apteczka" - przyciski Lista, PDF, Wyczyść

### ❌ Błąd

Przyciski umieszczone w kontenerze `flex` bez `flex-wrap` są ucinane gdy nie mieszczą się w jednej linii.

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

Kontenery z wieloma przyciskami lub elementami inline powinny używać `flex-wrap` aby elementy zawijały się do nowej linii zamiast być ucinane.

---

## 4. Border psuje efekt neumorficzny (Flutter mobile)

**Data:** 2025-12-29  
**Kontekst:** Karty leków i pole wyszukiwania w aplikacji mobilnej

### ❌ Błąd

Użyłem `Border.all()` w dekoracjach neumorficznych (`basin`, `statusCard`), co dodawało widoczne obramowanie i łamało iluzję 3D.

### ✅ Poprawne rozwiązanie

W neumorphism elementy "wyłaniają się" z tła dzięki cieniom, nie obramowaniom. Usuń border i wzmocnij cienie:

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

Używanie losowych wartości spacing (4, 6, 10, 12...) i border-radius (4, 8, 10, 12, 16, 20) - chaos wizualny.

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

Rytm spacingu i spójne radiusy są fundamentem jakości UI. Ich złamanie natychmiast obniża poziom wizualny projektu.

---

## 6. Symulacja inset shadow w Flutter (basin effect)

**Data:** 2025-12-30  
**Kontekst:** Pole wyszukiwania - efekt wklęsłości (basin) w neumorfizmie

### ❌ Błąd

Użyto tylko gradientu w `NeuDecoration.basin()`, co nie dawało prawdziwego efektu wklęsłości - Flutter `BoxDecoration` nie wspiera `inset box-shadow`.

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

W Flutter efekty niedostępne natywnie (jak inset shadow) można symulować przez Stack z warstwami gradientów. Widget własny > pakiet zewnętrzny gdy:

- Potrzebujesz integracji z istniejącym design system
- Chcesz pełną kontrolę nad stylami
- Zależność zewnętrzna nie jest niezbędna

---

> 📅 **Ostatnia aktualizacja:** 2025-12-30
