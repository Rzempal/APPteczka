# 📏 Standardy Kodu

> **Powiązane:** [Architektura](architecture.md) | [Model Danych](database.md)

---

## Wersjonowanie

### Strategia Wersjonowania

### Format

```
versionName: Major.Minor.Timestamp
versionCode: Timestamp (tylko liczba)
```

### Składniki

| Pole | Wartość | Opis |
| --- | --- | --- |
| `Major` | 0 | Faza rozwoju (1 = beta) |
| `Minor` | 1 | Funkcjonalna (rośnie przy nowych funkcjach) |
| `Timestamp` | `yyDDDHHmm` | yy=rok, DDD=dzień roku, HH=godz, mm=min |

### Przykład (2025-12-31 14:52)

```
versionName: 0.1.253651452
versionCode: 253651452
APK: name_0.1.253651452.apk
```

### Commity Git

Format opisu commita:

```text
#[numer] [opis zmian]
```

| Przykład | Opis |
| --- | --- | --- |
| `#1 Inicjalizacja projektu` | Pierwszy commit |
| `#2 Dodano FilterPanel` | Drugi commit |
| `#15 Fix: walidacja formularza` | Piętnasty commit |

**zawsze sprawdzaj liczbe commitow `git rev-list --count HEAD`**
---

## Komentarze

### Kiedy komentować

| ✅ Komentuj | ❌ Nie komentuj |
| --- | --- |
| Sekcje strony (header, nav, main, footer) | Oczywisty kod |
| Kluczowe funkcje biznesowe | Gettery/settery |
| Złożone algorytmy | Standardowe operacje |
| Decyzje architektoniczne ("dlaczego") | Co robi linia kodu |

### Przykłady

```tsx
// === SEKCJA: Hero z animowanym licznikiem ===

/**
 * Oblicza dopasowanie projektu do działki.
 * Uwzględnia wymiary, topografię i wymagania MPZP.
 */
function calculateProjectMatch(project, plot) { ... }
```

---

## Czysty Kod

### Funkcje

| Reguła | Opis |
| --- | --- |
| Max 50 linii | Podziel większe funkcje na mniejsze |
| Jedna odpowiedzialność | Funkcja robi jedną rzecz dobrze |
| Opisowe nazwy | Nazwa mówi CO robi, nie JAK |

### Nazewnictwo

| Język | Konwencja | Przykład |
| --- | --- | --- |
| JavaScript/TypeScript | `camelCase` | `calculateProjectMatch` |
| Python | `snake_case` | `calculate_project_match` |
| CSS (klasy) | `kebab-case` | `project-card-header` |
| Stałe | `SCREAMING_SNAKE_CASE` | `MAX_PROJECTS_PER_PAGE` |

### Zasady

| Zasada | Opis |
| --- | --- |
| **DRY** | Don't Repeat Yourself - wyciągaj powtarzający się kod |
| **KISS** | Keep It Simple - prostota > skomplikowane rozwiązania |
| **YAGNI** | You Aren't Gonna Need It - nie implementuj "na zapas" |

---

## Struktura Plików

### Frontend (Next.js)

```text
src/
├── app/                # Strony (App Router)
├── components/
│   ├── layout/         # Header, Footer
│   ├── ui/             # Bazowe komponenty (Button, Input)
│   └── [feature]/      # Komponenty per funkcjonalność
├── lib/
│   ├── api.ts          # Klient API
│   ├── types.ts        # Typy TypeScript
│   └── utils.ts        # Funkcje pomocnicze
└── contexts/           # React Contexts
```

### Backend (Django)

```text
apps/
└── [app_name]/
    ├── models.py       # Modele ORM
    ├── views.py        # ViewSety API
    ├── serializers.py  # Serializery DRF
    ├── urls.py         # Routing
    └── tests.py        # Testy
```

---

## TypeScript

### Typy

| Preferuj | Unikaj |
| --- | --- |
| `interface` dla obiektów | `any` |
| `type` dla unii/aliasów | `as` casting (chyba że konieczne) |
| Explicit return types | Implicit types w publicznym API |

### Przykład

```typescript
// ✅ Dobrze
interface ProjectCardProps {
  project: HouseProject;
  onSelect: (id: string) => void;
}

// ❌ Źle
const ProjectCard = (props: any) => { ... }
```

---

> 📅 **Ostatnia aktualizacja:** 2026-01-14
