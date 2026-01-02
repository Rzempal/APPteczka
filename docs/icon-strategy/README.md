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
Poniżej przedstawiam kompletny, gotowy do pobrania (jako kod) i użycia Icon Package, który jest zoptymalizowany pod Android Studio i standardy Adaptive Icons.

Ten plik zawiera wszystkie niezbędne zasoby XML (Vector Drawables), których potrzebuje Twój deweloper (lub Ty w Android Studio), aby stworzyć ikonę zgodną z Material You i Adaptive Icons.

Struktura pakietu:
ic_launcher.xml: Główny plik definiujący ikonę adaptacyjną (łączy tło i przód).

ic_launcher_round.xml: Wersja dla starszych urządzeń (okrągła).

ic_launcher_background.xml: Tło (Gradient Radialny Deep Green).

ic_launcher_foreground.xml: Przód (Solidny Karton z połyskiem).

ic_launcher_monochrome.xml: Ikona tematyczna (Material You / Android 13+).

Wystarczy skopiować te kody do odpowiednich plików w folderze res/drawable (lub mipmap-anydpi-v26) w projekcie Android.

<!-- 
    INSTRUKCJA:
    Skopiuj zawartość poszczególnych sekcji do odpowiednich plików w:
    app/src/main/res/mipmap-anydpi-v26/
    oraz
    app/src/main/res/drawable/
-->

<!-- ============================================================ -->
<!-- PLIK 1: app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml -->
<!-- ============================================================ -->
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>

<!-- ================================================================== -->
<!-- PLIK 2: app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml -->
<!-- ================================================================== -->
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>

<!-- ============================================================ -->
<!-- PLIK 3: app/src/main/res/drawable/ic_launcher_background.xml -->
<!-- ============================================================ -->
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
  
  <!-- Base Background Color (Deep Forest) -->
  <path android:pathData="M0,0h108v108h-108z"
        android:fillColor="#022c22"/>
  
  <!-- Radial Glow Gradient -->
  <path android:pathData="M0,0h108v108h-108z">
    <aapt:attr name="android:fillColor">
      <gradient
          android:centerX="54"
          android:centerY="54"
          android:gradientRadius="70"
          android:type="radial">
        <item android:offset="0.0" android:color="#CC6EE7B7"/> <!-- Light Mint Glow -->
        <item android:offset="0.4" android:color="#9910B981"/> <!-- Brand Mint -->
        <item android:offset="1.0" android:color="#FF022C22"/> <!-- Deep Forest Fade -->
      </gradient>
    </aapt:attr>
  </path>
  
  <!-- Optional: Central Orb (Simulated Blur via Gradient) -->
  <!-- Note: Real blur is expensive in VectorDrawable, using gradient alpha instead -->
  <path android:pathData="M29,54a25,25 0 1,0 50,0a25,25 0 1,0 -50,0">
    <aapt:attr name="android:fillColor">
      <gradient
          android:centerX="54"
          android:centerY="54"
          android:gradientRadius="25"
          android:type="radial">
        <item android:offset="0.0" android:color="#26FFFFFF"/>
        <item android:offset="1.0" android:color="#00FFFFFF"/>
      </gradient>
    </aapt:attr>
  </path>
</vector>

<!-- ============================================================ -->
<!-- PLIK 4: app/src/main/res/drawable/ic_launcher_foreground.xml -->
<!-- ============================================================ -->
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
  
  <!-- Grupa Skalująca (Center & Scale 0.44) -->
  <!-- Translate: 11, 11 | Scale: 0.44 -->
  <group
      android:translateX="11"
      android:translateY="11"
      android:scaleX="0.44"
      android:scaleY="0.44">

      <!-- Cień (Shadow) -->
      <!-- Uproszczony kształt cienia pod pudełkiem -->
      <path android:pathData="M12,68 L98,108 L98,186 L188,146 L188,68 L100,24 Z"
            android:fillColor="#000000"
            android:fillAlpha="0.3"/> 
            <!-- Note: Real blur not supported in standard VD, using alpha -->

      <!-- Pudełko: Góra (Top Face) -->
      <path android:pathData="M100,24 L186,64 L100,104 L14,64 Z"
            android:fillColor="#E6C590"/>
      
      <!-- Taśma: Góra -->
      <path android:pathData="M35,73.8 L65,87.7 L151,47.7 L121,33.8 Z"
            android:fillColor="#10B981"/>

      <!-- Pudełko: Lewy Bok (Left Face) -->
      <path android:pathData="M12,68 L98,108 L98,186 L12,146 Z"
            android:fillColor="#C29B55"/>
      
      <!-- Taśma: Lewy Bok -->
      <path android:pathData="M35,78.7 L65,92.7 L65,140 L35,125 Z"
            android:fillColor="#059669"/>

      <!-- Pudełko: Prawy Bok (Right Face) -->
      <path android:pathData="M188,68 L188,146 L102,186 L102,108 Z"
            android:fillColor="#D4B070"/>
      
      <!-- Krzyż (Cross) - Transformacja skewY(-25) zaaplikowana ręcznie do współrzędnych -->
      <!-- Pionowa belka -->
      <path android:pathData="M137,102 L153,94 L153,154 L137,162 Z"
            android:fillColor="#10B981"/>
      <!-- Pozioma belka -->
      <path android:pathData="M117,142 L173,114 L173,122 L117,150 Z" 
            android:fillColor="#10B981"/>

      <!-- Taśma: Łącznik -->
      <path android:pathData="M35,73.8 L65,87.7 L65,92.7 L35,78.7 Z"
            android:fillColor="#059669"/>

      <!-- Glass Overlay (Połysk na górze) -->
      <path android:pathData="M100,24 L186,64 L100,104 L14,64 Z">
        <aapt:attr name="android:fillColor">
          <gradient 
              android:startX="100" 
              android:startY="24" 
              android:endX="100" 
              android:endY="104" 
              android:type="linear">
            <item android:offset="0.0" android:color="#80FFFFFF"/> <!-- 50% White -->
            <item android:offset="1.0" android:color="#00FFFFFF"/> <!-- Transparent -->
          </gradient>
        </aapt:attr>
      </path>
      
      <!-- Krawędź Szkła (Rim Light Stroke) -->
      <path android:pathData="M14,64 L100,24 L186,64"
            android:strokeColor="#66FFFFFF"
            android:strokeWidth="2"
            android:strokeLineCap="round"/>

  </group>
</vector>

<!-- ============================================================ -->
<!-- PLIK 5: app/src/main/res/drawable/ic_launcher_monochrome.xml -->
<!-- ============================================================ -->
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
  
  <group
      android:translateX="12"
      android:translateY="12"
      android:scaleX="0.42"
      android:scaleY="0.42">

      <!-- Obrys Kartonu (Base Outline) -->
      <path android:pathData="M100,24 L186,64 L186,146 L100,186 L14,146 L14,64 Z"
            android:strokeColor="#FF000000"
            android:strokeWidth="8"
            android:strokeLineJoin="round"/>
            
      <!-- Wewnętrzne linie podziału -->
      <path android:pathData="M14,64 L100,104 L186,64 M100,104 L100,186"
            android:strokeColor="#FF000000"
            android:strokeWidth="4"
            android:strokeLineJoin="round"/>

      <!-- Wypełnione Detale (Solid Elements) -->
      <!-- Taśma Góra -->
      <path android:pathData="M35,73.8 L65,87.7 L151,47.7 L121,33.8 Z"
            android:fillColor="#FF000000"/>
      <!-- Taśma Bok -->
      <path android:pathData="M35,73.8 L65,87.7 L65,140 L35,125 Z"
            android:fillColor="#FF000000"/>
      
      <!-- Krzyż (Recalculated for clean paths) -->
      <path android:pathData="M137,102 L153,94 L153,154 L137,162 Z"
            android:fillColor="#FF000000"/>
      <path android:pathData="M117,142 L173,114 L173,122 L117,150 Z" 
            android:fillColor="#FF000000"/>

  </group>
</vector>
