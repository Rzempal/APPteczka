# Apteczka AI – Baza projektu aplikacji

## Cel projektu
Celem projektu jest stworzenie aplikacji, która umożliwia użytkownikowi **zarządzanie własną domową apteczką** oraz **bezpieczną analizę posiadanych leków przy wsparciu asystenta AI**.

Projekt jest podzielony na dwie fazy:
- **Faza 1:** Aplikacja webowa
- **Faza 2:** Aplikacja mobilna na Android

Aplikacja **nie zastępuje lekarza** i **nie udziela porad medycznych** – jej zadaniem jest porządkowanie informacji oraz wspieranie świadomych decyzji użytkownika.

---

## Główne założenia funkcjonalne

### 1. Zarządzanie apteczką
Użytkownik może:
- importować listy leków wygenerowane przez asystenta AI (JSON / YAML / Markdown),
- wielokrotnie powiększać apteczkę poprzez kolejne importy,
- usuwać pojedyncze leki z listy,
- dodawać i edytować **termin przydatności do użycia** dla każdego leku,
- przeglądać apteczkę w czytelnej, listowej formie.

### 2. Prezentacja i filtrowanie
Aplikacja:
- prezentuje leki w ustrukturyzowany sposób (karty / tabela),
- umożliwia filtrowanie po:
  - objawach (tagi),
  - działaniu leku,
  - typie infekcji,
  - grupie użytkowników (dzieci / dorośli),
  - terminie ważności (np. przeterminowane / bliskie terminu).

---

## Integracja z asystentem AI

### 3. Prompt: rozpoznawanie leków ze zdjęcia
Aplikacja udostępnia użytkownikowi gotowy **prompt dla asystenta AI**, który:
- analizuje zdjęcie opakowań leków,
- rozpoznaje nazwy leków,
- generuje ustrukturyzowaną listę (zgodną ze schemami projektu),
- nie zgaduje w przypadku niepewności.

Wynik jest walidowany i importowany do bazy apteczki.

---

### 4. Prompt: analiza apteczki + objawy
Użytkownik może wygenerować drugi prompt dla asystenta AI, który zawiera:
- **pełną aktualną listę leków z apteczki**,
- **zdefiniowane przez użytkownika objawy**.

Celem promptu jest:
- analiza, które leki *wg ulotek* mogą być potencjalnie związane z podanymi objawami,
- wskazanie leków, które **nie pasują** do objawów,
- wygenerowanie sekcji:
  - „Brak odpowiednich leków – rozważ konsultację z lekarzem”,
  - „Objawy wymagające kontroli lekarskiej”.

Asystent:
- nie proponuje dawkowania,
- nie sugeruje konkretnych terapii,
- bazuje wyłącznie na informacjach z ulotek i opisów.

---

## Architektura – Faza 1 (Aplikacja webowa)

### Frontend
- Framework: React / Next.js
- UI:
  - lista leków (cards / table),
  - filtry oparte o tagi,
  - formularz edycji terminu ważności,
  - generator promptów (copy & paste).

### Backend / logika
- Lokalna baza danych użytkownika:
  - IndexedDB / SQLite (offline-first),
- Walidacja danych:
  - JSON Schema / YAML Schema,
- Brak kont użytkowników (na start),
- Brak przechowywania danych medycznych na serwerze.

---

## Architektura – Faza 2 (Android)

- Technologia:
  - Kotlin + Jetpack Compose **lub**
  - Flutter (współdzielona logika),
- Synchronizacja danych:
  - lokalna (offline),
  - opcjonalnie backup (eksport/import pliku),
- Kamera:
  - wykonywanie zdjęć opakowań bezpośrednio w aplikacji,
- Integracja z promptami AI jak w wersji web.

---

## Bezpieczeństwo i odpowiedzialność

- Brak zgadywania danych.
- Brak porad medycznych.
- Jasne komunikaty:
  - „To nie jest porada lekarska”,
  - „Skonsultuj się z lekarzem” w odpowiednich przypadkach.
- Dane użytkownika pozostają lokalne.

---

## Kolejne kroki implementacyjne

1. Model danych apteczki (lek + termin ważności).
2. UI listy + filtrów.
3. Import danych + walidacja.
4. Generator promptów (2 tryby).
5. MVP web (Faza 1).
6. Port na Android (Faza 2).

---

## Status
Dokument stanowi **punkt startowy projektu** i może być rozwijany iteracyjnie.
