# 🎨 Neumorphism Style Guide

Dokumentacja systemu stylów neumorficznych używanych w aplikacji mobilnej (`apps/mobile`).
Zdefiniowane w: `lib/widgets/neumorphic/neu_decoration.dart`

---

## 1. Gotowe Widgety (High-Level)

Najprostszy sposób na użycie stylu. Widgety te automatycznie obsługują motyw (Light/Dark).

| Widget | Opis | Zastosowanie | Gdzie użyte w aplikacji (przykłady) |
|--------|------|--------------|--------------------------------------|
| **`NeuContainer`** | Podstawowy kontener | Karty, sekcje, tła | `BackupScreen` (sekcje), `ManageScreen` (kafelki) |
| **`NeuInsetContainer`** | Kontener z **prawdziwymi inner shadows** | Pola formularzy, sekcje wewnątrz flat parents | `SettingsScreen` (sekcje), `AddMedicineScreen` (sekcje) |
| **`NeuButton`** | Przycisk z tekstem | Główne akcje | `BackupScreen` (przyciski importu/eksportu) |
| **`NeuIconButton`** | Przycisk z ikoną | Toolbar, akcje, filtry. Tryby: `visible` (standard), `iconOnly` (bez tła) | `HomeScreen` (toolbar, filtry), Nawigacja |
| **`NeuSortMenu`** | Menu rozwijane | Sortowanie, wybory | `HomeScreen` (menu sortowania) |
| **`CollapsibleContainer`** | Rozwijany kontener | Ukryte szczegóły | `MedicineCard` (szczegóły dawkowania) |

---

## 2. Style Dekoracji (`NeuDecoration`)

Metody statyczne klasy `NeuDecoration`, używane w `Container(decoration: ...)` dla pełnej kontroli.

| Metoda | Wygląd | Kiedy używać? | Gdzie użyte w aplikacji |
|--------|--------|---------------|-------------------------|
| **`.flat()`** | Wypukły, miękki cień, radius 16px | Standardowe kontenery, karty | Karty ustawień, Ekrany zarządzania |
| **`.flatSmall()`** | Wypukły, mniejszy cień, radius 12px | Mniejsze elementy: tagi, chipy | Tagi w `MedicineDetailSheet`, małe przyciski |
| **`.pressed()`** | Wklęsły (debossed) - odwrócone cienie | Stan aktywny przycisku, włączone toggle | Wciśnięte przyciski menu |
| **`.pressedSmall()`** | Wklęsły, subtelniejszy (debossed) | Stan aktywny małych elementów, **aktywny NeuIconButton** | Wybrane filtry, aktywne tagi, toolbar buttons |
| **`.basin()`** | Płaskie tło (deprecated) | Use `NeuInsetContainer` for true inner shadows | - |
| **`.searchBar()`** | **Floating pill** z mocnymi cieniami "lewitacji" | Główny pasek wyszukiwania | `HomeScreen` (wyszukiwarka) |
| **`.searchBarFocused()`** | Wciśnięty pasek z **zielonym outline** | Fokus na polu wyszukiwania | `HomeScreen` (aktywna wyszukiwarka) |
| **`.convex()`** | Wypukły z gradientem | Elementy interaktywne "3D" | (Opcjonalne) Przyciski specjalne |
| **`.statusCard()`** | Wypukły + kolor statusu | Karty zależne od stanu | `MedicineCard` (status: OK, expiring, expired) |

> **Inner shadows**: Flutter `BoxShadow` nie obsługuje `inset`. Widget `NeuInsetContainer` używa **CustomPainter z gradient overlays** na wewnętrznych krawędziach.

---

## 3. Przyciski Akcji (Kolorowe)

Specjalne style dla przycisków o konkretnym znaczeniu semantycznym.

| Metoda | Kolor | Zastosowanie | Gdzie użyte w aplikacji |
|--------|-------|--------------|-------------------------|
| **`.primaryButton()`** | 🟢 Zielony (Primary) | Akcje pozytywne (Zapisz, Dodaj) | Formularz dodawania leku, Potwierdzenie edycji |
| **`.destructiveButton()`** | 🔴 Czerwony (Error) | Akcje destrukcyjne (Usuń) | Modal potwierdzenia usunięcia, Przycisk "Usuń" |

---

## 4. Przykłady Implementacji

### Standardowa karta (Flat)

```dart
Container(
  decoration: NeuDecoration.flat(
    isDark: isDark, 
    radius: 16
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text("To jest karta neumorficzna"),
  ),
)
```

### Pole tekstowe (Search Bar - Floating Pill)

```dart
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  height: 56,
  decoration: hasFocus 
    ? NeuDecoration.searchBarFocused(isDark: isDark) // Focus
    : NeuDecoration.searchBar(isDark: isDark),       // Idle
  child: Row(
    children: [
      Icon(LucideIcons.search),
      Expanded(child: TextField(...)),
      Icon(LucideIcons.arrowRight), // Submit
    ],
  ),
)
```

### Aktywny Tag (Toggle)

```dart
Container(
  decoration: isActive 
    ? NeuDecoration.pressedSmall(isDark: isDark) // Wciśnięty (Aktywny)
    : NeuDecoration.flatSmall(isDark: isDark),   // Wypukły (Nieaktywny)
  child: Text("Tag"),
)
```

---

## 5. Nawigacja (`FloatingNavBar`)

Custom bottom navigation bar z efektem "lewitowania".

| Właściwość | Wartość |
|------------|---------|
| **Layout** | `bottomNavigationBar` w `Scaffold` |
| **Efekt** | Floating (marginesy 16px, uniesiony nad krawędź) |
| **BorderRadius** | 24px |
| **Cienie** | Neumorficzne (ciemny dół + jasna góra) |
| **Animacje** | `AnimatedContainer` (250ms), `AnimatedScale` (200ms) |
| **Aktywny element** | Gradient convex, ikona powiększona do 32px, brak etykiety |
| **Fade-out** | Gradient 40px na dole listy (w `HomeScreen`) - elementy zanikają płynnie |

### Fade-out w ekranach

Aby elementy scrollujące się do dołu zanikały płynnie, lista jest owinięta w `Stack` z gradientem:

```dart
Stack(
  children: [
    ListView.builder(...), // lista
    Positioned(
      bottom: 0,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundColor.withAlpha(0), backgroundColor],
          ),
        ),
      ),
    ),
  ],
)
```
