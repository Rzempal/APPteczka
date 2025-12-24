'use client';

// src/components/MedicineList.tsx
// Lista/siatka kart leków - Neumorphism Style z toggle widoku

import { useState, useEffect } from 'react';
import type { Medicine, FilterState } from '@/lib/types';
import MedicineCard from './MedicineCard';

type SortOption = 'nazwa' | 'dataDodania' | 'terminWaznosci';
type SortDirection = 'asc' | 'desc';

interface MedicineListProps {
    medicines: Medicine[];
    filters: FilterState;
    onDelete: (id: string) => void;
    onUpdateExpiry: (id: string, date: string | undefined) => void;
    onUpdateLabels: (id: string, labelIds: string[]) => void;
    onUpdateNote: (id: string, note: string | undefined) => void;
    totalCount: number;
    sortBy: SortOption;
    sortDir: SortDirection;
    onSortChange: (option: SortOption) => void;
}

type ViewMode = 'grid' | 'list';

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

        // Filtr etykiet użytkownika
        if (filters.labels.length > 0) {
            const medicineLabels = medicine.labels || [];
            const hasAllLabels = filters.labels.every(labelId =>
                medicineLabels.includes(labelId)
            );
            if (!hasAllLabels) return false;
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

export default function MedicineList({ medicines, filters, onDelete, onUpdateExpiry, onUpdateLabels, onUpdateNote, totalCount, sortBy, sortDir, onSortChange }: MedicineListProps) {
    const [viewMode, setViewMode] = useState<ViewMode>('grid');
    const [collapsedCards, setCollapsedCards] = useState<Set<string>>(new Set());

    // Załaduj viewMode z localStorage
    useEffect(() => {
        const savedMode = localStorage.getItem('medicineListViewMode') as ViewMode;
        if (savedMode === 'grid' || savedMode === 'list') {
            setViewMode(savedMode);
        }
    }, []);

    // Zapisz viewMode do localStorage
    useEffect(() => {
        localStorage.setItem('medicineListViewMode', viewMode);
    }, [viewMode]);

    const filteredMedicines = filterMedicines(medicines, filters);

    // Toggle collapse dla pojedynczej karty
    const toggleCollapse = (id: string) => {
        setCollapsedCards(prev => {
            const newSet = new Set(prev);
            if (newSet.has(id)) {
                newSet.delete(id);
            } else {
                newSet.add(id);
            }
            return newSet;
        });
    };

    // Sprawdzanie czy karta jest zwinięta (w widoku lista domyślnie zwinięte)
    const isCardCollapsed = (id: string): boolean => {
        if (viewMode === 'list') {
            // W widoku lista: domyślnie zwinięte, chyba że rozwinięte ręcznie
            return !collapsedCards.has(id);
        } else {
            // W widoku grid: domyślnie rozwinięte, chyba że zwinięte ręcznie
            return collapsedCards.has(id);
        }
    };

    // Reset collapsed state przy zmianie widoku
    const handleViewModeChange = (mode: ViewMode) => {
        setViewMode(mode);
        setCollapsedCards(new Set()); // Reset stanu zwijania
    };

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
            {/* Header: Unified Toolbar - Counter | Sorting | View Toggle */}
            <div
                className="neu-flat-sm flex flex-wrap items-center justify-between gap-3 px-4 py-3 animate-fadeInUp"
                style={{ animationDelay: '0.1s' }}
            >
                {/* Licznik - jako tekst, nie przycisk */}
                <span className="text-sm font-medium order-last sm:order-first w-full sm:w-auto text-center sm:text-left" style={{ color: 'var(--color-text)' }}>
                    📦 Znaleziono: {filteredMedicines.length} z {totalCount} leków
                </span>

                {/* Sortowanie + Widok - zawsze razem */}
                <div className="flex items-center gap-3 mx-auto sm:mx-0">
                    {/* Sortowanie */}
                    <div className="flex items-center gap-1">
                        <span className="text-xs" style={{ color: 'var(--color-text-muted)' }}>Sortuj:</span>
                        {[
                            { key: 'nazwa', label: 'Nazwa' },
                            { key: 'dataDodania', label: 'Data' },
                            { key: 'terminWaznosci', label: 'Termin' },
                        ].map((opt) => (
                            <button
                                key={opt.key}
                                onClick={() => onSortChange(opt.key as SortOption)}
                                className={`neu-tag text-xs ${sortBy === opt.key ? 'active' : ''}`}
                            >
                                {opt.label} {sortBy === opt.key && (sortDir === 'asc' ? '↑' : '↓')}
                            </button>
                        ))}
                    </div>

                    {/* Separator */}
                    <div className="w-px h-5 bg-current opacity-20" />

                    {/* View Mode Toggle */}
                    <div className="flex gap-1">
                        <button
                            onClick={() => handleViewModeChange('grid')}
                            className={`neu-tag p-2 transition-all ${viewMode === 'grid' ? 'active' : ''}`}
                            title="Widok kafelków"
                            aria-label="Widok kafelków"
                            aria-pressed={viewMode === 'grid'}
                        >
                            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"
                                style={{ color: viewMode === 'grid' ? 'white' : 'var(--color-text-muted)' }}>
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                                    d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
                            </svg>
                        </button>
                        <button
                            onClick={() => handleViewModeChange('list')}
                            className={`neu-tag p-2 transition-all ${viewMode === 'list' ? 'active' : ''}`}
                            title="Widok listy"
                            aria-label="Widok listy"
                            aria-pressed={viewMode === 'list'}
                        >
                            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"
                                style={{ color: viewMode === 'list' ? 'white' : 'var(--color-text-muted)' }}>
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                                    d="M4 5h16a1 1 0 011 1v3a1 1 0 01-1 1H4a1 1 0 01-1-1V6a1 1 0 011-1zM4 14h16a1 1 0 011 1v3a1 1 0 01-1 1H4a1 1 0 01-1-1v-3a1 1 0 011-1z" />
                            </svg>
                        </button>
                    </div>
                </div>
            </div>

            {/* Grid/List z kartami */}
            <div className={viewMode === 'grid'
                ? 'grid gap-5 sm:grid-cols-1 md:grid-cols-2 xl:grid-cols-3'
                : 'flex flex-col gap-3'
            }>
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
                            onUpdateLabels={onUpdateLabels}
                            onUpdateNote={onUpdateNote}
                            isCollapsed={isCardCollapsed(medicine.id)}
                            onToggleCollapse={() => toggleCollapse(medicine.id)}
                        />
                    </div>
                ))}
            </div>
        </div>
    );
}

