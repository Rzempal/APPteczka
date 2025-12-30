# 🎨 Neumorphism Style Guide

Dokumentacja systemu stylów neumorficznych używanych w aplikacji mobilnej (`apps/mobile`).
Zdefiniowane w: `lib/widgets/neumorphic/neu_decoration.dart`

---

## 1. Gotowe Widgety (High-Level)

Najprostszy sposób na użycie stylu. Widgety te automatycznie obsługują motyw (Light/Dark).

| Widget | Opis | Zastosowanie | Gdzie użyte w aplikacji (przykłady) |
|--------|------|--------------|--------------------------------------|
| **`NeuContainer`** | Podstawowy kontener | Karty, sekcje, tła | `BackupScreen` (sekcje), `ManageScreen` (kafelki) |
| **`NeuBasinContainer`** | Kontener wklęsły (Inset) | Pola formularzy, Search Bar | `HomeScreen` (wyszukiwarka), `ImportForm` (pola tekstowe) |
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
| **`.pressed()`** | Wklęsły (wciśnięty) | Stan aktywny przycisku, włączone toggle | Wciśnięte przyciski menu |
| **`.pressedSmall()`** | Wklęsły, subtelniejszy | Stan aktywny małych elementów, **aktywny NeuIconButton** | Wybrane filtry, aktywne tagi, toolbar buttons (pressed/active) |
| **`.basin()`** | **Mocno wklęsły (Inset)** | Wnętrze pól tekstowych, inputy | `TextField` decoration, Search Bar container |
| **`.convex()`** | Wypukły z gradientem | Elementy interaktywne "3D" | (Opcjonalne) Przyciski specjalne |
| **`.statusCard()`** | Wypukły + kolor statusu | Karty zależne od stanu | `MedicineCard` (status: OK, expiring, expired) |

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

### Pole tekstowe (Basin)

```dart
// Opcja 1: Użycie gotowego widgetu (Zalecane)
NeuBasinContainer(
  child: TextField(
    decoration: InputDecoration(hintText: "Wpisz nazwę..."),
  ),
)

// Opcja 2: Ręczna dekoracja
Container(
  decoration: NeuDecoration.basin(
    isDark: isDark, 
    radius: 12
  ),
  child: TextField(...),
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
