// src/lib/date-ocr.ts
// Helper do rozpoznawania daty ważności przez Gemini API (server-side)

export interface DateOCRResult {
    terminWaznosci: string | null;
}

export interface DateError {
    error: string;
    code: 'API_KEY_MISSING' | 'RATE_LIMIT' | 'INVALID_IMAGE' | 'PARSE_ERROR' | 'API_ERROR';
}

const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

const DATE_OCR_PROMPT = `# Rozpoznawanie daty ważności leku

## Zadanie
Przeanalizuj zdjęcie opakowania leku i znajdź datę ważności (expiry date).

## Wejście
Zdjęcie opakowania leku lub jego część pokazująca datę ważności.

## Format wyjścia
Zwróć **wyłącznie poprawny JSON**, bez dodatkowego tekstu:

\`\`\`json
{
  "terminWaznosci": "YYYY-MM-DD" | null
}
\`\`\`

### Zasady:
1. Szukaj oznaczeń: "EXP", "Ważny do", "Use by", "Best before", dat w formacie MM/YYYY, MM.YYYY, YYYY-MM
2. Jeśli znaleziono datę, zwróć ją w formacie YYYY-MM-DD (ostatni dzień miesiąca, np. dla 03/2026 zwróć "2026-03-31")
3. Jeśli data jest nieczytelna lub niewidoczna, zwróć null
4. Zwróć TYLKO JSON, bez dodatkowego tekstu czy wyjaśnień`;

/**
 * Rozpoznaje datę ważności ze zdjęcia
 * UWAGA: Używać tylko server-side (API route)
 */
export async function recognizeDateFromImage(
    imageBase64: string,
    mimeType: string
): Promise<DateOCRResult | DateError> {
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
                            { text: DATE_OCR_PROMPT },
                            {
                                inline_data: {
                                    mime_type: mimeType,
                                    data: imageBase64
                                }
                            }
                        ]
                    }
                ],
                generationConfig: {
                    temperature: 0.1,
                    maxOutputTokens: 1024,
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
                error: 'Gemini nie zwróciło odpowiedzi. Spróbuj z innym zdjęciem.',
                code: 'API_ERROR'
            };
        }

        console.log('Date OCR raw response:', text);
        console.log('Date OCR raw response length:', text.length);

        // Wyciągnij JSON z odpowiedzi
        let jsonString = text.trim();

        const jsonCodeBlockMatch = jsonString.match(/```json\s*([\s\S]*?)\s*```/);
        if (jsonCodeBlockMatch && jsonCodeBlockMatch[1]) {
            jsonString = jsonCodeBlockMatch[1].trim();
            console.log('Date OCR: extracted from ```json block');
        } else {
            const codeBlockMatch = jsonString.match(/```\s*([\s\S]*?)\s*```/);
            if (codeBlockMatch && codeBlockMatch[1]) {
                jsonString = codeBlockMatch[1].trim();
                console.log('Date OCR: extracted from ``` block');
            } else {
                const jsonObjectMatch = jsonString.match(/\{[\s\S]*\}/);
                if (jsonObjectMatch) {
                    jsonString = jsonObjectMatch[0].trim();
                    console.log('Date OCR: extracted raw JSON object');
                } else {
                    console.log('Date OCR: no JSON pattern found, using raw text');
                }
            }
        }

        console.log('Date OCR extracted JSON:', jsonString);

        try {
            const parsed = JSON.parse(jsonString);
            console.log('Date OCR parsed successfully:', parsed);
            return {
                terminWaznosci: parsed.terminWaznosci || null
            };
        } catch (parseErr) {
            console.error('Date OCR parse error:', parseErr);
            console.error('Date OCR failed JSON string:', jsonString);
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
export function isDateError(result: DateOCRResult | DateError): result is DateError {
    return 'error' in result;
}
