// src/lib/gemini.ts
// Helper do komunikacji z Gemini API (server-side)

import { generateImportPrompt, generateNameLookupPrompt } from './prompts';

export interface GeminiOCRResult {
    leki: Array<{
        nazwa: string | null;
        opis: string;
        wskazania: string[];
        tagi: string[];
        terminWaznosci: string | null;
    }>;
}

export interface GeminiNameLookupResult {
    status: 'rozpoznano';
    lek: {
        nazwa: string;
        opis: string;
        wskazania: string[];
        tagi: string[];
    };
}

export interface GeminiNameLookupError {
    status: 'nie_rozpoznano';
    reason: string;
}

export interface GeminiError {
    error: string;
    code: 'API_KEY_MISSING' | 'RATE_LIMIT' | 'INVALID_INPUT' | 'PARSE_ERROR' | 'API_ERROR';
}

const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

/**
 * Wysyła zdjęcie do Gemini API i zwraca rozpoznane leki
 * UWAGA: Używać tylko server-side (API route)
 */
export async function recognizeMedicinesFromImage(
    imageBase64: string,
    mimeType: string
): Promise<GeminiOCRResult | GeminiError> {
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
        return {
            error: 'Brak klucza API Gemini. Skonfiguruj GEMINI_API_KEY w .env.local',
            code: 'API_KEY_MISSING'
        };
    }

    const prompt = generateImportPrompt();

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
                            { text: prompt },
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
                    maxOutputTokens: 4096,
                }
            })
        });

        if (response.status === 429) {
            return {
                error: 'Przekroczono limit zapytań do API Gemini. Spróbuj za chwilę lub użyj ręcznego promptu.',
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
        console.log('Gemini API raw response:', JSON.stringify(data, null, 2));
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;

        if (!text) {
            console.log('Gemini no text found in response');
            return {
                error: 'Gemini nie zwróciło odpowiedzi. Spróbuj z innym zdjęciem.',
                code: 'API_ERROR'
            };
        }

        console.log('Gemini text response:', text);

        // Wyciągnij JSON z odpowiedzi (może być owinięty w ```json ... ``` lub ``` ... ```)
        // Próbujemy kilka wzorców, od najbardziej specyficznego do ogólnego
        let jsonString = text.trim();

        // Wzorzec 1: ```json ... ``` (z opcjonalnym whitespace)
        const jsonCodeBlockMatch = jsonString.match(/```json\s*([\s\S]*?)\s*```/);
        if (jsonCodeBlockMatch && jsonCodeBlockMatch[1]) {
            jsonString = jsonCodeBlockMatch[1].trim();
        } else {
            // Wzorzec 2: ``` ... ``` (bez specyfikacji języka)
            const codeBlockMatch = jsonString.match(/```\s*([\s\S]*?)\s*```/);
            if (codeBlockMatch && codeBlockMatch[1]) {
                jsonString = codeBlockMatch[1].trim();
            } else {
                // Wzorzec 3: szukaj pierwszego { do ostatniego } 
                const jsonObjectMatch = jsonString.match(/\{[\s\S]*\}/);
                if (jsonObjectMatch) {
                    jsonString = jsonObjectMatch[0].trim();
                }
            }
        }

        console.log('Extracted JSON string:', jsonString.substring(0, 300));

        try {
            const parsed = JSON.parse(jsonString);

            // Sprawdź czy to odpowiedź niepewna
            if (parsed.status === 'niepewne_rozpoznanie') {
                return {
                    error: 'Nie udało się jednoznacznie rozpoznać leków. Spróbuj z wyraźniejszym zdjęciem.',
                    code: 'PARSE_ERROR'
                };
            }

            // Normalizuj odpowiedź
            if (parsed.leki && Array.isArray(parsed.leki)) {
                return { leki: parsed.leki };
            }

            // Jeśli odpowiedź to pojedynczy lek bez tablicy
            if (parsed.nazwa !== undefined) {
                return { leki: [parsed] };
            }

            return {
                error: 'Nieoczekiwany format odpowiedzi od Gemini.',
                code: 'PARSE_ERROR'
            };

        } catch (parseErr) {
            console.error('JSON parse error:', parseErr, 'Raw text:', text);
            return {
                error: `Nie udało się sparsować odpowiedzi Gemini jako JSON. Raw: ${text.substring(0, 200)}`,
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
export function isGeminiError(result: GeminiOCRResult | GeminiError | GeminiNameLookupResult | GeminiNameLookupError): result is GeminiError {
    return 'error' in result;
}

/**
 * Wyszukuje informacje o leku na podstawie nazwy
 * UWAGA: Używać tylko server-side (API route)
 */
export async function lookupMedicineByName(
    name: string
): Promise<GeminiNameLookupResult | GeminiNameLookupError | GeminiError> {
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
        return {
            error: 'Brak klucza API Gemini. Skonfiguruj GEMINI_API_KEY w .env.local',
            code: 'API_KEY_MISSING'
        };
    }

    const prompt = generateNameLookupPrompt(name);

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
                            { text: prompt }
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
        console.log('Gemini Name Lookup raw response:', JSON.stringify(data, null, 2));
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;

        if (!text) {
            console.log('Gemini no text found in response');
            return {
                error: 'Gemini nie zwróciło odpowiedzi.',
                code: 'API_ERROR'
            };
        }

        console.log('Gemini text response:', text);

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

        console.log('Extracted JSON string:', jsonString.substring(0, 300));

        try {
            const parsed = JSON.parse(jsonString);

            // Sprawdź czy rozpoznano lek
            if (parsed.status === 'rozpoznano' && parsed.lek) {
                return {
                    status: 'rozpoznano',
                    lek: parsed.lek
                };
            }

            // Nie rozpoznano
            if (parsed.status === 'nie_rozpoznano') {
                return {
                    status: 'nie_rozpoznano',
                    reason: parsed.reason || 'Nie rozpoznano produktu.'
                };
            }

            return {
                error: 'Nieoczekiwany format odpowiedzi od Gemini.',
                code: 'PARSE_ERROR'
            };

        } catch (parseErr) {
            console.error('JSON parse error:', parseErr, 'Raw text:', text);
            return {
                error: `Nie udało się sparsować odpowiedzi Gemini.`,
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
