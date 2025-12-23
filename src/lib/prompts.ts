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
 * Generuje prompt do analizy apteczki pod kątem objawów
 */
export function generateAnalysisPrompt(medicines: Medicine[], symptoms: string[]): string {
    const medicinesList = medicines
        .map(m => `- ${m.nazwa || 'Nieznany lek'}: ${m.opis} (tagi: ${m.tagi.join(', ')})`)
        .join('\n');

    const symptomsList = symptoms.join(', ');

    return `# Analiza apteczki pod kątem objawów

## Rola
Jesteś asystentem informacyjnym (nie medycznym). Twoim zadaniem jest **analiza informacyjna** – nie jesteś lekarzem i nie udzielasz porad medycznych.

## Dane wejściowe

### Apteczka użytkownika:
${medicinesList}

### Objawy użytkownika:
${symptomsList}

## Zadanie

Na podstawie **ulotek i opisów leków** (NIE wiedzy medycznej):

1. **Potencjalnie pasujące leki** – które leki mają w tagach/wskazaniach cokolwiek związanego z podanymi objawami
2. **Leki niepasujące** – które leki zdecydowanie nie mają związku z objawami
3. **Brakujące kategorie** – jeśli żaden lek nie pasuje do objawu

## Format odpowiedzi

### ✅ Potencjalnie pasujące leki
[lista leków z krótkim uzasadnieniem]

### ❌ Leki niepasujące do objawów
[lista leków]

### ⚠️ Brak odpowiednich leków dla:
[lista objawów bez odpowiedniego leku]

### 🏥 Zalecenie
„**To nie jest porada medyczna.** W przypadku wątpliwości skonsultuj się z lekarzem lub farmaceutą."

## Ograniczenia

- NIE sugeruj dawkowania
- NIE oceniaj skuteczności
- NIE zastępuj wizyty u lekarza
- Bazuj TYLKO na informacjach z ulotek`;
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
