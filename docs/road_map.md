# 🗺️ Road Map - ArchiFlex 

> **Narzędzie do parametryzacji projektów domów (SaaS)**

---

## Wizja Produktu

**ArchiFlex** to interaktywne narzędzie pozwalające klientom dostosować gotowy projekt architektoniczny do ich indywidualnych potrzeb i ograniczeń działki.

### Problem

Klienci kupują gotowe projekty domów, które często wymagają kosztownej adaptacji do:

- Wymiarów i kształtu działki
- Wymagań Miejscowego Planu Zagospodarowania (MPZP)
- Indywidualnych preferencji (układ pomieszczeń, orientacja)

### Rozwiązanie

Platforma umożliwiająca **parametryzację projektu przed zakupem**:

- Edytor wymiarów (szerokość działki, kąt dachu, orientacja)
- Podgląd na żywo zmian w projekcie
- Walidacja zgodności z przepisami
- Dynamiczna wycena

---

## Cel Biznesowy

| Aspekt | ArchiKunszt | ArchiFlex |
|--------|-------------|-----------|
| **Model** | E-commerce (projekty "as-is") | SaaS (parametryzacja) |
| **Klient** | Szuka gotowego projektu | Chce dostosować projekt do działki |
| **Wartość** | Szybki zakup, niższa cena | Dopasowanie, mniej adaptacji |

---

## Status

| Faza | Nazwa | Status |
|------|-------|--------|
| 0 | Walidacja pomysłu (Mock) | ⏳ Planowana (w repo ArchiKunszt) |
| 1 | Parametryzator UI | ⏳ Planowana |
| 2 | Checkout i Płatności | ⏳ Planowana |
| 3 | Analityka i Optymalizacja | ⏳ Planowana |

---

## FAZA 0: Walidacja Pomysłu (Mock) ⏳

**Cel:** Zebranie emaili i walidacja zainteresowania przed pełną implementacją.

| Element | Opis |
|---------|------|
| Landing Page | Hero: "Parametryzuj projekt pod swoją działkę" |
| Mockup UI | Statyczna wizualizacja interfejsu |
| Email Capture | Formularz "Zostaw email - powiadomimy o starcie" |
| Metryki sukcesu | Liczba zapisanych emaili, konwersja z ArchiKunszt |

**Kamień milowy:** Zebranie 100+ emaili → decyzja o kontynuacji.

---

## FAZA 1: Parametryzator UI ⏳

**Cel:** Przekształcenie mocka w działające narzędzie.

| Element | Opis |
|---------|------|
| Edytor wymiarów | Suwaki/inputy: szerokość działki, kąt dachu, orientacja |
| Podgląd na żywo | Wizualizacja zmieniająca się przy edycji |
| Walidacja reguł | Sprawdzenie czy konfiguracja jest wykonalna |
| Deep-linking | URL z parametrami → link z ArchiKunszt z pre-loaded projektem |

---

## FAZA 2: Checkout i Płatności ⏳

**Cel:** Finalizacja procesu zakupowego dla sparametryzowanych projektów.

| Element | Opis |
|---------|------|
| Koszyk konfiguracji | Przechowuje wybraną konfigurację (JSON) |
| Podsumowanie | Przed płatnością pokazuje co kupuje |
| Płatności | PayU/P24 |
| Generowanie plików | Backend generuje PDF z parametrami klienta |
| Email z konfiguracją | Potwierdzenie + specyfikacja wybranych parametrów |

---

## FAZA 3: Analityka i Optymalizacja ⏳

**Cel:** Zrozumienie flow klienta między ArchiKunszt a ArchiFlex.

| Element | Opis |
|---------|------|
| UTM tagi | Na wszystkich linkach ArchiKunszt → ArchiFlex |
| Event tracking | GA4 events dla kluczowych akcji |
| Funnel analysis | Gdzie klienci "wypadają" |
| A/B testy | CTA, layouty, copy |

---

## Integracja z ArchiKunszt

```
ArchiKunszt.pl                     ArchiFlex
     │                                 │
     │ CTA: "Sparametryzuj projekt"    │
     ├────────────────────────────────→│
     │                                 │
     │ Deep-link z project_id          │
     │                                 │
     │←────────────────────────────────┤
     │ Powrót z linkiem do zakupu      │
     │                                 │
```

---

> 📅 **Ostatnia aktualizacja:** 2025-12-14  
> 🏗️ **Repozytorium:** (osobne - do utworzenia)
