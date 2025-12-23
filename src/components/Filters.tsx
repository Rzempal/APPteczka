'use client';

// src/components/Filters.tsx
// Filtry dla listy leków - Neumorphism Style

import type { FilterState, ExpiryFilter } from '@/lib/types';
import { TAG_CATEGORIES } from '@/lib/types';

interface FiltersProps {
    filters: FilterState;
    onFiltersChange: (filters: FilterState) => void;
}

export default function Filters({ filters, onFiltersChange }: FiltersProps) {
    const handleSearchChange = (search: string) => {
        onFiltersChange({ ...filters, search });
    };

    const handleTagToggle = (tag: string) => {
        const newTags = filters.tags.includes(tag)
            ? filters.tags.filter(t => t !== tag)
            : [...filters.tags, tag];
        onFiltersChange({ ...filters, tags: newTags });
    };

    const handleExpiryChange = (expiry: ExpiryFilter) => {
        onFiltersChange({ ...filters, expiry });
    };

    const handleClearFilters = () => {
        onFiltersChange({ tags: [], search: '', expiry: 'all' });
    };

    const hasActiveFilters = filters.tags.length > 0 || filters.search || filters.expiry !== 'all';

    return (
        <div className="neu-flat p-5 space-y-5 animate-fadeInUp">
            {/* Wyszukiwanie */}
            <div>
                <label htmlFor="search" className="mb-2 block text-sm font-medium" style={{ color: 'var(--color-text)' }}>
                    🔍 Szukaj
                </label>
                <input
                    type="text"
                    id="search"
                    value={filters.search}
                    onChange={(e) => handleSearchChange(e.target.value)}
                    placeholder="Nazwa, opis, wskazania..."
                    className="neu-input"
                    style={{ padding: '0.75rem 1rem', fontSize: '0.875rem' }}
                />
            </div>

            {/* Filtr terminu ważności */}
            <div>
                <label className="mb-2 block text-sm font-medium" style={{ color: 'var(--color-text)' }}>
                    📅 Termin ważności
                </label>
                <div className="flex flex-wrap gap-2">
                    {[
                        { value: 'all', label: 'Wszystkie', icon: '📋' },
                        { value: 'expired', label: 'Przeterminowane', icon: '⚠️' },
                        { value: 'expiring-soon', label: 'Kończą się', icon: '⏰' },
                        { value: 'valid', label: 'Ważne', icon: '✅' }
                    ].map(option => (
                        <button
                            key={option.value}
                            onClick={() => handleExpiryChange(option.value as ExpiryFilter)}
                            className={`neu-tag transition-all ${filters.expiry === option.value ? 'active' : ''}`}
                        >
                            {option.icon} {option.label}
                        </button>
                    ))}
                </div>
            </div>

            {/* Filtry tagów */}
            <div>
                <div className="mb-2 flex items-center justify-between">
                    <label className="text-sm font-medium" style={{ color: 'var(--color-text)' }}>
                        🏷️ Tagi
                    </label>
                    {hasActiveFilters && (
                        <button
                            onClick={handleClearFilters}
                            className="neu-tag text-xs"
                            style={{ color: 'var(--color-error)' }}
                        >
                            ✕ Wyczyść filtry
                        </button>
                    )}
                </div>

                <div className="space-y-3">
                    {TAG_CATEGORIES.map(category => (
                        <div key={category.key}>
                            <span className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>
                                {category.label}
                            </span>
                            <div className="mt-1 flex flex-wrap gap-1.5">
                                {category.tags.map(tag => (
                                    <button
                                        key={tag}
                                        onClick={() => handleTagToggle(tag)}
                                        className={`neu-tag text-xs transition-all ${filters.tags.includes(tag) ? 'active' : ''}`}
                                    >
                                        {tag}
                                    </button>
                                ))}
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            {/* Aktywne filtry (podsumowanie) */}
            {filters.tags.length > 0 && (
                <div className="pt-4" style={{ borderTop: '1px solid var(--shadow-dark)' }}>
                    <span className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>
                        Aktywne tagi ({filters.tags.length}):
                    </span>
                    <div className="mt-2 flex flex-wrap gap-1.5">
                        {filters.tags.map(tag => (
                            <span
                                key={tag}
                                className="neu-tag active text-xs inline-flex items-center"
                            >
                                {tag}
                                <button
                                    onClick={() => handleTagToggle(tag)}
                                    className="ml-1.5 hover:scale-110 transition-transform"
                                    aria-label={`Usuń filtr ${tag}`}
                                >
                                    ×
                                </button>
                            </span>
                        ))}
                    </div>
                </div>
            )}
        </div>
    );
}
