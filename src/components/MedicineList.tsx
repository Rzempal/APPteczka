'use client';

// src/components/MedicineList.tsx
// Lista/siatka kart leków - Neumorphism Style

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
            <div className="neu-flat p-12 text-center animate-fadeInUp">
                <div className="neu-convex w-24 h-24 mx-auto mb-6 flex items-center justify-center animate-popIn">
                    <span className="text-5xl">💊</span>
                </div>
                <h2 className="mb-2 text-xl font-semibold" style={{ color: 'var(--color-text)' }}>
                    Twoja apteczka jest pusta
                </h2>
                <p className="mb-6" style={{ color: 'var(--color-text-muted)' }}>
                    Zaimportuj leki, aby rozpocząć zarządzanie apteczką.
                </p>
                <a
                    href="/dodaj"
                    className="neu-btn neu-btn-primary inline-flex"
                >
                    ➕ Importuj leki
                </a>
            </div>
        );
    }

    if (filteredMedicines.length === 0) {
        return (
            <div className="neu-flat p-12 text-center animate-fadeInUp">
                <div className="neu-convex w-24 h-24 mx-auto mb-6 flex items-center justify-center animate-popIn">
                    <span className="text-5xl">🔍</span>
                </div>
                <h2 className="mb-2 text-xl font-semibold" style={{ color: 'var(--color-text)' }}>
                    Brak wyników
                </h2>
                <p style={{ color: 'var(--color-text-muted)' }}>
                    Żaden lek nie pasuje do wybranych filtrów.
                </p>
            </div>
        );
    }

    return (
        <div className="space-y-4">
            {/* Counter */}
            <div className="neu-tag inline-flex animate-fadeInUp" style={{ animationDelay: '0.1s' }}>
                <span>📦</span>
                <span className="ml-1">Znaleziono: {filteredMedicines.length} z {medicines.length} leków</span>
            </div>

            {/* Grid z kartami */}
            <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
                {filteredMedicines.map((medicine, index) => (
                    <div
                        key={medicine.id}
                        className="animate-fadeInUp"
                        style={{ animationDelay: `${0.1 + index * 0.05}s` }}
                    >
                        <MedicineCard
                            medicine={medicine}
                            onDelete={onDelete}
                            onUpdateExpiry={onUpdateExpiry}
                        />
                    </div>
                ))}
            </div>
        </div>
    );
}
