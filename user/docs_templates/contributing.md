# 📚 Przewodnik Dokumentacji

> **Powiązane:** [Architektura](architecture.md) | [Standardy Kodu](conventions.md)

---

## Zasady Główne

### Single Source of Truth (SSOT)

Każda informacja powinna istnieć **w jednym miejscu**. Pozostałe dokumenty linkują do źródła.

| ❌ Źle | ✅ Dobrze |
| --- | --- |
| Kopiuj tabele portów do wielu plików | Tabela portów tylko w `architecture.md`, inne linkują |
| Powtarzaj schemat ES w kilku miejscach | Schema w `database.md`, inne odwołują się |

### Cross-linking

Każdy dokument powinien mieć na górze sekcję **Powiązane:**

```markdown
> **Powiązane:** [Architektura](architecture.md) | [Model Danych](database.md)
```

Linki wewnątrz treści:

```markdown
Szczegóły: **[database.md](database.md)**
```

---

## Format Dokumentów

### Nagłówek

Każdy dokument zaczyna się od:

```markdown
# [Emoji] Tytuł

> **Powiązane:** [Link1](plik1.md) | [Link2](plik2.md)

---
```

### Emoji dla typów dokumentów

| Emoji | Typ dokumentu |
| --- | --- |
| 🏛️ | Architektura |
| 📊 | Model danych |
| 🔍 | Logika biznesowa |
| 🔐 | Bezpieczeństwo |
| 📏 | Standardy |
| 🗺️ | Road map |
| 🧠 | Lessons Learned |
| 📝 | System logowania |
| 📚 | Przewodniki |

### Spis treści

Dla dokumentów **>100 linii** dodaj spis treści:

```markdown
## 📋 Spis Treści

- [Sekcja 1](#sekcja-1)
- [Sekcja 2](#sekcja-2)
```

---

## Wersjonowanie Dokumentów

### Komentarz wersji

Na końcu każdego dokumentu:

```markdown
---

> 📅 **Ostatnia aktualizacja:** 2025-12-14
```

### Kiedy aktualizować datę

- Zmiana treści merytorycznej
- Dodanie nowej sekcji
- **Nie:** poprawki literówek, formatowania

---

## Triggery Aktualizacji

### Zmiany kodu → Dokumentacja

| Zmiana w kodzie | Aktualizuj |
| --- | --- |
| Nowy endpoint API | `architecture.md` |
| Nowy model/encja | `database.md` |
| Nowy filtr w konfiguratorze | `search-logic.md` |
| Zmiana uwierzytelniania | `security.md` |
| Ukończenie zadania | `roadmap.md` |
| Nowa konwencja | `conventions.md` |
| Zmiana instalacji | `README.md` |

### Zmiany dokumentacji → Dokumentacja

| Zmiana | Aktualizuj |
| --- | --- |
| Nowy plik w `docs/` | `README.md` (tabela dokumentacji) |
| Nowy plik w `docs/` | `architecture.md` (tabela dokumentacji) |
| Przeniesienie sekcji | Wszystkie linki do tej sekcji |

---

## Struktura Katalogu `docs/`

```text
docs/
├── architecture.md         # Przegląd systemu, warstwy
├── database.md             # ERD, encje, Elasticsearch
├── search-logic.md         # Guided Selling, konfigurator
├── security.md             # GDPR, PCI DSS, OWASP
├── conventions.md          # Konwencje kodu
├── testing.md              # Strategia TDD, standardy testów
├── deployment.md           # CI/CD, deployment checklist
├── lessons-learned.md      # Dziennik doświadczeń i wniosków
├── logging.md              # System logowania i monitoring
├── contributing.md         # Ten plik
└── roadmap.md              # Plan rozwoju
```

---

## Checklist przed Commit

```markdown
- [ ] Czy zmiana wpływa na architektura? → `architecture.md`
- [ ] Czy zmiana dotyczy modelu danych? → `database.md`
- [ ] Czy zmiana dotyczy testów? → `testing.md`
- [ ] Czy zmiana wpływa na bezpieczeństwo? → `security.md`
- [ ] Czy ukończono zadanie z roadmapy? → `roadmap.md`
- [ ] Czy dodano nowy plik doc? → `README.md`
- [ ] Czy cross-linki są aktualne?
```

---

> 📅 **Ostatnia aktualizacja:** 2025-12-14
