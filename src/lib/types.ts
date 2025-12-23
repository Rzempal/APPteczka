// src/lib/types.ts
// Główna encja: Lek (Medicine)

/**
 * Reprezentacja leku w apteczce
 */
export interface Medicine {
    id: string;
    nazwa: string | null;
    opis: string;
    wskazania: string[];
    tagi: string[];
    terminWaznosci?: string; // ISO date string (YYYY-MM-DD)
    dataDodania: string;     // ISO date string
}

/**
 * Format danych importowanych z AI
 */
export interface MedicineImport {
    leki: Omit<Medicine, 'id' | 'dataDodania' | 'terminWaznosci'>[];
}

/**
 * Kontrolowane tagi dla filtrowania
 */
export const ALLOWED_TAGS = {
    objawy: [
        'ból',
        'gorączka',
        'kaszel',
        'katar',
        'ból gardła',
        'ból głowy',
        'ból mięśni',
        'biegunka',
        'nudności',
        'wymioty',
        'alergia',
        'zgaga'
    ],
    typInfekcji: [
        'infekcja wirusowa',
        'infekcja bakteryjna',
        'przeziębienie',
        'grypa'
    ],
    dzialanie: [
        'przeciwbólowy',
        'przeciwgorączkowy',
        'przeciwzapalny',
        'przeciwhistaminowy',
        'przeciwkaszlowy',
        'wykrztuśny',
        'przeciwwymiotny',
        'przeciwbiegunkowy'
    ],
    grupa: [
        'dla dorosłych',
        'dla dzieci'
    ]
} as const;

/**
 * Wszystkie dozwolone tagi (flat array)
 */
export const ALL_ALLOWED_TAGS = [
    ...ALLOWED_TAGS.objawy,
    ...ALLOWED_TAGS.typInfekcji,
    ...ALLOWED_TAGS.dzialanie,
    ...ALLOWED_TAGS.grupa
] as const;

export type AllowedTag = typeof ALL_ALLOWED_TAGS[number];

/**
 * Kategorie tagów dla UI
 */
export const TAG_CATEGORIES = [
    { key: 'objawy', label: 'Objawy', tags: ALLOWED_TAGS.objawy },
    { key: 'typInfekcji', label: 'Typ infekcji', tags: ALLOWED_TAGS.typInfekcji },
    { key: 'dzialanie', label: 'Działanie leku', tags: ALLOWED_TAGS.dzialanie },
    { key: 'grupa', label: 'Grupa użytkowników', tags: ALLOWED_TAGS.grupa }
] as const;

/**
 * Filtry terminu ważności
 */
export type ExpiryFilter = 'all' | 'expired' | 'expiring-soon' | 'valid';

export interface FilterState {
    tags: string[];
    search: string;
    expiry: ExpiryFilter;
}
