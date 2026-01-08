// src/lib/prompts.ts
// Generatory promptów do wklejenia w ChatGPT/Claude/Gemini

import type { Medicine } from './types';

/**
 * Generuje prompt do rozpoznawania leków ze zdjęcia
 */
export function generateImportPrompt(): string {
  return `# Prompt – Rozpoznawanie leków ze zdjęcia (Import JSON)

## Rola
Jesteś asystentem farmacji pomagającym użytkownikowi prowadzić prywatną bazę leków (domową apteczkę). Użytkownik nie ma wiedzy farmaceutycznej.

## Wejście
Użytkownik przesyła zdjęcie opakowania lub opakowań leków.
Na jednym zdjęciu może znajdować się jeden lub kilka różnych leków.

## Zadanie

1. Przeanalizuj obraz i rozpoznaj **nazwy leków widoczne na opakowaniach**.
2. Jeśli na zdjęciu jest więcej niż jeden lek, zwróć **osobny obiekt dla każdego**.
3. **Zgadywanie jest zabronione.**

Jeżeli:
- nazwa leku jest nieczytelna,
- opakowanie jest częściowo zasłonięte,
- nie masz 100% pewności,

**zatrzymaj generowanie danych** i zwróć obiekt decyzyjny:

\`\`\`json
{
  "status": "niepewne_rozpoznanie",
  "opcje": {
    "A": "Poproś o lepsze zdjęcie",
    "B": "Poproś użytkownika o podanie nazwy leku",
    "C": "Zostaw nazwę pustą"
  }
}
\`\`\`

Nie zgaduj. Nie proponuj nazw.

## Format wyjścia (OBOWIĄZKOWY)

Zwróć **wyłącznie poprawny JSON**, bez dodatkowego tekstu.

\`\`\`json
{
  "leki": [
    {
      "nazwa": "string | null",
      "opis": "string",
      "wskazania": ["string", "string"],
      "tagi": ["tag1", "tag2"],
      "terminWaznosci": "string | null"
    }
  ]
}
\`\`\`

### Pole terminWaznosci

- Jeśli na opakowaniu widoczna jest data ważności (np. "EXP 03/2026", "Ważny do: 2026-03", "03.2026"), zwróć ją w formacie **YYYY-MM-DD** (ostatni dzień miesiąca, np. "2026-03-31").
- Jeśli data jest nieczytelna lub niewidoczna, zwróć **null**.
- Typowe formaty dat na opakowaniach: MM/YYYY, MM.YYYY, YYYY-MM, EXP MM/YY.

## Zasady treści

- Język prosty, niemedyczny (np. „lek przeciwbólowy").
- Nie podawaj dawkowania ani ostrzeżeń.
- Na końcu opisu zawsze dodaj: **„Stosować zgodnie z ulotką."**
- Leki złożone traktuj jako jedną pozycję.

## Dozwolone tagi (kontrolowana lista)

### Klasyfikacja

#### Rodzaj leku
bez recepty, na receptę, suplement, wyrób medyczny

#### Grupa docelowa
dla dorosłych, dla dzieci, dla kobiet w ciąży, dla niemowląt

#### Typ infekcji
grypa, infekcja bakteryjna, infekcja grzybicza, infekcja wirusowa, przeziębienie

### Objawy i działanie

#### Ból
ból, ból gardła, ból głowy, ból menstruacyjny, ból mięśni, ból ucha, mięśnie i stawy, przeciwbólowy

#### Układ pokarmowy
biegunka, kolka, nudności, przeczyszczający, przeciwbiegunkowy, przeciwwymiotny, układ pokarmowy, wzdęcia, wymioty, zaparcia, zgaga

#### Układ oddechowy
duszność, gorączka, kaszel, katar, nos, przeciwgorączkowy, przeciwkaszlowy, układ oddechowy, wykrztuśny

#### Skóra i alergia
alergia, nawilżający, oparzenie, przeciwhistaminowy, przeciwświądowy, rana, skóra, sucha skóra, suche oczy, świąd, ukąszenie, wysypka

#### Inne
afty, antybiotyk, bezsenność, choroba lokomocyjna, jama ustna, odkażający, probiotyk, przeciwzapalny, rozkurczowy, steryd, stres, układ nerwowy, uspokajający, ząbkowanie

## Ograniczenia

- Brak porad medycznych.
- Brak sugerowania zamienników.
- Brak ocen skuteczności.

Celem jest wyłącznie **porządkowanie informacji do prywatnej bazy leków użytkownika**.`;
}

/**
 * Generuje prompt do rozpoznawania leku po wpisanej nazwie
 */
export function generateNameLookupPrompt(name: string): string {
  return `# Prompt – Rozpoznawanie leku po nazwie

## Rola
Jesteś asystentem farmacji pomagającym użytkownikowi prowadzić prywatną bazę leków (domową apteczkę). Użytkownik nie ma wiedzy farmaceutycznej.

## Wejście
Użytkownik wpisał nazwę: "${name}"

## Zadanie

1. Sprawdź czy wpisana nazwa odpowiada jednemu z typów: **lek OTC, lek na receptę, suplement diety, wyrób medyczny**.
2. Jeśli rozpoznajesz produkt, uzupełnij informacje o nim.
3. Dozwolone są literówki i skróty - spróbuj rozpoznać zamiar użytkownika.
4. **Nie zgaduj** – jeśli nazwa jest całkowicie nieznana, zwróć status "nie_rozpoznano".

## Format wyjścia (OBOWIĄZKOWY)

### Gdy rozpoznano produkt:

\`\`\`json
{
  "status": "rozpoznano",
  "lek": {
    "nazwa": "Poprawna nazwa produktu",
    "opis": "Krótki opis działania. Stosować zgodnie z ulotką.",
    "wskazania": ["wskazanie1", "wskazanie2"],
    "tagi": ["tag1", "tag2"]
  }
}
\`\`\`

### Gdy nie rozpoznano:

\`\`\`json
{
  "status": "nie_rozpoznano",
  "reason": "Nie znaleziono produktu o podanej nazwie w bazie leków, suplementów ani wyrobów medycznych."
}
\`\`\`

## Zasady treści

- Język prosty, niemedyczny (np. „lek przeciwbólowy").
- Nie podawaj dawkowania ani ostrzeżeń.
- Na końcu opisu zawsze dodaj: **„Stosować zgodnie z ulotką."**

## Dozwolone tagi (kontrolowana lista)

### Klasyfikacja

#### Rodzaj leku
bez recepty, na receptę, suplement, wyrób medyczny

#### Grupa docelowa
dla dorosłych, dla dzieci, dla kobiet w ciąży, dla niemowląt

#### Typ infekcji
grypa, infekcja bakteryjna, infekcja grzybicza, infekcja wirusowa, przeziębienie

### Objawy i działanie

#### Ból
ból, ból gardła, ból głowy, ból menstruacyjny, ból mięśni, ból ucha, mięśnie i stawy, przeciwbólowy

#### Układ pokarmowy
biegunka, kolka, nudności, przeczyszczający, przeciwbiegunkowy, przeciwwymiotny, układ pokarmowy, wzdęcia, wymioty, zaparcia, zgaga

#### Układ oddechowy
duszność, gorączka, kaszel, katar, nos, przeciwgorączkowy, przeciwkaszlowy, układ oddechowy, wykrztuśny

#### Skóra i alergia
alergia, nawilżający, oparzenie, przeciwhistaminowy, przeciwświądowy, rana, skóra, sucha skóra, suche oczy, świąd, ukąszenie, wysypka

#### Inne
afty, antybiotyk, bezsenność, choroba lokomocyjna, jama ustna, odkażający, probiotyk, przeciwzapalny, rozkurczowy, steryd, stres, układ nerwowy, uspokajający, ząbkowanie

## Ograniczenia

- Brak porad medycznych.
- Brak sugerowania zamienników.
- Brak ocen skuteczności.

Celem jest wyłącznie **porządkowanie informacji do prywatnej bazy leków użytkownika**.`;
}

/**
 * Generuje listę nazw leków oddzielonych przecinkami
 * Do kopiowania i użycia zewnętrznego
 */
export function generateMedicineList(medicines: Medicine[]): string {
  return medicines
    .map(m => m.nazwa || 'Nieznany lek')
    .join(', ');
}

/**
 * Kopiuje tekst do schowka
 */
export async function copyToClipboard(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    return false;
  }
}

