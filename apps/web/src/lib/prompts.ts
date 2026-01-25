// src/lib/prompts.ts v0.004 Extended fields: productType, power, capacity, postacFarmaceutyczna
// Generatory promptów do wklejenia w ChatGPT/Claude/Gemini

import type { Medicine } from './types';

/**
 * Generuje prompt do rozpoznawania leków ze zdjęcia
 */
export function generateImportPrompt(): string {
  return `# Prompt – Rozpoznawanie leków ze zdjęcia (Import JSON)

## Rola
Jesteś asystentem farmacji pomagającym użytkownikowi prowadzić prywatną bazę leków.

## Wejście
Zdjęcie opakowania lub opakowań leków, suplementów diety lub wyrobów medycznych.

## Zadanie (Priorytetyzacja)
1. **Kod kreskowy (EAN) to "kotwica pewności".** Jeśli kod kreskowy (EAN-13 lub EAN-8) jest wyraźnie widoczny, ZAWSZE zwróć obiekt leku, nawet jeśli nazwa jest nieczytelna lub zasłonięta.
2. Jeśli widzisz kod kreskowy, ale nie możesz odczytać nazwy, ustaw \`"nazwa": null\`. Kod kreskowy wystarczy do identyfikacji w bazie zewnętrznej.
3. Jeśli widzisz nazwę, ale nie widzisz kodu, zwróć \`"ean": null\`.
4. Jeśli na zdjęciu jest wiele leków, zwróć listę obiektów.
5. **Wyroby medyczne:** Jeśli produkt NIE jest lekiem ani suplementem (np. plaster, opatrunek, termometr, ciśnieniomierz, inhalator bez leku), ustaw \`"productType": "wyrob_medyczny"\`.

## Zarządzanie Niepewnością
Zwróć status \`"niepewne_rozpoznanie"\` WYŁĄCZNIE wtedy, gdy:
- Nie potrafisz zidentyfikować ANI nazwy, ANI kodu kreskowego.
- Obraz jest tak rozmazany, że żadne dane tekstowe ani numeryczne nie są czytelne.

W pozostałych przypadkach (gdy masz EAN LUB nazwę) generuj dane.

## Format wyjścia (OBOWIĄZKOWY JSON)

Zwróć **wyłącznie poprawny JSON**, bez dodatkowego tekstu.

\`\`\`json
{
  "leki": [
    {
      "productType": "lek | suplement | wyrob_medyczny",
      "nazwa": "string | null",
      "ean": "string | null",
      "power": "string | null",
      "capacity": "string | null",
      "postacFarmaceutyczna": "string | null",
      "opis": "string (krótki opis, język prosty)",
      "wskazania": ["string"],
      "tagi": ["tag1", "tag2"],
      "terminWaznosci": "YYYY-MM-DD | null"
    }
  ]
}
\`\`\`

### Pole productType (typ produktu)
- \`"lek"\` – produkt leczniczy (OTC lub na receptę)
- \`"suplement"\` – suplement diety
- \`"wyrob_medyczny"\` – wyrób medyczny (plaster, opatrunek, termometr, ciśnieniomierz, inhalator, strzykawka, itp.)

### Pole ean (kod kreskowy)
- Jeśli na opakowaniu widoczny jest kod kreskowy (EAN-13 lub EAN-8), zwróć **same cyfry** (np. "5909990733828").
- Kody kreskowe na lekach mają zazwyczaj 13 cyfr (EAN-13) lub 8 cyfr (EAN-8).
- Jeśli kod jest niewidoczny, zwróć \`null\`.

### Pole power (moc/dawka)
- Moc lub dawka widoczna na opakowaniu, np. "500 mg", "10 mg/ml", "200 mg + 30 mg".
- Jeśli niewidoczna lub nie dotyczy (wyrób medyczny), zwróć \`null\`.

### Pole capacity (ilość w opakowaniu)
- Ilość widoczna na pudełku, np. "30 tabletek", "100 ml", "20 saszetek", "140 dawek".
- Dla aerozoli często jest to liczba dawek, np. "140 dawek".
- Jeśli niewidoczna, zwróć \`null\`.

### Pole postacFarmaceutyczna (forma produktu)
- Postać produktu widoczna na opakowaniu, np. "tabletka powlekana", "syrop", "krople", "maść", "żel", "aerozol do nosa", "saszetki".
- Jeśli niewidoczna, zwróć \`null\`.

### Pole terminWaznosci
- Jeśli widzisz datę (np. "EXP 03/2026", "03.2026"), zamień na ostatni dzień miesiąca w formacie ISO: "2026-03-31".
- Jeśli data jest niewidoczna, zwróć \`null\`.

## Zasady treści
- Język prosty, niemedyczny (np. „lek przeciwbólowy").
- Nie podawaj dawkowania ani ostrzeżeń.
- Na końcu opisu zawsze dodaj: **„Stosować zgodnie z ulotką."**
- Leki złożone traktuj jako jedną pozycję.

## Dozwolone tagi (kontrolowana lista)

### Klasyfikacja
- **Rodzaj leku:** bez recepty, na receptę, suplement, wyrób medyczny
- **Grupa docelowa:** dla dorosłych, dla dzieci, dla kobiet w ciąży, dla niemowląt
- **Typ infekcji:** grypa, infekcja bakteryjna, infekcja grzybicza, infekcja wirusowa, przeziębienie

### Objawy i działanie
- **Ból:** ból, ból gardła, ból głowy, ból menstruacyjny, ból mięśni, ból ucha, mięśnie i stawy, przeciwbólowy
- **Układ pokarmowy:** biegunka, kolka, nudności, przeczyszczający, przeciwbiegunkowy, przeciwwymiotny, układ pokarmowy, wzdęcia, wymioty, zaparcia, zgaga
- **Układ oddechowy:** duszność, gorączka, kaszel, katar, nos, przeciwgorączkowy, przeciwkaszlowy, układ oddechowy, wykrztuśny
- **Skóra i alergia:** alergia, nawilżający, oparzenie, przeciwhistaminowy, przeciwświądowy, rana, skóra, sucha skóra, suche oczy, świąd, ukąszenie, wysypka
- **Inne:** afty, antybiotyk, bezsenność, choroba lokomocyjna, jama ustna, odkażający, probiotyk, przeciwzapalny, rozkurczowy, steryd, stres, układ nerwowy, uspokajający, ząbkowanie

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
5. **Wyroby medyczne:** Jeśli produkt NIE jest lekiem ani suplementem (np. plaster, opatrunek, termometr), ustaw \`"productType": "wyrob_medyczny"\`.

## Format wyjścia (OBOWIĄZKOWY)

### Gdy rozpoznano produkt:

\`\`\`json
{
  "status": "rozpoznano",
  "productType": "lek | suplement | wyrob_medyczny",
  "lek": {
    "nazwa": "Poprawna nazwa produktu",
    "power": "string | null (np. '500 mg')",
    "capacity": "string | null (np. '30 tabletek')",
    "postacFarmaceutyczna": "string | null (np. 'tabletka powlekana')",
    "opis": "Krótki opis działania. Stosować zgodnie z ulotką.",
    "wskazania": ["wskazanie1", "wskazanie2"],
    "tagi": ["tag1", "tag2"]
  }
}
\`\`\`

### Pole productType (typ produktu)
- \`"lek"\` – produkt leczniczy (OTC lub na receptę)
- \`"suplement"\` – suplement diety
- \`"wyrob_medyczny"\` – wyrób medyczny (plaster, opatrunek, termometr, ciśnieniomierz, itp.)

### Pole power (moc/dawka)
- Najbardziej popularna moc/dawka dla tego produktu, np. "500 mg", "10 mg/ml".
- Jeśli nie dotyczy (wyrób medyczny) lub nieznana, zwróć \`null\`.

### Pole capacity (ilość w opakowaniu)
- Najbardziej popularna ilość w opakowaniu, np. "30 tabletek", "100 ml".
- Jeśli nieznana, zwróć \`null\`.

### Pole postacFarmaceutyczna (forma produktu)
- Postać produktu, np. "tabletka powlekana", "syrop", "krople", "maść", "żel", "aerozol".
- Jeśli nieznana, zwróć \`null\`.

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
 * Generuje prompt do analizy terminu ważności po otwarciu
 */
export function generateShelfLifePrompt(): string {
  return `# Prompt – Analiza terminu ważności produktu po pierwszym otwarciu

## Rola
Jesteś asystentem farmacji analizującym ulotki leków.

## Wejście
Ulotka leku w formacie PDF.

## Zadanie

1. Przeszukaj ulotkę w poszukiwaniu informacji o **terminie ważności produktu po pierwszym otwarciu**.
2. Informacja ta zazwyczaj znajduje się w sekcjach:
   - "Termin ważności"
   - "Przechowywanie"
   - "Warunki przechowywania"
   - "Okres ważności po pierwszym otwarciu"
3. Szukaj fraz takich jak:
   - "Po otwarciu zużyć w ciągu [okres]"
   - "Okres ważności po otwarciu: [okres]"
   - "Po pierwszym otwarciu należy zużyć w ciągu [okres]"
   - "Termin przydatności po otwarciu opakowania: [okres]"

## Format wyjścia (OBOWIĄZKOWY JSON)

### Gdy znaleziono informację:

\`\`\`json
{
  "status": "znaleziono",
  "shelfLife": "dosłowny cytat z ulotki",
  "period": "6 miesięcy"
}
\`\`\`

Pole \`shelfLife\` powinno zawierać **dosłowny cytat** z ulotki (całe zdanie).
Pole \`period\` powinno zawierać **tylko okres** w formacie naturalnym (np. "6 miesięcy", "30 dni", "2 tygodnie", "1 rok").

### Gdy nie znaleziono:

\`\`\`json
{
  "status": "nie_znaleziono",
  "reason": "W ulotce nie znaleziono informacji o terminie ważności po pierwszym otwarciu."
}
\`\`\`

## Zasady

- **DOSŁOWNY CYTAT** – nie zmieniaj, nie parafrazuj, kopiuj dokładnie jak jest w ulotce.
- Jeśli w ulotce jest kilka różnych terminów dla różnych postaci (np. "po otwarciu butelki: 30 dni", "po otwarciu saszetki: 24h"), wybierz najbardziej ogólny lub pierwszy wymieniony.
- Jeśli naprawdę nie ma żadnej informacji o terminie po otwarciu, zwróć "nie_znaleziono".
- Zwróć **wyłącznie JSON**, bez dodatkowego tekstu.

## Ograniczenia

- Brak interpretacji terminów.
- Brak rad medycznych.
- Wyłącznie kopiowanie faktów z ulotki.

Celem jest **wyłącznie ekstrakcja faktów z dokumentu**.`;
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

