# Orphan Hunt Workflow - Instrukcja dla Agenta AI

> **Cel:** Systematyczne usunięcie martwego kodu z projektu APPteczka.

---

## Kontekst

Przeczytaj dokumentację:

- `docs/standards/conventions.md` → sekcja "Higiena Kodu"
- `docs/standards/code-review.md` → sekcja "Szósta warstwa: Polowanie na sieroty"

---

## Procedura krok po kroku

### 1. Analiza automatyczna

```bash
# Flutter/Dart - wykryj nieużywane elementy
cd apps/mobile
dart analyze 2>&1 | grep -E "(unused_|dead_code)"
```

### 2. Skanowanie TODO/FIXME

```bash
# Znajdź wszystkie TODO bez formatu (autor YYYY-MM)
grep -rn "TODO" --include="*.dart" apps/mobile/lib | grep -v "TODO("
```

### 3. Dla każdego znaleziska wykonaj

```markdown
1. **Find Usages** - sprawdź czy element jest gdziekolwiek wywoływany
2. **Sprawdź KEEP** - szukaj `// KEEP:` nad elementem
3. **Git blame** - sprawdź kiedy ostatnio modyfikowany
   - Jeśli >3 miesiące i brak użycia → kandydat do usunięcia
```

### 4. Decyzja i akcja

| Znalezisko         | KEEP? | Ostatnia zmiana | Akcja           |
| ------------------ | ----- | --------------- | --------------- |
| Nieużywana funkcja | ❌    | >3 mies.        | DELETE          |
| Nieużywana funkcja | ✅    | -               | ZACHOWAJ        |
| Martwy import      | -     | -               | DELETE (zawsze) |
| TODO bez formatu   | -     | >3 mies.        | DELETE lub FIX  |
| Kod po return      | -     | -               | DELETE (zawsze) |

### 5. Commit

Format wiadomości:

```
#N Orphan Hunt: usunięto X martwych elementów

- Usunięto: [lista plików/funkcji]
- Zachowano (KEEP): [lista z powodami]
```

---

## Zasady bezpieczeństwa

1. **NIE usuwaj** kodu z adnotacją `// KEEP: powód`
2. **NIE usuwaj** elementów publicznego API bez weryfikacji zewnętrznych zależności
3. **Przy wątpliwościach** → zapytaj użytkownika
4. **Testuj po usunięciu** → `flutter analyze` + `flutter test`

---

## Przykładowy output

```markdown
## Orphan Hunt Report - 2026-01-26

**Ocena:** akceptowalne (7 orphanów znalezionych)

### Usunięte:

- `lib/helpers/legacy_formatter.dart` - cały plik, brak referencji od 2025-08
- `lib/widgets/medicine_card.dart:145` - `_onLegacyTap()` - nieużywana od refaktoru
- `lib/screens/home_screen.dart:23` - import `dart:developer` - nieużywany

### Zachowane (KEEP):

- `lib/services/calendar_sync.dart` - `// KEEP: integracja z Google Calendar Q2`

### TODO naprawione:

- `lib/utils/date_helpers.dart:67` - dodano format `TODO(rzempal 2026-01):`
```

---

> 📅 **Utworzono:** 2026-01-26
