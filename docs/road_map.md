# 🗺️ Road Map – APPteczka

> **Powiązane:** [Architektura](architecture.md) | [Model Danych](data_model.md)

---

## Wizja Produktu

**APPteczka** to aplikacja do zarządzania domową apteczką z integracją AI. Umożliwia:

- Katalogowanie leków w domu
- Filtrowanie po objawach, działaniu, grupie użytkowników
- Śledzenie terminów ważności
- Analizę apteczki pod kątem objawów (z pomocą AI)

### Problem

Użytkownicy nie wiedzą, jakie leki mają w domu, kiedy się przeterminują i które pasują do aktualnych objawów.

### Rozwiązanie

Aplikacja webowa (później mobilna) z:

- Importem leków przez AI (zdjęcie → lista)
- Filtrowaniem i wyszukiwaniem
- Alertami o przeterminowanych lekach

---

## Status

| Faza | Nazwa | Status |
|------|-------|--------|
| 0 | Dokumentacja i Schematy | ✅ Ukończona |
| 1 | MVP Web (Next.js) | ⏳ Planowana |
| 2 | Backend + Synchronizacja | ⏳ Planowana |
| 3 | Integracja AI API | ⏳ Planowana |
| 4 | Aplikacja Mobile (Flutter) | ⏳ Planowana |

---

## FAZA 0: Dokumentacja i Schematy ✅

**Cel:** Przygotowanie fundamentów projektu.

| Element | Status |
|---------|--------|
| Schema danych (JSON/YAML) | ✅ `docs/schema/` |
| Prompty dla AI | ✅ `docs/prompts/` |
| Kontrolowana lista tagów | ✅ `docs/example_input/` |
| Przykładowe dane | ✅ `docs/example_input/` |

---

## FAZA 1: MVP Web (Next.js) ⏳

**Cel:** Działająca aplikacja webowa z podstawowymi funkcjami.

| Element | Opis |
|---------|------|
| Model danych | Implementacja encji `Lek` w TypeScript |
| Przechowywanie | localStorage (offline-first) |
| UI: Lista leków | Karty/tabela z podstawowymi informacjami |
| UI: Filtry | Po tagach, objawach, terminie ważności |
| Import danych | Walidacja JSON/YAML/Markdown |
| Generator promptów | Copy-paste do ChatGPT/Claude/Gemini |
| Termin ważności | Edycja daty, alerty o przeterminowaniu |

**Kamień milowy:** Użytkownik może zaimportować leki i filtrować apteczkę.

---

## FAZA 2: Backend + Synchronizacja ⏳

**Cel:** Opcjonalne konto użytkownika i backup danych.

| Element | Opis |
|---------|------|
| API REST | Node.js + Express lub Next.js API Routes |
| Baza danych | SQLite (dev) → PostgreSQL (prod) lub serverless |
| Autentykacja | Opcjonalna (email + hasło lub OAuth) |
| Backup/Export | JSON export/import dla użytkowników bez konta |

**Kamień milowy:** Użytkownik może założyć konto i zsynchronizować dane między urządzeniami.

---

## FAZA 3: Integracja AI API ⏳

**Cel:** Automatyczne rozpoznawanie leków ze zdjęć.

| Element | Opis |
|---------|------|
| Provider | Gemini API (Vision) |
| Workflow | Upload zdjęcia → analiza → walidacja → import |
| Fallback | Ręczna weryfikacja przy niepewnym rozpoznaniu |

**Kamień milowy:** Użytkownik robi zdjęcie opakowań i leki są automatycznie dodawane.

---

## FAZA 4: Aplikacja Mobile (Flutter) ⏳

**Cel:** Natywna aplikacja na Android (i opcjonalnie iOS).

| Element | Opis |
|---------|------|
| Framework | Flutter |
| Lokalna baza | Hive lub Isar (offline-first) |
| Kamera | Skanowanie opakowań bezpośrednio w aplikacji |
| Synchronizacja | Opcjonalna z backendem z Fazy 2 |
| Powiadomienia | Alerty o przeterminowanych lekach |

**Kamień milowy:** Użytkownik zarządza apteczką z telefonu.

---

## Kolejność Implementacji (Faza 1)

```text
1. Model danych (TypeScript)
2. Komponent: MedicineCard
3. Komponent: MedicineList + Filters
4. Import: walidacja + parsowanie
5. Generator promptów
6. Termin ważności + alerty
7. Stylowanie + responsywność
```

---

> 📅 **Ostatnia aktualizacja:** 2025-12-22
> 🏗️ **Projekt:** APPteczka
