# 🚀 Deployment & Automatyzacja

> **Powiązane:** [Architektura](architecture.md) | [Bezpieczeństwo](security.md) | [Standardy](conventions.md)

---

## Filozofia Automatyzacji

Dążymy do tego, aby proces wdrożenia był powtarzalny, bezpieczny i wymagał minimum interwencji manualnej. Głównym narzędziem wdrożeniowym jest skrypt automatyzujący.

---

## 🛠 Skrypt Wdrożeniowy

Wszystkie wdrożenia (Dev/Staging/Prod) powinny być wykonywane za pomocą dedykowanego skryptu:

👉 **Lokalizacja:** `scripts/deploy.ps1`

### Główne funkcje skryptu

1. **Walidacja:** Sprawdzenie obecności kluczy API i zmiennych środowiskowych.
2. **Build:** Kompilacja frontendu i przygotowanie statyków.
3. **Transfer:** Kopiowanie artefaktów na serwer docelowy (SCP/Rsync).
4. **Retention:** Utrzymywanie X ostatnich wersji builda (rollback capability).
5. **Logowanie:** Pełna historia wdrożeń w `deploy_logs/`.

---

## Instruksja Użytkowania (PowerShell)

```powershell
# Wdrożenie na środowisko deweloperskie (domyślne)
.\scripts\deploy.ps1

# Wdrożenie na produkcję z konkretnym tagiem wersji
.\scripts\deploy.ps1 -Target "Production" -Version "1.2.2026.1420"
```

---

## CI/CD (GitHub Actions)

Mimo posiadania skryptu lokalnego, proces produkcyjny jest wspierany przez CI:

- **Main Branch**: Automatyczny deploy na Staging po przejściu testów.
- **Releases**: Uruchomienie skryptu `deploy.ps1` wewnątrz kontenera CI dla celu "Production".

---

## Production Checklist

Nawet przy automatyzacji, sprawdź manualnie:

- [ ] Czy `scripts/deploy.ps1` ma dostęp do kluczy produkcyjnych?
- [ ] Czy migracje bazy danych są bezpieczne (brak utraty danych)?
- [ ] Czy backup został wykonany PRZED uruchomieniem skryptu?

---

> 📅 **Ostatnia aktualizacja:** 2026-01-14
