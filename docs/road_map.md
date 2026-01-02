# 🗺️ Road Map – Karton (Pudełko na leki)

> **Powiązane:** [Architektura](architecture.md) | [Model Danych](data_model.md) | [Feature Lists](feature-lists.md)

---

## Wizja Produktu

**Karton** to aplikacja mobilna do zarządzania domową apteczką z integracją AI. Umożliwia:

- 📦 Katalogowanie leków w domu
- 🔍 Filtrowanie po objawach, działaniu, grupie użytkowników
- ⏰ Śledzenie terminów ważności
- 📷 Automatyczne rozpoznawanie leków ze zdjęć (Gemini AI)
- 🏷️ Własne etykiety i notatki

---

## Strategia Rozwoju

**Platforma docelowa:** Android (Google Play Store)  
**Backend:** Vercel (API-only) – Gemini OCR proxy  
**Model:** Darmowa aplikacja, offline-first

```
┌─────────────────────────────────────────────────────┐
│                   ARCHITEKTURA                      │
├─────────────────────────────────────────────────────┤
│                                                     │
│   Google Play ──► Flutter APK (offline-first)      │
│                        │                           │
│                        ▼                           │
│               Vercel API (proxy)                   │
│               ├── /api/gemini-ocr                  │
│               └── /api/pdf-proxy                   │
│                        │                           │
│                        ▼                           │
│               Gemini API (Google)                  │
│                                                     │
│   Landing Page ──► karton.michalrapala.app         │
│               ├── Hero + Features                  │
│               ├── Screenshots                      │
│               └── Privacy Policy                   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Status Faz

| Faza | Nazwa | Status |
|------|-------|--------|
| 0 | Dokumentacja i Schematy | ✅ Ukończona |
| 1 | MVP Web (Next.js) | ✅ Ukończona |
| 2 | MVP Mobile (Flutter) | ✅ Ukończona |
| 3 | Gemini API Integration | ✅ Ukończona |
| 4 | Web → Landing Page + API | 📋 Planowana |
| 5 | Google Play Store Release | 📋 Planowana |
| 6 | Backend + Sync (opcjonalne) | 🔮 Przyszłość |

---

## ✅ FAZA 0-3: Zakończone

<details>
<summary>Szczegóły ukończonych faz</summary>

### Faza 0: Dokumentacja

- Schema danych (JSON/YAML)
- Prompty dla AI
- Kontrolowana lista tagów

### Faza 1: MVP Web (Next.js)

- Pełna aplikacja webowa z design neumorficznym
- Import/eksport JSON, PDF
- Etykiety, notatki, filtrowanie

### Faza 2: MVP Mobile (Flutter)

- Natywna aplikacja Android
- Hive local storage
- Design neumorficzny

### Faza 3: Gemini API

- Backend proxy na Vercel
- Automatyczne rozpoznawanie leków ze zdjęć
- Rate limiting

</details>

---

## 📋 FAZA 4: Web → Landing Page + API

**Cel:** Przekształcenie wersji webowej w stronę promocyjną + zachowanie API dla aplikacji mobilnej

### Do usunięcia

| Element | Ścieżka |
|---------|---------|
| Stare UI aplikacji | `apps/web/src/app/page.tsx` |
| Strona dodawania | `apps/web/src/app/dodaj/` |
| Strona backup | `apps/web/src/app/backup/` |
| Komponenty UI | `apps/web/src/components/*` |

### Do zachowania

| Element | Ścieżka |
|---------|---------|
| Gemini OCR API | `apps/web/src/app/api/gemini-ocr/` |
| PDF Proxy API | `apps/web/src/app/api/pdf-proxy/` |
| Lib (prompts, gemini) | `apps/web/src/lib/` |

### Do stworzenia

| Element | Opis |
|---------|------|
| Landing Page | Hero, features, screenshots, CTA do Play Store |
| Privacy Policy | Wymagane przez Google Play |
| SEO + Open Graph | Meta tagi dla wyszukiwarek i social |

---

## 📋 FAZA 5: Google Play Store Release

### Checklist Wymagań

#### Prawne

| Element | Status |
|---------|--------|
| Privacy Policy URL | ⬜ |
| Target Age Group (nie dla dzieci <13) | ⬜ |
| Data Safety Form | ⬜ |

#### Graficzne

| Element | Wymiary | Status |
|---------|---------|--------|
| App Icon | 512×512 | ✅ |
| Feature Graphic | 1024×500 | ⬜ |
| Screenshots (min. 2) | 1080×1920 | ⬜ |

#### Tekstowe

| Element | Limit | Status |
|---------|-------|--------|
| App Name | 30 znaków | ✅ "Karton" |
| Short Description | 80 znaków | ⬜ |
| Full Description | 4000 znaków | ⬜ |
| Contact Email | - | ⬜ |

#### Techniczne

| Element | Status |
|---------|--------|
| App Bundle (.aab) | ⬜ |
| Signing Keystore | ⬜ |
| Content Rating (IARC) | ⬜ |

#### Opłaty

| Element | Koszt | Status |
|---------|-------|--------|
| Google Play Developer | $25 jednorazowo | ⬜ |

---

## � FAZA 6: Backend + Sync (Przyszłość)

**Cel:** Opcjonalne konta użytkowników i synchronizacja cross-device

> [!NOTE]
> Ta faza jest opcjonalna i planowana na przyszłość, gdy baza użytkowników wzrośnie.

| Element | Technologia |
|---------|-------------|
| Autentykacja | Firebase Auth / Supabase |
| Baza danych | Firestore / PostgreSQL |
| Sync | Real-time synchronization |

---

> 📅 **Ostatnia aktualizacja:** 2026-01-02
