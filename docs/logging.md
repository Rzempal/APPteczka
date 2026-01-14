# 📝 System Logowania

> **Powiązane:** [Architektura](architecture.md) | [Wdrożenie](deployment.md)

---

## 📋 Przegląd

Dokument opisuje standardy i mechanizmy logowania w aplikacji APPteczka.

---

## Strategia Logowania

### Mobile (Flutter)

- **Produkcja**: Używamy wbudowanego loggera z filtrowaniem poziomów (tylko Error/Warning).
- **Development**: Pełne logi konsoli.

### Web (Next.js)

- Logowanie po stronie klienta (browser console).
- Logi Vercel dla API Routes.

---

## Poziomy Logów

| Poziom | Zastosowanie |
| --- | --- |
| **DEBUG** | Informacje techniczne dla dewelopera |
| **INFO** | Istotne zdarzenia biznesowe (np. pomyślny import) |
| **WARN** | Problemy niekrytyczne (np. brak opisu leku w AI) |
| **ERROR** | Błędy uniemożliwiające działanie (np. błąd bazy danych) |

---

## Monitoring

- **Vercel Analytics**: Podstawowe statystyki ruchu.
- **Własne Logi**: Skrypt deploymentu loguje przebieg wysyłki APK do `deploy_log.md` (jeśli skonfigurowano).

---

> 📅 **Ostatnia aktualizacja:** 2026-01-14
