# 📊 Model Danych (database.md)

<!-- 
  Alternatywne nazwy dla tego dokumentu zgodne ze standardami: 
  - schema.md 
  - data_model.md 
-->

> **Powiązane:** [Architektura](architecture.md) | [Bezpieczeństwo](security.md)

---

## Diagram ERD

*(Tu wklej link do diagramu Mermaid lub obrazu z `docs/assets/erd.png`)*

---

## Główne Encje

| Encja | Opis | Przechowywanie |
| --- | --- | --- |
| **User** | Dane użytkownika i role | PostgreSQL |
| **Project** | Metadane projektu | PostgreSQL |
| **ProjectIndex** | Dane do szybkiego wyszukiwania | Elasticsearch |

---

## Standardy Danych

### Migracje

- Każda zmiana schematu MUSI mieć migrację.
- Migracje muszą być odwracalne (`down` step).

### Indeksowanie (Elasticsearch)

- Synchronizacja danych zachodzi asynchronicznie przez Celery/RabbitMQ.

---

## Polityka Backupów

- **Daily**: Pełny dump bazy danych (zatrzymanie 30 dni).
- **Point-in-Time Recovery**: Logi transakcyjne (wal-g dla Postgres).

---

> 📅 **Ostatnia aktualizacja:** 2026-01-14
