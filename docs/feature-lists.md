# 📊 Szczegółowe Porównanie Funkcji (Web vs Mobile)

> ℹ️ **Status**: Mobile (Flutter) osiągnął parytet funkcjonalny z wersją Web, włącznie z Gemini Vision, systemem etykiet i importem z plików.

## 📱 Podsumowanie

| Kategoria | Web (Next.js) | Mobile (Flutter) |
| :--- | :--- | :--- |
| **Wersja** | 1.1.0 | 1.2.0 |
| **Styl** | Neumorphism (Soft UI) | Neumorphism (Soft UI) |
| **Baza** | localStorage | Hive (NoSQL) |
| **Dostęp** | Przeglądarka (PWA)| Aplikacja Android/iOS |

---

## 🛠️ Lista Funkcji

### 1. Zarządzanie Lekami

| Funkcja | Szczegóły | Web | Mobile | Uwagi |
| :--- | :--- | :--- | :--- | :--- |
| **Lista leków** | Widok kart z detalami | ✅ Tak | ✅ Tak | Web ma animacje wejścia |
| **Wyszukiwanie** | Po nazwie, opisie, tagach | ✅ Tak | ✅ Tak | |
| **Sortowanie** | A-Z, Z-A, Termin ↑, Termin ↓, Data dodania ↑/↓ | ✅ Tak | ✅ Tak | Mobile: Popup menu |
| **Filtrowanie** | Po tagach | ✅ Tak | ✅ Tak | |
| | Po terminie ważności | ✅ Tak | ✅ Tak | (Wszystkie/Ważne/Kończące się) |
| | Licznik aktywnych filtrów | ✅ Tak | ✅ Tak | |
| **Dodawanie** | Formularz ręczny | ✅ Tak | ✅ Tak | |
| | Walidacja pól | ✅ Tak | ✅ Tak | Nazwa i opis wymagane |
| **Edycja** | Pełna edycja danych | ✅ Tak | ✅ Tak | |
| **Usuwanie** | Pojedyncze | ✅ Tak | ✅ Tak | Mobile: Swipe-to-delete |
| | Masowe (Wyczyść wszystko) | ✅ Tak | ✅ Tak | Wymaga potwierdzenia |
| **Status ważności**| Kolorowe oznaczenia | ✅ Tak | ✅ Tak | 🟢 Ważne, 🟠 < 30 dni, 🔴 Przeterminowane |
| **Licznik leków** | Suma leków w apteczce | ✅ Tak | ✅ Tak | |

### 2. Integracja AI i Import

| Funkcja | Szczegóły | Web | Mobile | Uwagi |
| :--- | :--- | :--- | :--- | :--- |
| **Generator Promptu**| Kopiowanie promptu AI | ✅ Tak | ✅ Tak | Pozwala na demo "AI loop" |
| **Import JSON (Wklej)** | Wklejanie JSON z AI | ✅ Tak | ✅ Tak | Format kompatybilny |
| **Import JSON (Plik)** | Wybór pliku .json | ✅ Tak | ✅ Tak | FilePicker |
| **Gemini Vision** | Bezpośrednie zdjęcie | ✅ Tak | ✅ Tak | Mobile: przez API Vercel |
| **Import masowy** | Obsługa wielu leków | ✅ Tak | ✅ Tak | |
| **System Etykiet** | Tworzenie/edycja/filtrowanie | ✅ Tak | ✅ Tak | Max 15 globalnie, 5 per lek |

### 3. Dane i Eksport

| Funkcja | Szczegóły | Web | Mobile | Uwagi |
| :--- | :--- | :--- | :--- | :--- |
| **Eksport JSON** | Kopia zapasowa do schowka | ✅ Tak | ✅ Tak | Pełna zgodność formatu |
| **Eksport PDF** | Gotowy druk dla lekarza | ✅ Tak | ✅ Tak | Web: `jspdf`, Mobile: `pdf`+`printing` |
| **Offline** | Działanie bez internetu | ✅ Tak | ✅ Tak | Web: localStorage, Mobile: Hive |
| **Synchronizacja** | Przenoszenie danych | Manual | Manual | Automatyczna sync planowana w Fazie 3 |

### 4. UI / UX

| Funkcja | Szczegóły | Web | Mobile | Uwagi |
| :--- | :--- | :--- | :--- | :--- |
| **Styl** | Główny motyw | Neumorphism | Neumorphism | Spójny styl z wersją Web |
| **Tryb Ciemny** | Dark Mode | ✅ Tak | ✅ Tak | Mobile: 3-way toggle (System/Light/Dark) |
| **Nawigacja** | Struktura | 3 Tabs | Bottom Bar | Apteczka / Dodaj / Ustawienia |
| **Widok listy** | Kompaktowy / Pełny | ✅ Tak | ✅ Tak | Toggle w toolbarze |
| **Responsywność** | Mobile/Tablet/Desktop | ✅ Tak | ✅ Tak | Flutter skaluje się natywnie |
| **Feedback** | Toasty/Snackbary | ✅ Tak | ✅ Tak | Potwierdzenia akcji |
| **Animacje** | Mikro-interakcje | ✅ Tak | ✅ Tak | Tap feedback, scale, haptic |

### 5. Planowane (Roadmap)

| Funkcja | Web | Mobile | Priorytet |
| :--- | :--- | :--- | :--- |
| **Powiadomienia** | ❌ Nie | ⏳ Planowane | Wysoki (Local Notifications) |
| **Skaner kodów** | ⏳ Planowane | ⏳ Planowane | Średni (Barcode Scanner) |
| **Backend Sync** | ⏳ Planowane | ⏳ Planowane | Niski (Faza 3) |

---

> 📅 **Ostatnia aktualizacja:** 2026-01-01
