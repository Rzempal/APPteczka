'use client';

// src/components/MedicineList.tsx
// Lista/siatka kart leków

import type { Medicine, FilterState } from '@/lib/types';
import MedicineCard from './MedicineCard';

interface MedicineListProps {
    medicines: Medicine[];
    filters: FilterState;
    onDelete: (id: string) => void;
    onUpdateExpiry: (id: string, date: string | undefined) => void;
}

/**
 * Sprawdza status terminu ważności
 */
function getExpiryStatus(terminWaznosci?: string): 'expired' | 'expiring-soon' | 'valid' | 'unknown' {
    if (!terminWaznosci) return 'unknown';

    const today = new Date();
    const expiry = new Date(terminWaznosci);
    const daysUntilExpiry = Math.ceil((expiry.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));

    if (daysUntilExpiry < 0) return 'expired';
    if (daysUntilExpiry <= 30) return 'expiring-soon';
    return 'valid';
}

/**
 * Filtruje leki według aktywnych filtrów
 */
function filterMedicines(medicines: Medicine[], filters: FilterState): Medicine[] {
    return medicines.filter(medicine => {
        // Filtr tekstowy
        if (filters.search) {
            const searchLower = filters.search.toLowerCase();
            const matchesSearch =
                (medicine.nazwa?.toLowerCase().includes(searchLower) ?? false) ||
                medicine.opis.toLowerCase().includes(searchLower) ||
                medicine.wskazania.some(w => w.toLowerCase().includes(searchLower)) ||
                medicine.tagi.some(t => t.toLowerCase().includes(searchLower));

            if (!matchesSearch) return false;
        }

        // Filtr tagów
        if (filters.tags.length > 0) {
            const hasAllTags = filters.tags.every(tag =>
                medicine.tagi.includes(tag)
            );
            if (!hasAllTags) return false;
        }

        // Filtr terminu ważności
        if (filters.expiry !== 'all') {
            const status = getExpiryStatus(medicine.terminWaznosci);

            switch (filters.expiry) {
                case 'expired':
                    if (status !== 'expired') return false;
                    break;
                case 'expiring-soon':
                    if (status !== 'expiring-soon') return false;
                    break;
                case 'valid':
                    if (status !== 'valid') return false;
                    break;
            }
        }

        return true;
    });
}

export default function MedicineList({ medicines, filters, onDelete, onUpdateExpiry }: MedicineListProps) {
    const filteredMedicines = filterMedicines(medicines, filters);

    if (medicines.length === 0) {
        return (
            <div className="flex flex-col items-center justify-center py-16 text-center">
                <div className="mb-4 text-6xl">💊</div>
                <h2 className="mb-2 text-xl font-semibold text-gray-700 dark:text-gray-300">
                    Twoja apteczka jest pusta
                </h2>
                <p className="text-gray-500 dark:text-gray-400">
                    Zaimportuj leki, aby rozpocząć zarządzanie apteczką.
                </p>
                <a
                    href="/import"
                    className="mt-4 rounded-lg bg-blue-600 px-6 py-2 text-white hover:bg-blue-700 transition-colors"
                >
                    Importuj leki
                </a>
            </div>
        );
    }

    if (filteredMedicines.length === 0) {
        return (
            <div className="flex flex-col items-center justify-center py-16 text-center">
                <div className="mb-4 text-6xl">🔍</div>
                <h2 className="mb-2 text-xl font-semibold text-gray-700 dark:text-gray-300">
                    Brak wyników
                </h2>
                <p className="text-gray-500 dark:text-gray-400">
                    Żaden lek nie pasuje do wybranych filtrów.
                </p>
            </div>
        );
    }

    return (
        <div className="space-y-4">
            <div className="text-sm text-gray-500 dark:text-gray-400">
                Znaleziono: {filteredMedicines.length} z {medicines.length} leków
            </div>

            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                {filteredMedicines.map(medicine => (
                    <MedicineCard
                        key={medicine.id}
                        medicine={medicine}
                        onDelete={onDelete}
                        onUpdateExpiry={onUpdateExpiry}
                    />
                ))}
            </div>
        </div>
    );
}
