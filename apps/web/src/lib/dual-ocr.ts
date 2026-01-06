// src/lib/dual-ocr.ts
// Helper do rozpoznawania leku + daty z 2 zdjęć przez Gemini API (server-side)

export interface DualOCRResult {
    nazwa: string | null;
    opis: string;
    wskazania: string[];
    tagi: string[];
    terminWaznosci: string | null;
}

export interface DualOCRError {
    error: string;
    code: 'API_KEY_MISSING' | 'RATE_LIMIT' | 'INVALID_IMAGE' | 'PARSE_ERROR' | 'API_ERROR';
}

const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

const DUAL_OCR_PROMPT = `# Rozpoznawanie leku i daty ważności z dwóch zdjęć

## Rola
Jesteś asystentem farmacji pomagającym użytkownikowi prowadzić prywatną bazę leków (domową apteczkę). Użytkownik nie ma wiedzy farmaceutycznej.

## Wejście
Użytkownik przesyła DWA ZDJĘCIA:
1. **Zdjęcie frontu opakowania** - z widoczną nazwą leku
2. **Zdjęcie daty ważności** - z widocznym oznaczeniem EXP, "Ważny do", itp.

## Zadanie

1. Z PIERWSZEGO zdjęcia rozpoznaj **nazwę leku** i uzupełnij informacje (opis, wskazania, tagi).
2. Z DRUGIEGO zdjęcia rozpoznaj **datę ważności** (expiry date).
3. **Zgadywanie jest zabronione.**

Jeżeli:
- nazwa leku jest nieczytelna,
- opakowanie jest częściowo zasłonięte,
- nie masz 100% pewności co do nazwy,

**zatrzymaj generowanie** i zwróć obiekt z \`nazwa: null\`.

## Format wyjścia (OBOWIĄZKOWY)

Zwróć **wyłącznie poprawny JSON**, bez dodatkowego tekstu.

\`\`\`json
{
  "nazwa": "string | null",
  "opis": "string",
  "wskazania": ["string", "string"],
  "tagi": ["tag1", "tag2"],
  "terminWaznosci": "YYYY-MM-DD | null"
}
\`\`\`

### Pole terminWaznosci

- Jeśli na DRUGIM zdjęciu widoczna jest data ważności (np. "EXP 03/2026", "Ważny do: 2026-03", "03.2026"), zwróć ją w formacie **YYYY-MM-DD** (ostatni dzień miesiąca, np. "2026-03-31").
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

/**
 * Rozpoznaje lek i datę ważności z 2 zdjęć
 * UWAGA: Używać tylko server-side (API route)
 */
export async function recognizeMedicineWithDateFromImages(
    frontImageBase64: string,
    frontMimeType: string,
    dateImageBase64: string,
    dateMimeType: string
): Promise<DualOCRResult | DualOCRError> {
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
        return {
            error: 'Brak klucza API Gemini. Skonfiguruj GEMINI_API_KEY w .env.local',
            code: 'API_KEY_MISSING'
        };
    }

    try {
        const response = await fetch(`${GEMINI_API_URL}?key=${apiKey}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                contents: [
                    {
                        parts: [
                            { text: DUAL_OCR_PROMPT },
                            {
                                inline_data: {
                                    mime_type: frontMimeType,
                                    data: frontImageBase64
                                }
                            },
                            {
                                inline_data: {
                                    mime_type: dateMimeType,
                                    data: dateImageBase64
                                }
                            }
                        ]
                    }
                ],
                generationConfig: {
                    temperature: 0.1,
                    maxOutputTokens: 2048,
                }
            })
        });

        if (response.status === 429) {
            return {
                error: 'Przekroczono limit zapytań do API Gemini. Spróbuj za chwilę.',
                code: 'RATE_LIMIT'
            };
        }

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            return {
                error: `Błąd API Gemini: ${response.status} - ${errorData?.error?.message || 'Nieznany błąd'}`,
                code: 'API_ERROR'
            };
        }

        const data = await response.json();
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;

        if (!text) {
            return {
                error: 'Gemini nie zwróciło odpowiedzi. Spróbuj z innymi zdjęciami.',
                code: 'API_ERROR'
            };
        }

        console.log('Dual OCR raw response:', text);

        // Wyciągnij JSON z odpowiedzi
        let jsonString = text.trim();

        const jsonCodeBlockMatch = jsonString.match(/```json\s*([\s\S]*?)\s*```/);
        if (jsonCodeBlockMatch && jsonCodeBlockMatch[1]) {
            jsonString = jsonCodeBlockMatch[1].trim();
        } else {
            const codeBlockMatch = jsonString.match(/```\s*([\s\S]*?)\s*```/);
            if (codeBlockMatch && codeBlockMatch[1]) {
                jsonString = codeBlockMatch[1].trim();
            } else {
                const jsonObjectMatch = jsonString.match(/\{[\s\S]*\}/);
                if (jsonObjectMatch) {
                    jsonString = jsonObjectMatch[0].trim();
                }
            }
        }

        console.log('Dual OCR extracted JSON:', jsonString.substring(0, 300));

        try {
            const parsed = JSON.parse(jsonString);
            console.log('Dual OCR parsed successfully:', parsed);

            return {
                nazwa: parsed.nazwa || null,
                opis: parsed.opis || 'Stosować zgodnie z ulotką.',
                wskazania: Array.isArray(parsed.wskazania) ? parsed.wskazania : [],
                tagi: Array.isArray(parsed.tagi) ? parsed.tagi : [],
                terminWaznosci: parsed.terminWaznosci || null
            };
        } catch (parseErr) {
            console.error('Dual OCR parse error:', parseErr);
            console.error('Dual OCR failed JSON string:', jsonString);
            return {
                error: `Nie udało się sparsować odpowiedzi Gemini. Raw: ${text.substring(0, 200)}`,
                code: 'PARSE_ERROR'
            };
        }

    } catch (error) {
        return {
            error: `Błąd połączenia z API Gemini: ${error instanceof Error ? error.message : 'Nieznany błąd'}`,
            code: 'API_ERROR'
        };
    }
}

/**
 * Sprawdza czy wynik to błąd
 */
export function isDualOCRError(result: DualOCRResult | DualOCRError): result is DualOCRError {
    return 'error' in result;
}
