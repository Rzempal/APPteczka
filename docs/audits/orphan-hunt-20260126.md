# Orphan Hunt Report - 2026-01-26

**Ocena:** ✅ czysto (po cleanup)

---

## 🔴 Orphany USUNIĘTE

| Plik                           | Element                   | Typ                   |
| ------------------------------ | ------------------------- | --------------------- |
| `home_screen.dart:214`         | `_collapseSearchBar()`    | unused_element        |
| `update_service.dart:98`       | `_compareVersions()`      | unused_element        |
| `gs1_parser.dart:178`          | `_looksLikeAiStart()`     | unused_element        |
| `tag_selector_widget.dart:178` | `_buildCategorySection()` | unused_element        |
| `karton_icons.dart:323`        | `topColor`                | unused_local_variable |
| `neu_inset_container.dart:50`  | `gradientStop`            | unused_local_variable |
| `neu_text_field.dart:260`      | `_isFocused`              | unused_field          |
| `neu_text_field.dart:306`      | `theme`                   | unused_local_variable |
| `barcode_scanner.dart:1396`    | `_deleteExpiryPhoto()`    | unused_element        |

**Łącznie usunięto: ~180 linii martwego kodu**

---

## 🟢 Zachowane (false positive lub celowe)

| Plik                  | Element                  | Powód                               |
| --------------------- | ------------------------ | ----------------------------------- |
| `home_screen.dart:72` | `_isFiltersSheetOpen`    | Używane przez settery w bottomSheet |
| `home_screen.dart:73` | `_isManagementSheetOpen` | Używane przez settery w bottomSheet |
| `home_screen.dart:80` | `_isSortSheetOpen`       | Używane przez settery w bottomSheet |
| `app_logger.dart:32`  | `_instance`              | Singleton pattern (required)        |

---

## 🟡 Deprecated do osobnego PR

53 ostrzeżenia `deprecated_member_use`:

- `withOpacity` → `.withValues()`
- `value` → `initialValue` / `.r/.g/.toARGB32`

---

## Nowe narzędzia

1. **Sekcja w `conventions.md`**: "Higiena Kodu (Orphan-Code Prevention)"
2. **Sekcja w `code-review.md`**: "Szósta warstwa: Polowanie na sieroty"
3. **Workflow**: `/orphan-hunt` - uruchamiaj raz na sprint

---

> 📅 **Data raportu:** 2026-01-26 10:55 **Commit:** `#N Orphan Hunt: usunięto 9 martwych elementów`
