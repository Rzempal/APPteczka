// src/lib/storage.ts
// Zarządzanie danymi w localStorage

import { v4 as uuidv4 } from 'uuid';
import type { Medicine, MedicineImport } from './types';

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
 * Importuje wiele leków naraz (z walidowanego importu AI)
 */
export function importMedicines(importData: MedicineImport): Medicine[] {
    const medicines = getMedicines();
    const newMedicines: Medicine[] = [];

    for (const lek of importData.leki) {
        const newMedicine: Medicine = {
            id: uuidv4(),
            nazwa: lek.nazwa,
            opis: lek.opis,
            wskazania: lek.wskazania,
            tagi: lek.tagi,
            dataDodania: new Date().toISOString()
        };
        newMedicines.push(newMedicine);
    }

    saveMedicines([...medicines, ...newMedicines]);
    return newMedicines;
}

/**
 * Usuwa lek z apteczki
 */
export function deleteMedicine(id: string): boolean {
    const medicines = getMedicines();
    const filtered = medicines.filter(m => m.id !== id);

    if (filtered.length === medicines.length) {
        return false; // Nie znaleziono leku
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
 * Eksportuje apteczkę jako JSON string
 */
export function exportMedicines(): string {
    const medicines = getMedicines();
    return JSON.stringify({ leki: medicines }, null, 2);
}
