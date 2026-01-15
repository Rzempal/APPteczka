# 🎨 Neumorphism Style Guide

> **Powiązane:** [Design Review](design-review.md) | [Standardy Kodu](conventions.md)

---

## 🏛️ Filozofia Stylu

Neumorfizm w tym projekcie nie jest celem samym w sobie, lecz narzędziem do budowania hierarchii. Zgodnie z zasadą **KISS** (patrz [Design Review](design-review.md)), stosujemy go oszczędnie, aby nie zaburzyć czytelności (Accessibility).

---

## 🎨 Design Tokens (Neu-Tokens)

### Dekoracje Bazowe (`NeuDecoration`)

Wszystkie dekoracje są wielokrotnością **8px Grid System**.

| Metoda | Radius | Wygląd | Zastosowanie |
| --- | --- | --- | --- |
| **`.flat()`** | 16px | Wypukły, miękki | Standardowe kontenery, karty |
| **`.flatSmall()`** | 12px | Wypukły, subtelny | Tagi, chipy, małe przyciski |
| **`.pressed()`** | 16px | Wklęsły | Stan aktywny (debossed) |
| **`.searchBar()`** | 28px (Pill) | Floating | Główny pasek wyszukiwania |

### Kolory Semantyczne

Zgodnie z Design Systemem, przyciski akcji używają tokenów `--color-error` oraz `--color-primary`.

- **`.primaryButton()`**: Stosuje `--color-primary` (Zapisz, Dodaj).
- **`.destructiveButton()`**: Stosuje `--color-error` (Usuń).

---

## 📐 Layout i Siatka

Zasady spójności (Consistency):

- **Padding kart:** Standardowo 16px.
- **Marginesy między elementami:** Wielokrotność 8px.
- **Radius:** Standardowo 16px dla dużych elementów, 12px dla małych.

---

## 🧩 Komponenty (Atomic Design)

### 1. Atomy (Bazowe elementy)

- **`NeuButton`**: Podstawowy przycisk akcji.
- **`NeuIconButton`**: Przycisk ikony (tryby: visible, iconOnly).
- **`NeuDecoration`**: Surowe style dekoracji.

### 2. Molekuły (Małe grupy)

- **`NeuInsetContainer`**: Kontener z wewnętrznymi cieniami (np. pola formularzy).
- **`NeuSortMenu`**: Neumorficzne menu wyboru.
- **`SearchBar`**: Kompozycja pola tekstowego i pływającego kontenera.

### 3. Organizmy (Złożone struktury)

- **`FloatingNavBar`**: Lewitująca nawigacja dolna.
- **`CollapsibleContainer`**: Rozwijane sekcje szczegółów.

---

## ♿ Dostępność (WCAG 2.1)

Neumorfizm niesie ryzyko niskiego kontrastu. Aby zachować standardy z `DESIGN.md`:

- **Tekst i Ikony:** Nigdy nie polegaj na samym cieniu do rozróżnienia elementów interaktywnych. Używaj wyraźnych kolorów tekstowych (minimum 4.5:1).
- **Focus States:** Skupienie (np. `searchBarFocused`) musi być sygnalizowane dodatkowym elementem (np. zielony outline), a nie tylko zmianą cienia.
- **Haptic Feedback:** Każda interakcja (np. `switchOption`) musi generować sygnał haptyczny dla osób niewidomych/słabowidzących.

---

## 🚀 UX Principles

- **Optimistic UI:** Używamy `AnimatedContainer` (200-250ms) dla płynnych przejść między stanami `flat` a `pressed`.
- **Loading States:** Shimmer/Skeletons powinny zachowywać radius 16px, aby pasować do kart.
- **Feedback:** Używamy `HapticFeedback.lightImpact()` przy zmianach stanu (Toggle, Button).

---

> 📅 **Ostatnia aktualizacja:** 2026-01-14
