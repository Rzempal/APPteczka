# Dynamic Status - Lista scenariuszy

Plik zawiera wszystkie możliwe komunikaty/scenariusze wyświetlane w polu **dynamicStatus** (H2) na
karcie leku w trybie compact.

---

## Priorytet komunikatów (od najważniejszego)

### 🔴 Priorytet 1: Krytyczny (kolor: `AppColors.expired` - czerwony)

| #   | Scenariusz                                 | Komunikat                           | Warunek                   |
| --- | ------------------------------------------ | ----------------------------------- | ------------------------- |
| 1.1 | Krytycznie niski stan (opakowanie otwarte) | `KRYTYCZNIE NISKI STAN - UZUPEŁNIJ` | `percentRemaining <= 10%` |
| 1.2 | Krytycznie niski zapas (dni)               | `ZAPAS NA X DNI - UZUPEŁNIJ`        | `daysSupply <= 3`         |
| 1.3 | Produkt przeterminowany                    | `Produkt przeterminowany`           | `daysUntilExpiry < 0`     |

---

### 🟠 Priorytet 2: Ostrzeżenie (kolor: `AppColors.expiringSoon` - amber)

| #   | Scenariusz             | Komunikat             | Warunek                     |
| --- | ---------------------- | --------------------- | --------------------------- |
| 2.1 | Ważność wygasa wkrótce | `Ważne jeszcze X dni` | `0 <= daysUntilExpiry <= 7` |

---

### 🔵 Priorytet 3: Informacja (kolor: `theme.colorScheme.primary`)

| #   | Scenariusz              | Komunikat                              | Warunek                                              |
| --- | ----------------------- | -------------------------------------- | ---------------------------------------------------- |
| 3.1 | Przydatność po otwarciu | `Po otwarciu: [shelfLifeAfterOpening]` | opakowanie otwarte + `shelfLifeAfterOpening != null` |

---

### ⚪ Priorytet 4: Default (kolor: `theme.colorScheme.onSurfaceVariant`)

| #   | Scenariusz    | Komunikat         | Warunek        |
| --- | ------------- | ----------------- | -------------- |
| 4.1 | Normalny opis | `[medicine.opis]` | brak warningów |

---

## Diagram przepływu

```
┌─────────────────────────────────────────┐
│          Sprawdź dynamicStatus          │
└─────────────────────────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ packages.isNotEmpty?  │
        └───────────────────────┘
           │ TAK            │ NIE
           ▼                ▼
  ┌─────────────────┐   ┌─────────────────┐
  │ isOpen &&       │   │ pieceCount?     │
  │ percentRemaining│   └─────────────────┘
  │ <= 10%?         │            │
  └─────────────────┘            ▼
       │ TAK              ┌─────────────────┐
       ▼                  │ dailyIntake &&  │
  🔴 KRYTYCZNIE           │ daysSupply <=3? │
     NISKI STAN           └─────────────────┘
                               │ TAK
                               ▼
                          🔴 ZAPAS NA X DNI

                    │
                    ▼
        ┌───────────────────────┐
        │ expiryStatus?         │
        │ expiringSoon/expired  │
        └───────────────────────┘
           │ TAK
           ▼
  ┌─────────────────────────────┐
  │ daysUntilExpiry < 0?        │──▶ 🔴 PRZETERMINOWANY
  │ daysUntilExpiry <= 7?       │──▶ 🟠 Ważne X dni
  └─────────────────────────────┘

                    │
                    ▼
        ┌───────────────────────┐
        │ shelfLifeAfterOpening │
        │ && isOpen?            │
        └───────────────────────┘
           │ TAK
           ▼
        🔵 Po otwarciu: [value]

                    │
                    ▼
        ⚪ Default: [opis]
```

---

## Brakujące scenariusze (do rozważenia)

| #   | Potencjalny scenariusz      | Komunikat            | Komentarz                      |
| --- | --------------------------- | -------------------- | ------------------------------ |
| ?   | Niski zapas (nie krytyczny) | `Niski zapas`        | 10% < remaining <= 25%         |
| ?   | Lek wymaga przepisu         | `Lek na receptę`     | jeśli `isPrescription == true` |
| ?   | Lek otwarty                 | `Opakowanie otwarte` | tylko informacja               |
| ?   | Brak danych o zapasie       | `Uzupełnij dane`     | brak packages                  |
| ?   | Termin ważności nieznany    | `Brak daty ważności` | `terminWaznosci == null`       |

---

> **Pytanie do użytkownika:** Czy chcesz dodać któryś z "brakujących scenariuszy" do listy?
