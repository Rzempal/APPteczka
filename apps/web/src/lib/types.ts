// src/lib/types.ts
// Główna encja: Lek (Medicine)

// ==================== ETYKIETY UŻYTKOWNIKA ====================

/**
 * Dostępne kolory etykiet
 */
export const LABEL_COLORS = {
    red: { name: 'Czerwony', hex: '#ef4444' },
    orange: { name: 'Pomarańczowy', hex: '#f97316' },
    yellow: { name: 'Żółty', hex: '#eab308' },
    green: { name: 'Zielony', hex: '#22c55e' },
    blue: { name: 'Niebieski', hex: '#3b82f6' },
    purple: { name: 'Fioletowy', hex: '#a855f7' },
    pink: { name: 'Różowy', hex: '#ec4899' },
    gray: { name: 'Szary', hex: '#6b7280' }
} as const;

export type LabelColor = keyof typeof LABEL_COLORS;

/**
 * Limity etykiet
 */
export const MAX_LABELS_PER_MEDICINE = 5;
export const MAX_LABELS_GLOBAL = 15;

/**
 * Etykieta użytkownika (definiowana dowolnie)
 */
export interface UserLabel {
    id: string;
    name: string;
    color: LabelColor;
}

// ==================== LEK ====================

/**
 * Reprezentacja leku w apteczce
 */
export interface Medicine {
    id: string;
    nazwa: string | null;
    opis: string;
    wskazania: string[];
    tagi: string[];
    labels?: string[];        // ID etykiet użytkownika
    notatka?: string;         // Notatka użytkownika
    terminWaznosci?: string;  // ISO date string (YYYY-MM-DD)
    leafletUrl?: string;      // Link do ulotki PDF z Rejestru Produktów Leczniczych
    dataDodania: string;      // ISO date string
}

/**
 * Format danych importowanych z AI (bez terminów)
 */
export interface MedicineImport {
    leki: Omit<Medicine, 'id' | 'dataDodania' | 'terminWaznosci'>[];
}

/**
 * Format pełnego backupu (z terminami i wszystkimi danymi)
 */
export interface BackupImport {
    leki: Medicine[];
}

/**
 * Kontrolowane tagi dla filtrowania
 * UWAGA: Kategorie połączone zgodnie z planem z 2026-01-05
 */
export const ALLOWED_TAGS = {
    // === OBJAWY I DZIAŁANIE (połączone) ===
    objawIDzialanie: [
        // Ból
        'ból', 'ból głowy', 'ból gardła', 'ból mięśni', 'ból menstruacyjny', 'ból ucha',
        'przeciwbólowy',
        // Układ pokarmowy
        'nudności', 'wymioty', 'biegunka', 'zaparcia', 'wzdęcia', 'zgaga', 'kolka',
        'przeciwwymiotny', 'przeciwbiegunkowy', 'przeczyszczający',
        // Układ oddechowy
        'gorączka', 'kaszel', 'katar', 'duszność',
        'przeciwgorączkowy', 'przeciwkaszlowy', 'wykrztuśny',
        // Skóra/alergia
        'świąd', 'wysypka', 'oparzenie', 'ukąszenie', 'rana', 'sucha skóra', 'suche oczy',
        'alergia', 'przeciwhistaminowy', 'przeciwświądowy', 'nawilżający',
        // Inne
        'bezsenność', 'stres', 'choroba lokomocyjna', 'afty', 'ząbkowanie',
        'przeciwzapalny', 'odkażający', 'uspokajający', 'rozkurczowy',
        'probiotyk', 'antybiotyk', 'steryd'
    ],

    // === INFEKCJE ===
    typInfekcji: [
        'infekcja wirusowa', 'infekcja bakteryjna', 'infekcja grzybicza',
        'przeziębienie', 'grypa'
    ],

    // === RODZAJ LEKU (zaktualizowane nazwy) ===
    rodzaj: [
        'bez recepty',      // dawniej: lek OTC
        'na receptę',       // dawniej: lek Rx
        'suplement',
        'wyrób medyczny'
    ],

    // === GRUPA DOCELOWA ===
    grupa: [
        'dla dorosłych', 'dla dzieci', 'dla niemowląt',
        'dla kobiet w ciąży'
    ]
} as const;

/**
 * Wszystkie dozwolone tagi (flat array)
 */
export const ALL_ALLOWED_TAGS = [
    ...ALLOWED_TAGS.objawIDzialanie,
    ...ALLOWED_TAGS.typInfekcji,
    ...ALLOWED_TAGS.rodzaj,
    ...ALLOWED_TAGS.grupa
] as const;

export type AllowedTag = typeof ALL_ALLOWED_TAGS[number];

/**
 * Kategorie tagów dla UI
 */
export const TAG_CATEGORIES = [
    { key: 'objawIDzialanie', label: 'Objawy i działanie', tags: ALLOWED_TAGS.objawIDzialanie },
    { key: 'typInfekcji', label: 'Typ infekcji', tags: ALLOWED_TAGS.typInfekcji },
    { key: 'rodzaj', label: 'Rodzaj leku', tags: ALLOWED_TAGS.rodzaj },
    { key: 'grupa', label: 'Grupa docelowa', tags: ALLOWED_TAGS.grupa }
] as const;

/**
 * Filtry terminu ważności
 */
export type ExpiryFilter = 'all' | 'expired' | 'expiring-soon' | 'valid';

export interface FilterState {
    tags: string[];
    labels: string[];         // ID etykiet do filtrowania
    search: string;
    expiry: ExpiryFilter;
}
