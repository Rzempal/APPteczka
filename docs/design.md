# 🎨 Neumorphism Style Guide

> **Powiązane:** [Design Review](standards/design-review.md) |
> [Standardy Kodu](standards/conventions.md)

---

## 🏛️ Filozofia Stylu

Neumorfizm w tym projekcie nie jest celem samym w sobie, lecz narzędziem do budowania hierarchii.
Zgodnie z zasadą **KISS** (patrz [Design Review](standards/design-review.md)), stosujemy go
oszczędnie, aby nie zaburzyć czytelności (Accessibility).

W 2026 ewoluujemy w stronę **Hybrid Soft UI** – łącząc miękkie cienie z wyraźnymi obrysami (outline)
dla lepszej wydajności i kontrastu.

---

## 🎨 Paleta Kolorystyczna (System Motywów)

System opiera się na dwóch przeciwstawnych motywach, które zmieniają nie tylko kolory, ale i
"atmosferę" aplikacji.

### ☀️ Light Mode: "Earthy Clinical"

Motyw oparty na naturalnych barwach, redukujący stres medyczny.

| Token Nazwa  | Wartość HEX              | Opis                                                                        |
| ------------ | ------------------------ | --------------------------------------------------------------------------- |
| `--bg-app`   | `#F9F6F2`                | Kość słoniowa (Bone White). Tło główne aplikacji. Ciepłe, nie męczy oczu.   |
| `--frame`    | `#3E514B`                | Dymna zieleń. Kolor głównej ramki telefonu oraz nagłówków tekstowych.       |
| `--accent`   | `#5D8A82`                | Zgaszona Szałwia. Główny kolor akcji, pasków postępu i aktywnych elementów. |
| `--card-bg`  | `#FFFFFF`                | Czysta Biel. Tło kart leków (dla kontrastu z tłem aplikacji).               |
| `--text-sec` | `#6B7C77`                | Szaro-zielony. Teksty pomocnicze, opisy, nieaktywne ikony.                  |
| `--shadow`   | `#E8E3D8`                | Ciepły, beżowy cień (zamiast szarego/czarnego).                             |
| `--border`   | `rgba(62, 81, 75, 0.15)` | Subtelny obrys kart dla definicji kształtu.                                 |

### 🌙 Dark Mode: "Innovation Indigo"

Motyw technologiczny, "cyber-medyczny", zapewniający maksymalny kontrast w nocy.

| Token Nazwa   | Wartość HEX              | Opis                                                                                 |
| ------------- | ------------------------ | ------------------------------------------------------------------------------------ |
| `--bg-app`    | `#1A1A2E`                | Głębokie Indygo. Tło główne. Nie jest to czysta czerń, co pozwala na głębsze cienie. |
| `--frame`     | `#004D40`                | Morski Turkus (Deep Teal). Kolor głównej ramki telefonu.                             |
| `--accent`    | `#00FF9D`                | Neonowa Mięta. Bardzo mocny akcent. Powiadomienia, FAB i aktywne stany.              |
| `--card-bg`   | `#1F1F35`                | Rozjaśnione indygo. Tło kart leków.                                                  |
| `--text-main` | `#E6E6FA`                | Lawenda. Zastępuje biel dla głównego tekstu. Zmniejsza kontrast jaskrawości.         |
| `--shadow`    | `#0A0A16`                | Bardzo ciemny granat/czerń dla cieni.                                                |
| `--border`    | `rgba(0, 255, 157, 0.2)` | Neon Glow. Obrys kart imitujący światło krawędziowe.                                 |

---

## 🗺️ Mapowanie Kolorów na Komponenty

Tabela określa, który kolor z powyższych palet należy zastosować do konkretnego elementu UI.

| Komponent        | Light Mode Color         | Dark Mode Color         | Uwagi                                           |
| ---------------- | ------------------------ | ----------------------- | ----------------------------------------------- |
| Container Frame  | `--frame` (#3E514B)      | `--frame` (#004D40)     | Główna ramka otaczająca ekran (asymetryczna).   |
| Top Header (H1)  | `--frame` (#3E514B)      | `--text-main` (#E6E6FA) | Nagłówek "Moja Apteczka".                       |
| Card Surface     | `--card-bg` (#FFFFFF)    | `--card-bg` (#1F1F35)   | Powierzchnia kart leków.                        |
| Card Outline     | `--border` (Szałwia 15%) | `--border` (Neon 20%)   | **Kluczowe:** Karty muszą mieć `border: 1.5px`. |
| Icons (Active)   | `--accent` (#5D8A82)     | `--accent` (#00FF9D)    | Ikony wewnątrz kart i FAB.                      |
| Chips (Inactive) | `#FFFFFF`                | `#262642`               | Tło nieaktywnych tagów (kontrast w Dark Mode).  |
| Chips (Active)   | `--frame` (#3E514B)      | `--accent` (#00FF9D)    | Tło wybranych tagów.                            |
| Warning/Alert    | `#DCA546`                | `#FFBD2E`               | Np. "Kończy się", "Wygasa".                     |
| Danger/Error     | `#E26D5C`                | `#FF7070`               | Np. "Przeterminowane", "Usuń".                  |

---

## 🎨 Design Tokens (Neu-Tokens)

### Dekoracje Bazowe (`NeuDecoration`)

Wszystkie dekoracje są wielokrotnością **8px Grid System**.

| Metoda             | Radius      | Wygląd            | Zastosowanie                 |
| ------------------ | ----------- | ----------------- | ---------------------------- |
| **`.flat()`**      | 16px        | Wypukły, miękki   | Standardowe kontenery, karty |
| **`.flatSmall()`** | 12px        | Wypukły, subtelny | Tagi, chipy, małe przyciski  |
| **`.pressed()`**   | 16px        | Wklęsły           | Stan aktywny (debossed)      |
| **`.searchBar()`** | 28px (Pill) | Floating          | Główny pasek wyszukiwania    |

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
- **Asymetria:** Główne kontenery (App Frame) używają promieni `50px 50px 20px 80px`.

---

## 🧩 Komponenty (Atomic Design)

### 1. Atomy (Bazowe elementy)

- **`NeuButton`**: Podstawowy przycisk akcji.
- **`NeuIconButton`**: Przycisk ikony (tryby: visible, iconOnly).
- **`NeuDecoration`**: Surowe style dekoracji.

### 2. Molekuły (Małe grupy)

- **`NeuInsetContainer`**: Kontener z wewnętrznymi cieniami (np. pola formularzy).
- **`NeuSortMenu`**: Neumorficzne menu wyboru.
- **`SearchBar`**: Kompozycja pola tekstowego i pływającego kontenera. Styl inset (wciśnięty).

### 3. Organizmy (Złożone struktury)

- **`FloatingNavBar`**: Lewitująca nawigacja dolna.
- **`CollapsibleContainer`**: Rozwijane sekcje szczegółów.
- **`MedicineCard`** (High Performance):
  - Zamiast podwójnych cieni używa **Outline + Single Shadow**.
  - Posiada gradientową poświatę krawędzi (`linear-gradient` od lewego górnego rogu).
- **`FiltersSheet`** (Unified Bottom Sheet):
  - **Typ A** (Alert): Mały, wycentrowany, płaski dół.
  - **Typ B** (Menu): Lista opcji z ikonami.
  - **Typ C** (Complex):
    - Sticky Header (z SearchBar).
    - Horizontal Tabs (Kategorie).
    - Scrollable Content (Chips Cloud).
    - Sticky Footer (Button z blurem tła).
    - Geometria: BorderRadius góra `50px 80px`, dół `0px`.

---

## ♿ Dostępność (WCAG 2.1)

Neumorfizm niesie ryzyko niskiego kontrastu. Aby zachować standardy:

- **Outline (Kluczowe):** W Dark Mode każdy element interaktywny (karta, chip) musi posiadać
  `border` o grubości 1px-1.5px z niskim kryciem (10-20%), aby odciąć się od tła.
- **Tekst:** W Dark Mode używamy koloru Lawendowego (`#E6E6FA`) zamiast bieli, aby uniknąć efektu
  "halo" (zmęczenia wzroku przy czytaniu jasnego tekstu na ciemnym tle).
- **Focus States:** Skupienie musi być sygnalizowane zmianą koloru obrysu na `--accent`.

---

## 🚀 UX Principles

- **Optimistic UI:** Używamy `AnimatedContainer` (200-250ms) dla płynnych przejść między stanami.
- **High Performance:** Na listach powyżej 10 elementów wyłączamy pełne rozmycie (`blur`) cieni na
  rzecz prostszych cieni `BoxShadow` i obrysów.
- **Feedback:** Używamy `HapticFeedback.lightImpact()` przy zmianach stanu (Toggle, Button).

---

> 📅 **Ostatnia aktualizacja:** 2026-01-21
