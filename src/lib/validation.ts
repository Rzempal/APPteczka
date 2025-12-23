// src/lib/validation.ts
// Walidacja danych importowanych z AI

import { z } from 'zod';
import { ALL_ALLOWED_TAGS } from './types';

/**
 * Schema dla pojedynczego leku (import)
 */
const MedicineImportItemSchema = z.object({
    nazwa: z.string().nullable(),
    opis: z.string().min(1, 'Opis jest wymagany'),
    wskazania: z.array(z.string()).min(1, 'Przynajmniej jedno wskazanie jest wymagane'),
    tagi: z.array(z.string()).min(1, 'Przynajmniej jeden tag jest wymagany')
});

/**
 * Schema dla importu z AI (JSON)
 */
export const MedicineImportSchema = z.object({
    leki: z.array(MedicineImportItemSchema).min(1, 'Lista leków nie może być pusta')
});

/**
 * Schema dla niepewnego rozpoznania (fallback od AI)
 */
export const UncertainRecognitionSchema = z.object({
    status: z.literal('niepewne_rozpoznanie'),
    opcje: z.object({
        A: z.string(),
        B: z.string(),
        C: z.string()
    })
});

/**
 * Waliduje czy tag jest dozwolony
 */
export function isAllowedTag(tag: string): boolean {
    return (ALL_ALLOWED_TAGS as readonly string[]).includes(tag);
}

/**
 * Filtruje tagi do tylko dozwolonych
 */
export function filterAllowedTags(tags: string[]): string[] {
    return tags.filter(isAllowedTag);
}

/**
 * Wynik walidacji
 */
export type ValidationResult<T> =
    | { success: true; data: T }
    | { success: false; errors: string[] };

/**
 * Waliduje dane JSON z importu AI
 */
export function validateMedicineImport(data: unknown): ValidationResult<z.infer<typeof MedicineImportSchema>> {
    const result = MedicineImportSchema.safeParse(data);

    if (result.success) {
        return { success: true, data: result.data };
    }

    const errors = result.error.errors.map(err =>
        `${err.path.join('.')}: ${err.message}`
    );

    return { success: false, errors };
}

/**
 * Sprawdza czy odpowiedź AI to "niepewne rozpoznanie"
 */
export function isUncertainRecognition(data: unknown): boolean {
    return UncertainRecognitionSchema.safeParse(data).success;
}

/**
 * Parsuje JSON/YAML input od użytkownika
 */
export function parseImportInput(input: string): { data: unknown; format: 'json' } | { error: string } {
    const trimmed = input.trim();

    // Próbuj JSON
    try {
        const data = JSON.parse(trimmed);
        return { data, format: 'json' };
    } catch {
        // JSON parsing failed
    }

    return { error: 'Nie udało się sparsować danych. Upewnij się, że format jest poprawny (JSON).' };
}
