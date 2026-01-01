# Neumorphism Review - APK vs Web

## Werdykt (Linus Style)

To co widzę na mobile to **nie jest neumorfizm**. To jakaś płaska proteza próbująca udawać głębię.
Web wygląda czysto, ostro i premium. Mobile wygląda jak rozmyta plama.

**Ocena:** 3/10 (Śmieci, do poprawki natychmiast)

---

## Brutalna Analiza Różnic

### 1. Cienie to ŻART

**Web:** Precyzyjne `box-shadow` z jasnym i ciemnym cieniem. Widać wyraźnie źródło światła (góra-lewo). Elementy "wychodzą" z ekranu.
**Mobile:** Rozmyte plamy. `NeuDecoration` używa `withOpacity` w sposób, który brudzi kolory.

* **Problem:** Cienie w `statusCard` w Dark Mode są HARDCODED na `Colors.black` i `Colors.white` zamiast używać zdefiniowanych `AppColors`. To amatorszczyzna.

### 2. "Basin" (Wklęsłość) to totalna porażka

**Web:** Czysty `inset box-shadow`. Wygląda jak wyżłobienie w materiale.
**Mobile:** `NeuBasinContainer` to over-engineered Stack z 5 warstwami gradientów i protezami cienia. Wynik? Wygląda jak brudne pudełko, a nie wklęsły element interfejsu. Flutter nie wspiera `inset` natywnie, ale obecna implementacja "symulacji" jest przekombinowana i nienaturalna.

### 3. Gradienty Statusów (Karty Leków)

**Web:** Karty mają subtelny gradient, ale zachowują spójność z tłem (zwłaszcza w Dark Mode jako `glass-dark`). Status (ważny/kończy się) jest akcentem.
**Mobile:** Karty ("Valid") są szare i martwe. Widać na screenie, że karta "Acard" (kończy się) wygląda jak jajecznica wylana na ekran. Gradienty są zbyt intensywne i "tanie". Nie ma tego eleganckiego "szkła" co w wersji webowej.

### 4. Typography & Layout

**Web:** Dużo oddechu (whitespace). Tagi są małe, zgrabne (`neu-flat-sm`).
**Mobile:** Wszystko ściśnięte. Tagi wyglądają jak guziki od kalesonów (za duże, za grube). Paddingi w kartach są niespójne.

---

## 4. Plan Naprawczy (Priorytet "Critical")

### KROK 1: Naprawa Fundamentów (Shadows & Colors)

* **Wyrzucić** hardcoded kolory cieni w `neu_decoration.dart`. Używać TYLKO `AppColors`.
* Zwiększyć kontrast cieni (zmniejszyć blur, zwiększyć opacity dla ciemnego cienia).
* Shadow distance musi być spójny: `distance: 6`, `blur: 12` dla kart; `distance: 3`, `blur: 6` dla małych elementów.

### KROK 2: Prawdziwy "Basin" (Search Bar)

* Zamiast 5 warstw w `NeuBasinContainer`, użyć biblioteki `flutter_inset_box_shadow` (jeśli możemy dodać dependencję) LUB uprościć implementację do **jednego** `DecoratedBox` z precyzyjnym gradientem wewnątrz, zamiast bawić się w "symulację krawędzi".
* Search bar musi wyglądać jak wycięty w skale, a nie namalowany farbkami.

### KROK 3: Karty Leków (Kluczowy element)

* **Light Mode:** Subtelniejszy gradient. Mniej żółtego w "Kończy się".
* **Dark Mode:** Zaimplementować ten efekt `glass-dark` z CSS!
  * To nie jest zwykły gradient. To `backdrop-filter: blur` (we Flutterze `BackdropFilter` jest drogi, więc symulujemy to półprzezroczystym kolorem tła + subtelny biały border z niskim opacity).
  * Wywalić ten czarny cień (`Colors.black.withOpacity(0.5)`) - wygląda jak smoła. Użyć koloru tła (`0xFF070b15`) z opacity.

### KROK 4: Detale (Tagi i Przyciski)

* Zmniejszyć tagi. Są za wysokie. `padding: symmetric(vertical: 4, horizontal: 8)`.
* Ujednolicić `borderRadius`. Karty `16-20`, Tagi `8-12`. Na mobile wygląda to losowo.

## Decyzja

Czekam na akceptację planu. Zaczynamy od KROKU 1 i 3 (największy wizualny impact).
