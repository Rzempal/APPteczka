# 🧪 Strategia Testów i TDD

> **Powiązane:** [Konwencje](conventions.md) | [Architektura](architecture.md)

---

## Filozofia TDD

W tym projekcie stosujemy podejście **Test-Driven Development**. Kod bez testów jest uznawany za „dług techniczny” już w momencie powstania.

1. **RED**: Napisz test dla nowej funkcjonalności i zobacz, jak zawodzi.
2. **GREEN**: Napisz minimalną ilość kodu, aby test przeszedł.
3. **REFACTOR**: Oczyść kod, zachowując przechodzące testy.

---

## Rodzaje Testów

### 1. Testy Jednostkowe (Unit Tests)

- **Cel**: Testowanie pojedynczych funkcji/metod w izolacji.
- **Zasada**: 100% pokrycia logiki biznesowej.
- **Narzędzia**: `jest` (Frontend), `pytest` (Backend).

### 2. Testy Integracyjne

- **Cel**: Weryfikacja współpracy między komponentami (np. API <-> DB).
- **Zasada**: Testowanie "happy path" i krytycznych błędów.

### 3. Testy E2E (End-to-End)

- **Cel**: Symulacja pełnych ścieżek użytkownika w przeglądarce.
- **Narzędzia**: `Playwright` lub `Cypress`.

---

## Standardy Pisania Testów

### Struktura: Given-When-Then

Używamy opisowych nazw testów i struktury AAA (Arrange, Act, Assert).

```typescript
test('should calculate project match percentage correctly', () => {
  // GIVEN (Arrange)
  const project = { width: 10, length: 20 };
  const plot = { width: 15, length: 25 };

  // WHEN (Act)
  const result = calculateProjectMatch(project, plot);

  // THEN (Assert)
  expect(result.percentage).toBe(100);
});
```

### Co testować (Kryterium Linusa)

- **Problem realny**: Testuj to, co może się zepsuć i ma wpływ na użytkownika.
- **Przypadki brzegowe**: Puste dane, błędy sieci, nieprawidłowe formaty.

---

## Uruchamianie Testów

```bash
# Backend
pytest

# Frontend
npm test
```

---

> 📅 **Ostatnia aktualizacja:** 2026-01-14
