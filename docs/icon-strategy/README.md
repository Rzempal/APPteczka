# Icon Strategy - Karton z lekami

Dokumentacja strategii ikon dla aplikacji APPteczka.

## Warianty Ikon

| Wariant | Opis | Zastosowanie |
|---------|------|--------------|
| **Full Color Closed** | Kolorowy karton zamknięty z taśmą | Android launcher icon |
| **Full Color Open** | Kolorowy karton otwarty z lekami | Menu "Dodaj leki", ilustracje |
| **Mono Closed** | Monochromatyczny z opacity layers | Bottom nav bar (aktywny/nieaktywny) |
| **Mono Open** | Monochromatyczny otwarty | Material You themed icon |

## Pliki źródłowe

- **HTML Preview:** [apk_icons_strategy.html](apk_icons_strategy.html) - interaktywny podgląd wszystkich wariantów
- **Flutter Widgets:** `lib/widgets/karton_icons.dart`
- **Android Monochrome:** `android/app/src/main/res/drawable/ic_launcher_monochrome.xml`

## Kolory

```
--color-mint: #10b981         (Primary)
--box-face-top: #E6C590       (Karton góra)
--box-face-right: #D4B070     (Karton prawo) 
--box-face-left: #C29B55      (Karton lewo)
```

## Użycie widgetów

```dart
// Kolorowy zamknięty
KartonClosedIcon(size: 80, isDark: true)

// Kolorowy otwarty
KartonOpenIcon(size: 80, isDark: true)

// Mono (dla nav bar)
KartonMonoClosedIcon(size: 24, color: Colors.mint)
```

---

> 📅 **Ostatnia aktualizacja:** 2026-01-02
