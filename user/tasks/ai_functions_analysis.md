# Analiza Funkcji AI w APPteczka

> **Data Raportu:** 2026-02-01 **Cel:** Identyfikacja wszystkich miejsc generujących koszty AI
> (Gemini/Vision/OCR).

## Zestawienie Zbiorcze

Zidentyfikowano **5 głównych funkcji AI** oraz **1 proces w tle**, które generują zapytania do API.

| ID    | Funkcja                        | Opis                                                                                 | Trigger (Wyzwalacz)                                                                          | Oznaczenie UI                                                    |
| :---- | :----------------------------- | :----------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------- | :--------------------------------------------------------------- |
| **1** | **Name Lookup**                | Wyszukiwanie leku po nazwie (baza + AI Fallback).                                    | **Ręczny**<br>Użytkownik wpisuje nazwę w "Wyszukaj lek" i klika lupę/enter.                  | Ikona `textSearch` z `sparkles`.                                 |
| **2** | **Barcode Scanner (Fallback)** | Rozpoznawanie produktu ze zdjęcia, gdy kod EAN jest nieznany (brak w RPL).           | **Automatyczny**<br>Natychmiast po zeskanowaniu kodu, którego nie ma w bazie.                | Dialog postępu "Przetwarzanie AI...".                            |
| **3** | **Product Photo**              | Rozpoznawanie leku na podstawie zdjęcia całego opakowania.                           | **Ręczny**<br>Kliknięcie "Zrób zdjęcie nazwy" w trybie skanera `productPhoto`.               | Ikona `camera` + pomarańczowa ramka AI.                          |
| **4** | **Expiry Date OCR**            | Odczyt daty ważności ze zdjęcia (OCR).                                               | **Ręczny**<br>Kliknięcie "Zrób zdjęcie daty ważności" w trybie skanera `expiryDate`.         | Ikona `calendarPlus`.                                            |
| **5** | **Shelf Life Analysis**        | Analiza ulotki PDF (jeśli dostępna) w celu znalezienia terminu ważności po otwarciu. | **Automatyczny**<br>Uruchamiane w tle po zapisaniu leku, który ma przypisany link do ulotki. | Ikona `sparkles` obok pola "Okres przydatności" (Medicine Card). |

## Procesy w Tle (Ukryte Koszty)

### Background Queue Processing

W ekranie `AddMedicineScreen` zaimplementowano kolejkę przetwarzania w tle dla trybu wsadowego
(Batch Mode).

- **Zasada działania:** Jeśli na liście oczekujących znajduje się więcej niż **3 leki**, aplikacja
  automatycznie uruchamia `_startBackgroundProcessing` dla najstarszych pozycji.
- **Cel:** Wzbogacenie danych (opis, tagi, wskazania) przez Gemini przed finalnym zapisaniem.
- **Ryzyko:** Przy szybkim dodawaniu wielu leków (np. import z pliku lub szybki skan), zapytania AI
  są generowane automatycznie bez wyraźnej akcji "Zapisz" dla każdego leku z osobna.

## Weryfikacja

Raport przygotowano na podstawie analizy kodu źródłowego:

- `GeminiNameLookupService`
- `GeminiService` (Vision OCR)
- `DateOcrService`
- `GeminiShelfLifeService`
- `BarcodeScannerWidget` & `AddMedicineScreen` (logika triggers)

### Paleta kolorów AI

| Tryb  | Kolor      | Hex       |
| ----- | ---------- | --------- |
| Light | Violet-500 | `#8B5CF6` |
| Dark  | Purple-600 | `#9333EA` |

## Serwisy AI (endpointy Gemini)

| Serwis                    | Endpoint                  | Funkcja            |
| ------------------------- | ------------------------- | ------------------ |
| `GeminiService`           | `/api/gemini-ocr`         | OCR produktu       |
| `GeminiShelfLifeService`  | `/api/gemini-shelf-life`  | Analiza ulotki     |
| `GeminiNameLookupService` | `/api/gemini-name-lookup` | Wzbogacanie danych |
| `DateOcrService`          | `/api/date-ocr`           | OCR daty           |

## Analiza Migracji na Local AI (Gemini Nano / ML Kit)

Przeprowadzono research możliwości przeniesienia funkcji do przetwarzania lokalnego (On-Device), aby
zredukować koszty API.

### Dostępność Technologii (Stan na 2026)

- **Gemini Nano**: Dostępny głównie na flagowcach (Pixel 9, Samsung S24/S25). **Brak wsparcia na
  iOS**. Wymaga Android AICore.
- **Google ML Kit**: Dostępny na każdym urządzeniu (Android/iOS). Darmowy, offline. Idealny do zadań
  OCR i detekcji.
- **Local LLM (Gemma/Llama)**: Możliwe uruchomienie przez `executorch`/`llama.cpp`, ale wiąże się to
  z pobraniem modelu **~2GB+**, co jest krytyczną barierą dla aplikacji użytkowej typu "Apteczka".

### Rekomendacje Migracji

| Funkcja                    | Wykonalność Lokalna | Rekomendowana Technologia                                                                                                                                                                    | Oszczędność |
| :------------------------- | :------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------- |
| **1. Name Lookup**         | 🔴 Niska            | **Cloud**. Lokalne LLM są za duże (GBs) lub za głupie (brak wiedzy o lekach polskich bez RAG).                                                                                               | -           |
| **2. Barcode Fallback**    | 🔴 Niska            | **Cloud (Gemini)**. ML Kit odczyta tylko "surowy tekst". Brak lokalnej inteligencji, która zrozumie kontekst ("to jest lek", "to dawka") i stworzy obiekt `ScannedMedicine`. OCR to za mało. | -           |
| **3. Product Photo**       | 🔴 Niska            | **Cloud (Gemini)**. Jw. Rozpoznawanie leku ze zdjęcia wymaga modelu multimodalnego. Lokalny OCR nie odróżni "producenta" od "nazwy" bez skomplikowanej heurystyki.                           | -           |
| **4. Expiry Date OCR**     | 🟢 **Wysoka**       | **ML Kit Text Recognition**. To zadanie nie wymaga AI generatywnego. Zwykły OCR radzi sobie doskonale z formatem `MM/YYYY`.                                                                  | $$          |
| **5. Shelf Life Analysis** | 🟢 **Wysoka**       | **Regex / Algorytm**. Szukanie fraz "okres ważności po otwarciu wynosi X" w tekście PDF nie wymaga LLM. Można to zrobić prostym skryptem po ekstrakcji tekstu.                               | $$          |

### Wnioski

1.  **Zadanie Krytyczne:** Natychmiastowa migracja **Expiry Date OCR** na Google ML Kit (100%
    darmowe, offline).
2.  **Optymalizacja:** Zamiana `GeminiShelfLifeService` na lokalną analizę tekstu (Regex) po
    ekstrakcji treści PDF.
3.  **Vision:** Pozostawienie Gemini dla funkcji **Barcode Fallback** i **Product Photo**. Lokalny
    OCR nie jest w stanie zastąpić wnioskowania semantycznego (rozumienia co jest czym na
    opakowaniu), które oferuje model Vision.
