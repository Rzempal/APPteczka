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
      "tagi": ["tag1", "tag2"]
    }
  ]
}
\`\`\`

## Zasady treści

- Język prosty, niemedyczny (np. „lek przeciwbólowy").
- Nie podawaj dawkowania ani ostrzeżeń.
- Na końcu opisu zawsze dodaj: **„Stosować zgodnie z ulotką."**
- Leki złożone traktuj jako jedną pozycję.

## Dozwolone tagi (kontrolowana lista)

ból, gorączka, kaszel, katar, ból gardła, ból głowy, ból mięśni,
biegunka, nudności, wymioty, alergia, zgaga,
infekcja wirusowa, infekcja bakteryjna, przeziębienie, grypa,
przeciwbólowy, przeciwgorączkowy, przeciwzapalny,
przeciwhistaminowy, przeciwkaszlowy, wykrztuśny,
przeciwwymiotny, przeciwbiegunkowy,
dla dorosłych, dla dzieci

## Ograniczenia

- Brak porad medycznych.
- Brak sugerowania zamienników.
- Brak ocen skuteczności.

Celem jest wyłącznie **porządkowanie informacji do prywatnej bazy leków użytkownika**.`;
}

/**
 * Generuje prompt do wyszukiwania informacji w ulotkach leków (rola: asystent wyszukiwania)
 * UWAGA: Prompt NIE pełni roli doradczej/lekarskiej - tylko wyszukuje i cytuje ulotki
 */
export function generateAnalysisPrompt(medicines: Medicine[], symptoms: string[], additionalNotes?: string): string {
  const medicineNames = medicines
    .map(m => m.nazwa || 'Nieznany lek')
    .join(', ');

  const symptomsList = symptoms.join(', ');

  const notesSection = additionalNotes?.trim()
    ? `\n\n## Dodatkowe informacje:\n${additionalNotes.trim()}`
    : '';

  return `# Wyszukiwanie w ulotkach leków

## Rola
Działaj jako asystent wyszukujący informacje w dokumentacji leków (Charakterystyka Produktu Leczniczego / ulotki). 
NIE jesteś lekarzem. NIE udzielasz porad medycznych. NIE oceniasz skuteczności klinicznej.

## Słowa kluczowe do wyszukania:
${symptomsList}${notesSection}

## Lista leków do przeszukania:
${medicineNames}

## Zadanie (format: WYSZUKIWARKA / BIBLIOTEKARZ)

1. **Dopasowanie słów kluczowych** – Wyszukaj w treści ulotek (ChPL) leków z powyższej listy te, które w sekcji "Wskazania do stosowania" zawierają wymienione słowa kluczowe (objawy lub pokrewne terminy).

2. **Cytowanie źródła** – Dla każdego dopasowania zacytuj fragment ulotki, np.:
   > "Lek X – Wskazania: stosowany w leczeniu [objaw]..." (źródło: ulotka producenta)

3. **Brak dopasowania** – Jeśli żaden lek z listy nie zawiera w ulotce wymienionych słów kluczowych, napisz: "Brak dopasowań w ulotkach dla podanych słów kluczowych."

4. **Przypomnienie dla użytkownika** – Na końcu zawsze dodaj:
   > ⚠️ To jest wyszukiwarka informacji z ulotek, NIE porada medyczna. Przed użyciem leku przeczytaj pełną ulotkę i skonsultuj się z lekarzem lub farmaceutą.

## Ograniczenia (BEZWZGLĘDNE)
- NIE oceniaj, czy lek jest odpowiedni dla użytkownika
- NIE sugeruj dawkowania
- NIE analizuj interakcji między lekami
- NIE stawiaj diagnoz
- NIE wcielaj się w rolę lekarza ani farmaceuty`
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
