# 📚 Przewodnik Dokumentacji

> **Powiązane:** [Architektura](architecture.md) | [Standardy Kodu](standards.md)

---

## Zasady Główne

### Single Source of Truth (SSOT)

Każda informacja powinna istnieć **w jednym miejscu**. Pozostałe dokumenty linkują do źródła.

| ❌ Źle | ✅ Dobrze |
|--------|-----------|
| Kopiuj tabele portów do wielu plików | Tabela portów tylko w `architecture.md`, inne linkują |
| Powtarzaj schemat ES w kilku miejscach | Schema w `data_model.md`, inne odwołują się |

### Cross-linking

Każdy dokument powinien mieć na górze sekcję **Powiązane:**

```markdown
> **Powiązane:** [Architektura](architecture.md) | [Model Danych](data_model.md)
```

Linki wewnątrz treści:

```markdown
Szczegóły: **[data_model.md](data_model.md)**
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
|-------|---------------|
| 🏛️ | Architektura |
| 📊 | Model danych |
| 🔍 | Logika biznesowa |
| 🔐 | Bezpieczeństwo |
| 📏 | Standardy |
| 🗺️ | Road map |
| 📚 | Przewodniki |
| 🛡️ | Disclaimers |

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
|-----------------|------------|
| Nowy endpoint API | `architecture.md` |
| Nowy model/encja | `data_model.md` |
| Nowy filtr w konfiguratorze | `search_logic.md` |
| Zmiana uwierzytelniania | `security.md` |
| Ukończenie zadania | `road_map.md` |
| Nowa konwencja | `standards.md` |
| Zmiana instalacji | `README.md` |

### Zmiany dokumentacji → Dokumentacja

| Zmiana | Aktualizuj |
|--------|------------|
| Nowy plik w `docs/` | `README.md` (tabela dokumentacji) |
| Nowy plik w `docs/` | `architecture.md` (tabela dokumentacji) |
| Przeniesienie sekcji | Wszystkie linki do tej sekcji |

---

## Struktura Katalogu `docs/`

```text
docs/
├── architecture.md         # Przegląd systemu, warstwy
├── data_model.md           # ERD, encje, Elasticsearch
├── search_logic.md         # Guided Selling, konfigurator
├── security.md             # GDPR, PCI DSS
├── disclaimers.md          # Wyłączenia odpowiedzialności (Medical vs Inventory)
├── standards.md            # Konwencje kodu
├── documentation_guide.md  # Ten plik
└── road_map.md             # Plan rozwoju
```

---

## Checklist przed Commit

```markdown
- [ ] Czy zmiana wpływa na architekturę? → `architecture.md`
- [ ] Czy zmiana dotyczy modelu danych? → `data_model.md`
- [ ] Czy zmiana dotyczy wyszukiwania? → `search_logic.md`
- [ ] Czy ukończono zadanie z road mapy? → `road_map.md`
- [ ] Czy dodano nowy plik doc? → `README.md`
- [ ] Czy cross-linki są aktualne?
```

---

> 📅 **Ostatnia aktualizacja:** 2026-01-07
