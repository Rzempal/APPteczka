# System Tagów

Dokumentacja Master Listy tagów używanych w aplikacji APPteczka / Karton z lekami.

> **Ostatnia aktualizacja:** 2026-01-10

---

## Przegląd

Tagi służą do kategoryzacji leków, umożliwiając:

- **Filtrowanie** - szybkie wyszukiwanie leków po cechach
- **Auto-tagowanie** - Gemini AI automatycznie przypisuje tagi podczas skanowania
- **Organizację** - grupowanie leków w sensowne kategorie

---

## Struktura Kategorii

```
# Tagi
├── Klasyfikacja
│   ├── Rodzaj i postać leku
│   ├── Substancja czynna (dynamiczna - z API RPL)
│   ├── Grupa docelowa
│   └── Typ infekcji
├── Objawy i działanie
│   ├── Ból
│   ├── Układ pokarmowy
│   ├── Układ oddechowy
│   ├── Skóra i alergia
│   └── Inne
└── Moje (niestandardowe tagi użytkownika)
```

---

## Master Lista Tagów

### Klasyfikacja

#### Rodzaj i postać leku

| Tag | Opis |
|-----|------|
| `bez recepty` | Leki OTC dostępne bez recepty |
| `na receptę` | Leki Rx wymagające recepty |
| `suplement` | Suplementy diety |
| `wyrób medyczny` | Wyroby medyczne (testy, opatrunki) |
| `tabletki` | Tabletki, tabletki powlekane |
| `kapsułki` | Kapsułki twarde i miękkie |
| `syrop` | Syropy i roztwory doustne |
| `maść` | Maści, kremy, żele |
| `zastrzyki` | Roztwory do wstrzykiwań |
| `krople` | Krople do oczu, uszu, nosa |
| `aerozol` | Aerozole, spray |
| `czopki` | Czopki doodbytnicze |
| `plastry` | Plastry lecznicze |
| `proszek/zawiesina` | Proszki, zawiesiny, granulaty |

#### Substancja czynna (dynamiczna)

Tagi substancji czynnych są automatycznie generowane ze skanera kodów EAN (API RPL):

- Wyświetlane w filtrach tylko gdy występują w apteczce użytkownika
- Niemodyfikowalne przez użytkownika (readonly)
- Rozpoznawane po łacińskiej nomenklaturze (np. `Escitalopramum`, `Paracetamolum`)
- Wieloskładnikowe leki mają rozdzielone substancje (np. `Paracetamolum + Codeini phosphas`)

#### Grupa docelowa

| Tag | Opis |
|-----|------|
| `dla dorosłych` | Przeznaczone dla osób dorosłych |
| `dla dzieci` | Przeznaczone dla dzieci |
| `dla kobiet w ciąży` | Bezpieczne w ciąży |
| `dla niemowląt` | Przeznaczone dla niemowląt |

#### Typ infekcji

| Tag | Opis |
|-----|------|
| `grypa` | Leki na grypę |
| `infekcja bakteryjna` | Zakażenia bakteryjne |
| `infekcja grzybicza` | Zakażenia grzybicze |
| `infekcja wirusowa` | Zakażenia wirusowe |
| `przeziębienie` | Przeziębienie |

---

### Objawy i działanie

#### Ból

`ból`, `ból gardła`, `ból głowy`, `ból menstruacyjny`, `ból mięśni`, `ból ucha`, `mięśnie i stawy`, `przeciwbólowy`

#### Układ pokarmowy

`biegunka`, `kolka`, `nudności`, `przeczyszczający`, `przeciwbiegunkowy`, `przeciwwymiotny`, `układ pokarmowy`, `wzdęcia`, `wymioty`, `zaparcia`, `zgaga`

#### Układ oddechowy

`duszność`, `gorączka`, `kaszel`, `katar`, `nos`, `przeciwgorączkowy`, `przeciwkaszlowy`, `układ oddechowy`, `wykrztuśny`

#### Skóra i alergia

`alergia`, `nawilżający`, `oparzenie`, `przeciwhistaminowy`, `przeciwświądowy`, `rana`, `skóra`, `sucha skóra`, `suche oczy`, `świąd`, `ukąszenie`, `wysypka`

#### Inne

`afty`, `antybiotyk`, `bezsenność`, `choroba lokomocyjna`, `jama ustna`, `odkażający`, `probiotyk`, `przeciwzapalny`, `rozkurczowy`, `steryd`, `stres`, `układ nerwowy`, `uspokajający`, `ząbkowanie`

---

## Miejsca użycia

Master Lista jest zsynchronizowana w następujących miejscach:

| Plik | Platforma | Zastosowanie |
|------|-----------|--------------|
| [filters_sheet.dart](../apps/mobile/lib/widgets/filters_sheet.dart) | Mobile | Filtrowanie leków + dynamiczne substancje |
| [tag_selector_widget.dart](../apps/mobile/lib/widgets/tag_selector_widget.dart) | Mobile | Ręczne dodawanie leku |
| [barcode_scanner.dart](../apps/mobile/lib/widgets/barcode_scanner.dart) | Mobile | Auto-tagowanie ze skanera EAN |
| [types.ts](../apps/web/src/lib/types.ts) | Web | Definicja typów tagów |
| [prompts.ts](../apps/web/src/lib/prompts.ts) | Web | Prompt do auto-tagowania |
| [dual-ocr.ts](../apps/web/src/lib/dual-ocr.ts) | Web | Prompt dual OCR |

---

## Normalizacja tagów

Stare tagi z backupów są automatycznie normalizowane:

| Stary tag | → Nowy tag |
|-----------|------------|
| `lek OTC` / `OTC` | `bez recepty` |
| `lek Rx` / `Rx` | `na receptę` |
| `test diagnostyczny` | `wyrób medyczny` |
| `kosmetyk leczniczy` | `nawilżający` |

Deprecated tagi (usuwane): `oczy`, `uszy`, `dla seniorów`, `układ krążenia`, `układ moczowy`

Plik: [tag_normalization.dart](file:///c:/Users/rzemp/GitHub/APPteczka/apps/mobile/lib/utils/tag_normalization.dart)

---

## Implikacje tagów (auto-rozszerzanie)

Przy auto-tagowaniu, niektóre tagi automatycznie dodają powiązane:

```
ból głowy → ból, przeciwbólowy
ból gardła → ból, przeciwbólowy
gorączka → przeciwgorączkowy
kaszel → przeciwkaszlowy lub wykrztuśny
antybiotyk → infekcja bakteryjna, na receptę
steryd → przeciwzapalny, na receptę
```

Pełna lista: [tag_normalization.dart](file:///c:/Users/rzemp/GitHub/APPteczka/apps/mobile/lib/utils/tag_normalization.dart#L35-L55)

---

## Sekcja "Moje"

Tagi spoza Master Listy są wyświetlane w sekcji "Moje":

- Są to niestandardowe tagi dodane przez użytkownika
- Nie są usuwane automatycznie
- Można je zarządzać w: Zarządzaj → Moje tagi
