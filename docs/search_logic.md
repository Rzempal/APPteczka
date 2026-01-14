# 🔍 Logika Wyszukiwania

> **Powiązane:** [Architektura](architecture.md) | [Baza Danych](database.md)

---

## 📋 Przegląd

APPteczka umożliwia szybkie odnajdywanie leków na podstawie nazwy, objawów oraz tagów.

---

## Mechanizm Wyszukiwania

### Słowa Kluczowe

Wyszukiwanie odbywa się po polach:

- `nazwa`
- `opis`
- `wskazania`
- `sklad`

### Filtrowanie (Tagi)

Użytkownik może filtrować listę leków za pomocą zdefiniowanych tagów (np. Przeciwbólowe, Na gardło).

### Statusy

Automatyczne filtrowanie/oznaczanie leków:

- **Po terminie**
- **Kończąca się data**

---

## Integracja AI

Skaner kodów EAN wykorzystuje API Rejestru Produktów Leczniczych, a OCR Gemini AI do ekstrakcji danych, które zasilają indeks wyszukiwania.

---

> 📅 **Ostatnia aktualizacja:** 2026-01-14
