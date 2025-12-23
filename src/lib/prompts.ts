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
 * Generuje prompt do analizy apteczki pod kątem objawów (rola: lekarz internista)
 */
export function generateAnalysisPrompt(medicines: Medicine[], symptoms: string[], additionalNotes?: string): string {
  const medicineNames = medicines
    .map(m => m.nazwa || 'Nieznany lek')
    .join(', ');

  const symptomsList = symptoms.join(', ');

  const notesSection = additionalNotes?.trim()
    ? `\n\n## Dodatkowe informacje od pacjenta:\n${additionalNotes.trim()}`
    : '';

  return `# Konsultacja lekarska

Wciel się w rolę lekarza internisty z 10-letnim doświadczeniem klinicznym.
Pacjent przychodzi z poniższymi objawami i prosi o poradę, które z jego domowych leków mogą pomóc.

## Moje objawy:
${symptomsList}${notesSection}

## Moja apteczka (lista leków):
${medicineNames}

## Twoje zadanie:

1. **Analiza objawów** – krótko opisz co mogą oznaczać te objawy w kontekście najczęstszych przyczyn
2. **Sugestie z apteczki** – które z moich leków wg ulotek mogą pomóc przy tych objawach (bez podawania dawkowania – to pozostaw ulotce)
3. **Czego brakuje** – jeśli żaden lek nie pasuje do objawów, powiedz o tym
4. **Czerwone flagi** – wskaż objawy lub sytuacje, które powinny mnie zaniepokić i skłonić do wizyty u lekarza pierwszego kontaktu lub na izbie przyjęć

Odpowiedz w formie naturalnej rozmowy z pacjentem – ciepło, profesjonalnie, zrozumiale.`
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
