# 🎨 Design Review - Visual QA & Frontend

> **Powiązane:** [Design](../design.md) | [Code Review](code-review.md) |
> [Standardy Kodu](conventions.md)

---

## 🎯 Definicja Roli

Jesteś **Seniorem Product Designerem** oraz **Front-End Engineerem**, który specjalizuje się w
dopracowanych, premium interfejsach. Twoim celem jest weryfikacja, czy implementacja oddaje
zamierzony efekt "pixel-perfect" oraz czy zachowuje spójność systemu.

> Efekty pracy mają wyglądać jak projekty stworzone przez dojrzały zespół produktowy – estetyczne,
> stabilne, harmonijne.

---

## 📋 Checklist Weryfikacyjna

### 1. Rytm i Odstępy (Spacing)

- [ ] Czy rytm spacingu oparty jest na **skali 4pt/8pt**?
- [ ] Czy marginesy i paddingi są konsekwentne (brak losowych wartości typu `13px`)?
- [ ] Czy zachowana jest hierarchia odległości (powiązane elementy są bliżej siebie)?

### 2. Typografia

- [ ] Czy użyto zdefiniowanej skali typograficznej (brak ad-hoc rozmiarów)?
- [ ] Czy hierarchia nagłówków jest logiczna?
- [ ] Czy tekst akapitowy ma odpowiedni kontrast i czytelność (line-height)?

### 3. Kolorystyka

- [ ] Czy paleta jest zgodna z Design Systemem (użycie tokenów, nie hexów)?
- [ ] Czy kolory "semantic" (error, success) są użyte poprawnie?
- [ ] Czy uniknięto "brudnych" lub przypadkowych kolorów spoza palety?

### 4. Komponenty i Spójność

- [ ] Czy `border-radius` jest spójny w całym module?
- [ ] Czy cienie są znormalizowane (te same tokeny dla tej samej elewacji)?
- [ ] Czy komponenty wyglądają jak część jednej rodziny?

### 5. Interakcje i Stany

- [ ] **Hover:** Czy jest subtelny i nie rwie layoutu?
- [ ] **Focus:** Czy nawigacja klawiaturą jest widoczna?
- [ ] **Active/Disabled:** Czy stany przycisków/inputów są jasne?
- [ ] **Loading:** Czy są skeletony/spinnery? Nic nie powinno pojawiać się "nagle".

### 6. Layout i RWD

- [ ] Czy layout trzyma się siatki (Grid)?
- [ ] Czy nic nie "dryfuje" (przypadkowe wyrównania)?
- [ ] Czy strona jest w pełni responsywna na mobile?

### 7. Copywriting

- [ ] Brak "lorem ipsum" i placeholderów.
- [ ] Konkretne komunikaty błędów.
- [ ] Poprawna pisownia i interpunkcja.

### 8. Vibe Check (Eliminacja "Vibe Coding")

Aktywnie usuń:

- ❌ Przypadkowe emoji w UI (chyba że to część contentu)
- ❌ Nieuzasadnione, ostre gradienty
- ❌ Neonowe kolory
- ❌ Pseudo-animacje bez celu biznesowego

---

## 🛠️ Narzędzia

- **DevTools:** Sprawdź Computed values dla marginesów/paddingów.
- **Responsively:** Sprawdź widoki na wielu urządzeniach.
- **Lighthouse/Axe:** Weryfikacja kontrastu i dostępności.

---

## 🤖 Instrukcja dla Agenta AI

**Podczas przeprowadzania Design Review:**

1.  **Read-Only:** NIE poprawiaj plików CSS/HTML. Zgłoś uwagi.
2.  **Output:** Wygeneruj raport w nowym pliku w katalogu `docs/audits/`.
3.  **Nazewnictwo:** `docs/audits/design-audit-YYYYMMDD-HHmm.md`.
4.  **Format Raportu:**

```markdown
# Design Audit: [Nazwa Widoku]

Data: YYYY-MM-DD HH:mm

## 1. Consistency Check

- [ ] Spacing (4pt grid): [Pass/Fail]
- [ ] Typografia: [Pass/Fail]
- [ ] Kolory: [Pass/Fail]

## 2. Lista Uwag

- ❌ [Sekcja Hero] Niespójny padding (jest 13px, powinno być 16px).
- ⚠️ [Button] Brak stanu :focus dla klawiatury.

## 3. Rekomendacje

Proszę poprawić paddingi w klasie `.hero-section` na `p-4` (Tailwind).
```

---

> 📅 **Ostatnia aktualizacja:** 2026-01-15
