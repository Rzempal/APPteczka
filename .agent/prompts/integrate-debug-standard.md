# Wdrożenie standardu debug.md

> **Cel:** Prompt dla AI Agenta do integracji `debug.md` w nowym projekcie.

---

## Instrukcja dla AI Agenta

Wkleiłem plik `docs/standards/debug.md` do projektu. Wykonaj poniższe kroki integracji:

### 1. Dostosuj sekcję "Powiązane:"

- Zmień linki na odpowiednie dla tego projektu
- Jeśli nie ma `logging.md` - usuń ten link
- Dodaj link do `contributing.md` jeśli istnieje

### 2. Zaktualizuj `contributing.md` (jeśli istnieje)

- Dodaj `debug.md` do struktury katalogów `docs/standards/`
- Zaktualizuj datę ostatniej modyfikacji

### 3. Sprawdź SSOT

Jeśli istnieje plik `logging.md` lub podobny:

- Usuń zduplikowane sekcje (tabele poziomów, przykłady użycia)
- Zastąp je linkami do `debug.md#odpowiednia-sekcja`
- Zostaw tylko treść project-specific

### 4. Zaimplementuj w kodzie (jeśli brak)

Jeśli projekt nie ma jeszcze:

- `AppLogger` class → utwórz wg wzorca z `debug.md#applogger-pattern`
- `AppConfig.isInternal` → utwórz wg wzorca z `debug.md#kanał-budowania`
- Debug UI w ustawieniach → zaimplementuj wg `debug.md#debug-ui`

### 5. Commit

```
Wdrozenie standardu debug.md do dokumentacji projektu
```

---

**Priorytet:** Najpierw dokumentacja (kroki 1-3), potem kod (krok 4).

---

> 📅 **Ostatnia aktualizacja:** 2026-01-24
