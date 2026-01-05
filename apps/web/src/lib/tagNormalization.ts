// src/lib/tagNormalization.ts
// Normalizacja i rozszerzanie tagów leków

/**
 * Mapowanie synonimów tagów na formy kanoniczne
 */
export const TAG_SYNONYMS: Record<string, string> = {
    // Rodzaj leku - zamiana terminologii OTC/Rx
    'lek OTC': 'bez recepty',
    'OTC': 'bez recepty',
    'otc': 'bez recepty',
    'lek Rx': 'na receptę',
    'Rx': 'na receptę',
    'rx': 'na receptę',
    'recepta': 'na receptę',
};

/**
 * Implikacje tagów - automatyczne dodawanie powiązanych tagów
 * Klucz: tag wejściowy (objaw szczegółowy)
 * Wartość: tagi do automatycznego dodania
 */
export const TAG_IMPLICATIONS: Record<string, string[]> = {
    // Bóle → ogólny ból + działanie przeciwbólowe
    'ból głowy': ['ból', 'przeciwbólowy'],
    'ból gardła': ['ból', 'przeciwbólowy'],
    'ból mięśni': ['ból', 'przeciwbólowy'],
    'ból menstruacyjny': ['ból', 'przeciwbólowy', 'rozkurczowy'],
    'ból ucha': ['ból', 'przeciwbólowy'],

    // Objawy → działanie leczące
    'gorączka': ['przeciwgorączkowy'],
    'kaszel': ['przeciwkaszlowy'],
    'biegunka': ['przeciwbiegunkowy'],
    'nudności': ['przeciwwymiotny'],
    'wymioty': ['przeciwwymiotny'],
    'alergia': ['przeciwhistaminowy'],
    'świąd': ['przeciwświądowy'],
    'zaparcia': ['przeczyszczający'],
};

/**
 * Normalizuje pojedynczy tag (zamienia synonimy na formę kanoniczną)
 */
export function normalizeTag(tag: string): string {
    const trimmed = tag.trim();
    return TAG_SYNONYMS[trimmed] ?? trimmed;
}

/**
 * Normalizuje listę tagów (zamienia synonimy)
 */
export function normalizeTags(tags: string[]): string[] {
    return tags.map(normalizeTag);
}

/**
 * Rozszerza tagi o implikowane (np. "ból głowy" → +ból +przeciwbólowy)
 */
export function expandTags(tags: string[]): string[] {
    const expanded = new Set(tags);

    for (const tag of tags) {
        const implied = TAG_IMPLICATIONS[tag];
        if (implied) {
            implied.forEach(t => expanded.add(t));
        }
    }

    return Array.from(expanded);
}

/**
 * Pełna normalizacja: synonimy + rozszerzenie
 * Używać przy imporcie leków i OCR
 */
export function processTagsForImport(tags: string[]): string[] {
    const normalized = normalizeTags(tags);
    return expandTags(normalized);
}
