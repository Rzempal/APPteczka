# 🗺️ Road Map – Pudełko na leki

> **Powiązane:** [Architektura](architecture.md) | [Model Danych](data_model.md)

---

## Wizja Produktu

**Pudełko na leki** to aplikacja do zarządzania domową apteczką z integracją AI. Umożliwia:

- Katalogowanie leków w domu
- Filtrowanie po objawach, działaniu, grupie użytkowników
- Śledzenie terminów ważności
- Analizę apteczki pod kątem objawów (z pomocą AI)

---

## Dwie ścieżki rozwoju

### 🅰️ Opcja A: Full Local (MVP)

**100% offline, dane lokalne, zero backendu**

| Platforma | Przechowywanie | AI | Koszt użytkownika |
|-----------|----------------|-----|-------------------|
| Web | localStorage / IndexedDB | Prompt copy-paste | Darmowe |
| Android | Hive / Isar | Prompt copy-paste | Darmowe |

### 🅱️ Opcja B: Backend Premium

**Konta użytkowników, sync, automatyczne AI**

| Funkcja | Opis | Koszt |
|---------|------|-------|
| Konta użytkowników | Logowanie Google/email | Darmowe |
| Synchronizacja | Cross-device sync (web ↔ mobile) | Darmowe |
| Gemini API | Automatyczne rozpoznawanie ze zdjęć | Premium (przyszłość) |

**Hosting testowy:** Vercel (frontend) + Railway/Supabase (backend)

---

## Status Faz

| Faza | Nazwa | Status |
|------|-------|--------|
| 0 | Dokumentacja i Schematy | ✅ Ukończona |
| 1 | MVP Web (Next.js) | ✅ Ukończona |
| 2 | MVP Mobile (Flutter) | ⏳ Następna |
| 3 | Backend + Sync (Opcja B) | 📋 Planowana |
| 4 | Gemini API (Opcja B) | 📋 Planowana |

---

## ✅ FAZA 0: Dokumentacja i Schematy

| Element | Status |
|---------|--------|
| Schema danych (JSON/YAML) | ✅ `docs/schema/` |
| Prompty dla AI | ✅ `docs/prompts/` |
| Kontrolowana lista tagów | ✅ `docs/example_input/` |

---

## ✅ FAZA 1: MVP Web (Next.js)

**Stack:** Next.js 16 + TypeScript + Tailwind CSS 4

| Funkcja | Status |
|---------|--------|
| Model danych TypeScript | ✅ |
| Lista leków z kartami | ✅ |
| Filtrowanie (tagi, terminy) | ✅ |
| Import JSON z walidacją Zod | ✅ |
| Edycja terminu ważności | ✅ |
| Alerty o przeterminowaniu | ✅ |
| Generator promptów AI | ✅ |
| Eksport JSON + kopiowanie | ✅ |
| **Eksport do PDF** | ✅ |
| **Sortowanie (A-Z, termin)** | ✅ |
| **4-tabowa nawigacja** | ✅ |
| **Design neumorficzny** | ✅ |
| **Animacje scroll + button press** | ✅ |
| **Etykiety użytkownika (labels)** | ✅ |
| **Notatki użytkownika** | ✅ |
| **Kopiowanie listy leków** | ✅ |
| Persistencja localStorage | ✅ |

---

## ⏳ FAZA 2: MVP Mobile (Flutter)

**Cel:** Natywna aplikacja Android (offline-first, jak Opcja A)

| Element | Opis |
|---------|------|
| Framework | Flutter + Dart |
| Lokalna baza | Hive lub Isar |
| UI | Material Design 3 |
| Funkcje | Identyczne jak web MVP |
| Kamera | Skanowanie opakowań (z promptem) |
| Powiadomienia | Lokalne alerty o terminach |

---

## 📋 FAZA 3: Backend + Synchronizacja (Opcja B)

**Cel:** Opcjonalne konta i sync dla użytkowników premium

| Element | Technologia |
|---------|-------------|
| Hosting | Vercel (Next.js) + Railway/Supabase |
| Autentykacja | NextAuth.js (Google OAuth) |
| Baza danych | PostgreSQL (Supabase) |
| API | Next.js API Routes |
| Sync | Real-time z Supabase |

---

## 📋 FAZA 4: Gemini API (Opcja B)

**Cel:** Automatyczne rozpoznawanie leków bez kopiowania promptów

| Element | Opis |
|---------|------|
| Provider | Gemini 2.0 Flash (Vision) |
| Architektura | Backend proxy (nasz klucz API) |
| Limit | Rate limiting per user |
| Model biznesowy | Premium feature (przyszłość) |

---

> 📅 **Ostatnia aktualizacja:** 2025-12-25
