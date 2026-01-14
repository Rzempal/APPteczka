# 🔐 Bezpieczeństwo

> **Powiązane:** [Architektura](architecture.md) | [Model Danych](database.md)

---

## Strategia Bezpieczeństwa

### 1. Autentykacja i Autoryzacja

- Używamy JWT z krótkim czasem życia (Access Token) i Refresh Token.
- Role użytkowników (RBAC) definiowane na poziomie middleware.

### 2. Ochrona Danych

- Szyfrowanie wrażliwych danych w bazie (AES-256).
- Wszystkie połączenia przez HTTPS (TLS 1.3).
- Sanityzacja danych wejściowych (XSS, SQL Injection).

---

## Security Checklist (OWASP Top 10)

- [ ] **A01: Broken Access Control** - Czy deweloper ma dostęp tylko do tego, co niezbędne?
- [ ] **A02: Cryptographic Failures** - Czy hasła są hashowane (Argon2/BCrypt)?
- [ ] **A03: Injection** - Czy używamy sparametryzowanych zapytań?
- [ ] **A05: Security Misconfiguration** - Czy wyłączono błędy debugowania na produkcji?
- [ ] **A07: Identification and Authentication Failures** - Czy mamy blokadę po X nieudanych logowaniach?

---

## Procedura Incydentu

W przypadku wykrycia luki:

1. Izolacja zagrożonego serwisu.
2. Analiza logów.
3. Patch & Deploy.
4. Powiadomienie użytkowników (jeśli dotyczy RODO/GDPR).

---

> 📅 **Ostatnia aktualizacja:** 2026-01-14
