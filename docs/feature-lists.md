# 📊 Porównanie Funkcji (Web vs Apk)

> ℹ️ **Status**: Apk (Android) jest obecnie o **4** funkcje w tyle za wersją Web.

| Funkcja | Web (Next.js) | Apk (Flutter) | Status |
|---------|---------------|---------------|--------|
| **Podstawowe** | | | |
| Lista leków | ✅ Tak | ✅ Tak | Równe |
| Dodawanie ręczne | ✅ Tak | ✅ Tak | Równe |
| Edycja leku | ✅ Tak | ✅ Tak | Równe |
| Usuwanie leku | ✅ Tak | ✅ Tak | Równe |
| Wyszukiwanie tekstowe | ✅ Tak | ✅ Tak | Równe |
| Sortowanie | ✅ Tak | ✅ Tak | Równe |
| Filtrowanie | ✅ Tak | ✅ Tak | Równe |
| **Dane i Backup** | | | |
| Import/Eksport JSON | ✅ Tak | ✅ Tak | Równe |
| Eksport PDF | ✅ Tak | ❌ Nie | **Web Only** |
| Kopia zapasowa do schowka | ✅ Tak | ✅ Tak | Równe |
| **AI i Automatyzacja** | | | |
| Generator promptu AI (kopiowanie) | ✅ Tak | ✅ Tak | Równe |
| Gemini OCR (rozpoznawanie ze zdjęć) | ✅ Tak | ❌ Nie (tylko prompt) | **Web Only** |
| **UI/UX** | | | |
| Design Neumorficzny | ✅ Tak | ❌ Nie (Material 3) | **Web Only** |
| Nawigacja | 3-tab (Bottom Bar) | 3-tab (NavigationBar) | Równe |
| Animacje | Scroll + Micro-interactions | Standard Material | **Web Only** |
| **Inne** | | | |
| Offline-first | ✅ Tak | ✅ Tak | Równe |
| Skaner kodów kreskowych | ❌ Planowane | ❌ Planowane | - |

---

## 📝 Szczegóły różnic

### 1. Eksport PDF

- **Web**: Generuje gotowy plik PDF z listą leków do druku dla lekarza.
- **Apk**: Brak. Użytkownik może jedynie skopiować JSON.

### 2. Gemini AI OCR

- **Web**: Zintegrowane API Gemini Vision. Użytkownik robi zdjęcie -> formularz wypełnia się sam.
- **Apk**: "Manualne AI". Użytkownik kopiuje prompt -> wkleja do ChatGPT -> kopiuje JSON -> importuje.

### 3. Design

- **Web**: Unikalny styl Neumorphism (Soft UI), niestandardowe cienie, szklane efekty.
- **Apk**: Standardowy Material Design 3 (Google native look).

### 4. Animacje

- **Web**: Zaawansowane animacje elementów listy przy scrollowaniu, interaktywne przyciski.
- **Apk**: Standardowe przejścia ekranów Flutter.
