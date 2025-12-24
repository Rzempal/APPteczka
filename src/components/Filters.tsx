'use client';

// src/components/Filters.tsx
// Filtry dla listy leków - Neumorphism Style z możliwością zwijania

import { useState, useEffect } from 'react';
import type { FilterState, ExpiryFilter } from '@/lib/types';
import { TAG_CATEGORIES } from '@/lib/types';

interface FiltersProps {
    filters: FilterState;
    onFiltersChange: (filters: FilterState) => void;
}

export default function Filters({ filters, onFiltersChange }: FiltersProps) {
    const [isFiltersCollapsed, setIsFiltersCollapsed] = useState(false);

    // Załaduj stan zwijania z localStorage
    useEffect(() => {
        const saved = localStorage.getItem('filtersCollapsed');
        if (saved !== null) {
            setIsFiltersCollapsed(saved === 'true');
        }
    }, []);

    // Zapisz stan zwijania do localStorage
    useEffect(() => {
        localStorage.setItem('filtersCollapsed', String(isFiltersCollapsed));
    }, [isFiltersCollapsed]);

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

            {/* Sekcja Filtry (dawniej Tagi) - zwijalna */}
            <div>
                {/* Nagłówek - klikalny do zwijania */}
                <div
                    className="mb-2 flex items-center justify-between cursor-pointer group"
                    onClick={() => setIsFiltersCollapsed(!isFiltersCollapsed)}
                    role="button"
                    aria-expanded={!isFiltersCollapsed}
                >
                    <label className="text-sm font-medium cursor-pointer flex items-center gap-2" style={{ color: 'var(--color-text)' }}>
                        🏷️ Filtry
                        <span
                            className={`neu-tag p-1 transition-all group-hover:scale-110 ${isFiltersCollapsed ? 'active' : ''}`}
                            style={{ borderRadius: '50%' }}
                        >
                            <svg
                                className={`h-3 w-3 transition-transform duration-300 ${isFiltersCollapsed ? '' : 'rotate-180'}`}
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                                style={{ color: isFiltersCollapsed ? 'white' : 'var(--color-text-muted)' }}
                            >
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                            </svg>
                        </span>
                    </label>
                    {hasActiveFilters && (
                        <button
                            onClick={(e) => { e.stopPropagation(); handleClearFilters(); }}
                            className="neu-tag text-xs"
                            style={{ color: 'var(--color-error)' }}
                        >
                            ✕ Wyczyść filtry
                        </button>
                    )}
                </div>

                {/* Kategorie filtrów - ukryte gdy zwinięte */}
                <div
                    className={`overflow-hidden transition-all duration-300 ease-in-out ${isFiltersCollapsed ? 'max-h-0 opacity-0' : 'max-h-[500px] opacity-100'}`}
                >
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
            </div>

            {/* Aktywne filtry (podsumowanie) */}
            {filters.tags.length > 0 && (
                <div className="pt-4" style={{ borderTop: '1px solid var(--shadow-dark)' }}>
                    <span className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>
                        Aktywne filtry ({filters.tags.length}):
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

