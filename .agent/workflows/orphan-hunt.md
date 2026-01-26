---
description: Systematyczne usuwanie martwego kodu (orphan-code) z projektu
---

# Orphan Hunt Workflow

// turbo-all

## Krok 1: Analiza lint (Flutter)

```bash
cd apps/mobile && dart analyze 2>&1 | Select-String -Pattern "unused_|dead_code"
```

## Krok 2: Skanowanie TODO bez formatu

```bash
cd apps/mobile && Select-String -Path "lib\**\*.dart" -Pattern "TODO" | Select-String -NotMatch "TODO\("
```

## Krok 3: Przeczytaj instrukcję i wygeneruj raport

Przeczytaj `.agent/prompts/orphan-hunt-workflow.md` i wykonaj procedurę.

Dla każdego znaleziska:

1. Sprawdź Find Usages (czy element jest używany)
2. Sprawdź czy nie ma `// KEEP:`
3. Sprawdź git blame (kiedy ostatnio modyfikowany)

## Krok 4: Wygeneruj raport

Utwórz raport w `docs/audits/orphan-hunt-YYYYMMDD.md`:

```markdown
# Orphan Hunt Report - YYYY-MM-DD

**Ocena:** [czysto / akceptowalne / cmentarzysko]

## Usunięte

- [plik:linia] - [opis]

## Zachowane (KEEP)

- [plik:linia] - [powód z KEEP]

## TODO naprawione

- [plik:linia] - [co zrobiono]
```

## Krok 5: Usuń orphany

Po akceptacji raportu przez użytkownika, usuń zidentyfikowane elementy.

## Krok 6: Weryfikacja

```bash
cd apps/mobile && flutter analyze
```

## Krok 7: Commit

```
#N Orphan Hunt: usunięto X martwych elementów
```
