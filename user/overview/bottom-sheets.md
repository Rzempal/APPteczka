# Zestawienie BottomSheetów w aplikacji

Dokument zawiera listę zidentyfikowanych komponentów typu `BottomSheet` w projekcie, podzieloną na
dedykowane klasy oraz implementacje lokalne.

## 1. Dedykowane klasy BottomSheet

Pliki znajdujące się w `apps/mobile/lib/widgets/`:

| Nazwa klasy                   | Plik                          | Opis                                                                                                                                                |
| :---------------------------- | :---------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`RplPackageSelectorSheet`** | `rpl_package_selector.dart`   | Wybór opakowania leku z bazy Rejestru Produktów Leczniczych (RPL).                                                                                  |
| **`BugReportSheet`**          | `bug_report_sheet.dart`       | Formularz zgłaszania błędów i feedbacku.                                                                                                            |
| **`BatchDateInputSheet`**     | `batch_date_input_sheet.dart` | Masowe wprowadzanie dat ważności dla nowo dodanych leków.                                                                                           |
| **`FiltersSheet`**            | `filters_sheet.dart`          | Zaawansowane filtry na ekranie głównym (tagi, etykiety, daty).                                                                                      |
| **`LeafletSearchSheet`**      | `leaflet_search_sheet.dart`   | Wyszukiwarka ulotek w bazie Ministerstwa Zdrowia (wywoływana z karty leku).                                                                         |
| **`AppBottomSheet`**          | `app_bottom_sheet.dart`       | Klasa użytkowa (wrapper) zapewniająca spójny styl (neumorfizm, drag handle) dla innych arkuszy. Udostępnia metody statyczne `show` i `showOptions`. |

## 2. Implementacje lokalne w HomeScreen

Implementacje znajdujące się w `apps/mobile/lib/screens/home_screen.dart` (jako metody prywatne lub
wewnętrzne widgety):

| Metoda wywołująca           | Opis działania                                                                 | Uwagi                                                 |
| :-------------------------- | :----------------------------------------------------------------------------- | :---------------------------------------------------- |
| **`_showSortBottomSheet`**  | Opcje sortowania listy leków.                                                  | Wykorzystuje `AppBottomSheet.show`.                   |
| **`_showFilterManagement`** | Menu zarządzania filtrami, eksportem do PDF i opcjami masowymi.                | Wykorzystuje `AppBottomSheet.show`.                   |
| **`_showHelpBottomSheet`**  | Wyświetla pomoc/tooltip dla nowych użytkowników.                               | Używa prywatnej klasy `_HelpBottomSheetContent`.      |
| **`_showLabelsSheet`**      | Zarządzanie etykietami dla konkretnego leku (wywołanie przyciskiem na karcie). | Osadza widget `LabelSelector` w standardowym arkuszu. |
| **`_showLabelManagement`**  | Globalne zarządzanie listą dostępnych etykiet (dodawanie/usuwanie).            | Używa prywatnej klasy `_LabelManagementSheet`.        |
| **`_showTagManagement`**    | Globalne zarządzanie listą niestandardowych tagów.                             | Używa prywatnej klasy `_TagManagementSheet`.          |

## 3. Inne uwagi

- **Dialogi:** Część interakcji (np. `_showEditNameDialog`, `_showEditDescriptionDialog` w
  `MedicineCard`) jest realizowana za pomocą standardowych okien dialogowych (`showDialog`), a nie
  arkuszy dolnych.
- **LabelSelector:** Widget ten (`apps/mobile/lib/widgets/label_selector.dart`) jest niezależnym
  komponentem, który w `HomeScreen` jest osadzany wewnątrz `BottomSheet`.
