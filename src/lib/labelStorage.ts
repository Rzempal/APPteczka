// src/lib/labelStorage.ts
// Zarządzanie etykietami użytkownika w localStorage

import { v4 as uuidv4 } from 'uuid';
import type { UserLabel, LabelColor } from './types';
import { MAX_LABELS_GLOBAL } from './types';

const LABELS_STORAGE_KEY = 'appteczka_labels';

/**
 * Pobiera wszystkie etykiety z localStorage
 */
export function getLabels(): UserLabel[] {
    if (typeof window === 'undefined') return [];

    try {
        const stored = localStorage.getItem(LABELS_STORAGE_KEY);
        if (!stored) return [];

        const parsed = JSON.parse(stored);
        return Array.isArray(parsed) ? parsed : [];
    } catch {
        console.error('Błąd odczytu etykiet z localStorage');
        return [];
    }
}

/**
 * Zapisuje listę etykiet do localStorage
 */
export function saveLabels(labels: UserLabel[]): void {
    if (typeof window === 'undefined') return;

    try {
        localStorage.setItem(LABELS_STORAGE_KEY, JSON.stringify(labels));
    } catch {
        console.error('Błąd zapisu etykiet do localStorage');
    }
}

/**
 * Tworzy nową etykietę
 * @returns null jeśli przekroczono limit
 */
export function createLabel(name: string, color: LabelColor): UserLabel | null {
    const labels = getLabels();

    if (labels.length >= MAX_LABELS_GLOBAL) {
        return null;
    }

    // Sprawdź duplikat nazwy
    if (labels.some(l => l.name.toLowerCase() === name.toLowerCase())) {
        return null;
    }

    const newLabel: UserLabel = {
        id: uuidv4(),
        name: name.trim(),
        color
    };

    labels.push(newLabel);
    saveLabels(labels);

    return newLabel;
}

/**
 * Aktualizuje etykietę
 */
export function updateLabel(id: string, updates: Partial<Omit<UserLabel, 'id'>>): UserLabel | null {
    const labels = getLabels();
    const index = labels.findIndex(l => l.id === id);

    if (index === -1) {
        return null;
    }

    // Sprawdź duplikat nazwy (jeśli zmieniana)
    if (updates.name) {
        const duplicate = labels.find(l =>
            l.id !== id && l.name.toLowerCase() === updates.name!.toLowerCase()
        );
        if (duplicate) return null;
    }

    labels[index] = { ...labels[index], ...updates };
    saveLabels(labels);

    return labels[index];
}

/**
 * Usuwa etykietę oraz czyści referencje do niej ze wszystkich leków
 */
export function deleteLabel(id: string): boolean {
    const labels = getLabels();
    const filtered = labels.filter(l => l.id !== id);

    if (filtered.length === labels.length) {
        return false;
    }

    saveLabels(filtered);

    // Usuń referencje do tej etykiety ze wszystkich leków
    removeLabelFromAllMedicines(id);

    return true;
}

/**
 * Usuwa referencję do etykiety ze wszystkich leków
 */
function removeLabelFromAllMedicines(labelId: string): void {
    if (typeof window === 'undefined') return;

    try {
        const stored = localStorage.getItem('appteczka_medicines');
        if (!stored) return;

        const data = JSON.parse(stored);
        if (!data.leki || !Array.isArray(data.leki)) return;

        let modified = false;

        for (const medicine of data.leki) {
            if (medicine.labels && Array.isArray(medicine.labels)) {
                const originalLength = medicine.labels.length;
                medicine.labels = medicine.labels.filter((lid: string) => lid !== labelId);
                if (medicine.labels.length !== originalLength) {
                    modified = true;
                }
            }
        }

        if (modified) {
            localStorage.setItem('appteczka_medicines', JSON.stringify(data));
            // Emit event to notify components
            window.dispatchEvent(new Event('medicinesUpdated'));
        }
    } catch (error) {
        console.error('Błąd usuwania etykiety z leków:', error);
    }
}

/**
 * Pobiera etykietę po ID
 */
export function getLabelById(id: string): UserLabel | undefined {
    const labels = getLabels();
    return labels.find(l => l.id === id);
}

/**
 * Pobiera wiele etykiet po ID
 */
export function getLabelsByIds(ids: string[]): UserLabel[] {
    const labels = getLabels();
    return labels.filter(l => ids.includes(l.id));
}

/**
 * Eksportuje etykiety (do backupu)
 */
export function exportLabels(): string {
    const labels = getLabels();
    return JSON.stringify({ labels }, null, 2);
}

/**
 * Importuje etykiety z backupu
 */
export function importLabels(data: { labels?: UserLabel[] }): number {
    if (!data.labels || !Array.isArray(data.labels)) {
        return 0;
    }

    const existingLabels = getLabels();
    let imported = 0;

    for (const label of data.labels) {
        // Pomiń istniejące (po nazwie)
        if (existingLabels.some(l => l.name.toLowerCase() === label.name.toLowerCase())) {
            continue;
        }

        if (existingLabels.length >= MAX_LABELS_GLOBAL) {
            break;
        }

        existingLabels.push({
            id: label.id || uuidv4(),
            name: label.name,
            color: label.color || 'gray'
        });
        imported++;
    }

    saveLabels(existingLabels);
    return imported;
}
