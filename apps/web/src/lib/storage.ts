// src/lib/storage.ts
// Zarządzanie danymi w localStorage

import { v4 as uuidv4 } from 'uuid';
import type { Medicine, MedicineImport, BackupImport } from './types';
import { getLabels } from './labelStorage';

const STORAGE_KEY = 'appteczka_medicines';

/**
 * Pobiera wszystkie leki z localStorage
 */
export function getMedicines(): Medicine[] {
    if (typeof window === 'undefined') return [];

    try {
        const stored = localStorage.getItem(STORAGE_KEY);
        if (!stored) return [];

        const parsed = JSON.parse(stored);
        return Array.isArray(parsed) ? parsed : [];
    } catch {
        console.error('Błąd odczytu danych z localStorage');
        return [];
    }
}

/**
 * Zapisuje listę leków do localStorage
 */
export function saveMedicines(medicines: Medicine[]): void {
    if (typeof window === 'undefined') return;

    try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(medicines));
    } catch {
        console.error('Błąd zapisu danych do localStorage');
    }
}

/**
 * Dodaje nowy lek do apteczki
 */
export function addMedicine(medicine: Omit<Medicine, 'id' | 'dataDodania'>): Medicine {
    const newMedicine: Medicine = {
        ...medicine,
        id: uuidv4(),
        dataDodania: new Date().toISOString()
    };

    const medicines = getMedicines();
    medicines.push(newMedicine);
    saveMedicines(medicines);

    return newMedicine;
}

/**
 * Sprawdza czy lek o danej nazwie już istnieje
 */
export function findDuplicates(newMedicines: { nazwa: string | null }[]): { nazwa: string; existingId: string }[] {
    const existing = getMedicines();
    const duplicates: { nazwa: string; existingId: string }[] = [];

    for (const newMed of newMedicines) {
        if (!newMed.nazwa) continue;

        const found = existing.find(m =>
            m.nazwa?.toLowerCase().trim() === newMed.nazwa?.toLowerCase().trim()
        );

        if (found) {
            duplicates.push({ nazwa: newMed.nazwa, existingId: found.id });
        }
    }

    return duplicates;
}

/**
 * Typ akcji dla duplikatów
 */
export type DuplicateAction = 'replace' | 'add' | 'skip';

/**
 * Importuje wiele leków z obsługą duplikatów
 */
export function importMedicinesWithDuplicateHandling(
    importData: MedicineImport,
    duplicateActions: Map<string, DuplicateAction>
): Medicine[] {
    const medicines = getMedicines();
    const newMedicines: Medicine[] = [];

    for (const lek of importData.leki) {
        if (!lek.nazwa) {
            // Bez nazwy - zawsze dodaj
            const newMedicine: Medicine = {
                id: uuidv4(),
                nazwa: lek.nazwa,
                opis: lek.opis,
                wskazania: lek.wskazania,
                tagi: lek.tagi,
                labels: lek.labels,
                notatka: lek.notatka,
                dataDodania: new Date().toISOString()
            };
            newMedicines.push(newMedicine);
            continue;
        }

        const action = duplicateActions.get(lek.nazwa) || 'add';
        const existingIndex = medicines.findIndex(m =>
            m.nazwa?.toLowerCase().trim() === lek.nazwa?.toLowerCase().trim()
        );

        if (existingIndex !== -1 && action === 'replace') {
            // Zastąp istniejący
            medicines[existingIndex] = {
                ...medicines[existingIndex],
                opis: lek.opis,
                wskazania: lek.wskazania,
                tagi: lek.tagi,
                labels: lek.labels,
                notatka: lek.notatka
                // Zachowaj terminWaznosci i dataDodania
            };
        } else if (action === 'skip') {
            // Pomiń
            continue;
        } else {
            // Dodaj nowy (add lub brak duplikatu)
            const newMedicine: Medicine = {
                id: uuidv4(),
                nazwa: lek.nazwa,
                opis: lek.opis,
                wskazania: lek.wskazania,
                tagi: lek.tagi,
                labels: lek.labels,
                notatka: lek.notatka,
                dataDodania: new Date().toISOString()
            };
            newMedicines.push(newMedicine);
        }
    }

    saveMedicines([...medicines, ...newMedicines]);
    return newMedicines;
}

/**
 * Importuje backup (pełne dane z terminami)
 */
export function importBackup(
    backupData: BackupImport,
    duplicateActions: Map<string, DuplicateAction>
): Medicine[] {
    const medicines = getMedicines();
    const newMedicines: Medicine[] = [];

    for (const lek of backupData.leki) {
        if (!lek.nazwa) {
            // Bez nazwy - zawsze dodaj z nowym ID
            const newMedicine: Medicine = {
                ...lek,
                id: uuidv4(),
                dataDodania: lek.dataDodania || new Date().toISOString()
            };
            newMedicines.push(newMedicine);
            continue;
        }

        const action = duplicateActions.get(lek.nazwa) || 'add';
        const existingIndex = medicines.findIndex(m =>
            m.nazwa?.toLowerCase().trim() === lek.nazwa?.toLowerCase().trim()
        );

        if (existingIndex !== -1 && action === 'replace') {
            // Zastąp istniejący (zachowaj stare ID)
            medicines[existingIndex] = {
                ...lek,
                id: medicines[existingIndex].id
            };
        } else if (action === 'skip') {
            continue;
        } else {
            // Dodaj nowy z nowym ID
            const newMedicine: Medicine = {
                ...lek,
                id: uuidv4(),
                dataDodania: lek.dataDodania || new Date().toISOString()
            };
            newMedicines.push(newMedicine);
        }
    }

    saveMedicines([...medicines, ...newMedicines]);
    return newMedicines;
}

/**
 * Stara funkcja importu (dla kompatybilności) - DEPRECATED
 */
export function importMedicines(importData: MedicineImport): Medicine[] {
    return importMedicinesWithDuplicateHandling(importData, new Map());
}

/**
 * Usuwa lek z apteczki
 */
export function deleteMedicine(id: string): boolean {
    const medicines = getMedicines();
    const filtered = medicines.filter(m => m.id !== id);

    if (filtered.length === medicines.length) {
        return false;
    }

    saveMedicines(filtered);
    return true;
}

/**
 * Aktualizuje lek (np. termin ważności)
 */
export function updateMedicine(id: string, updates: Partial<Omit<Medicine, 'id' | 'dataDodania'>>): Medicine | null {
    const medicines = getMedicines();
    const index = medicines.findIndex(m => m.id === id);

    if (index === -1) {
        return null;
    }

    medicines[index] = { ...medicines[index], ...updates };
    saveMedicines(medicines);

    return medicines[index];
}

/**
 * Czyści całą apteczkę (reset)
 */
export function clearMedicines(): void {
    if (typeof window === 'undefined') return;
    localStorage.removeItem(STORAGE_KEY);
}

/**
 * Eksportuje apteczkę jako JSON string (pełny backup z etykietami)
 */
export function exportMedicines(): string {
    const medicines = getMedicines();
    const labels = getLabels();
    return JSON.stringify({ leki: medicines, labels }, null, 2);
}

/**
 * Sprawdza czy dane wyglądają na backup (mają id, dataDodania)
 */
export function isBackupFormat(data: unknown): data is BackupImport {
    if (!data || typeof data !== 'object') return false;
    const obj = data as { leki?: unknown[] };
    if (!Array.isArray(obj.leki) || obj.leki.length === 0) return false;

    // Jeśli pierwszy element ma 'id' i 'dataDodania', to backup
    const first = obj.leki[0] as { id?: string; dataDodania?: string };
    return typeof first.id === 'string' && typeof first.dataDodania === 'string';
}
