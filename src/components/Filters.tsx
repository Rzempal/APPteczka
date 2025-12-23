'use client';

// src/components/Filters.tsx
// Filtry dla listy leków

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
        <div className="space-y-4 rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
            {/* Wyszukiwanie */}
            <div>
                <label htmlFor="search" className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Szukaj
                </label>
                <input
                    type="text"
                    id="search"
                    value={filters.search}
                    onChange={(e) => handleSearchChange(e.target.value)}
                    placeholder="Nazwa, opis, wskazania..."
                    className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                />
            </div>

            {/* Filtr terminu ważności */}
            <div>
                <label className="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Termin ważności
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
                            className={`rounded-lg px-3 py-1.5 text-sm font-medium transition-colors ${filters.expiry === option.value
                                    ? 'bg-blue-600 text-white'
                                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300'
                                }`}
                        >
                            {option.icon} {option.label}
                        </button>
                    ))}
                </div>
            </div>

            {/* Filtry tagów */}
            <div>
                <div className="mb-2 flex items-center justify-between">
                    <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
                        Tagi
                    </label>
                    {hasActiveFilters && (
                        <button
                            onClick={handleClearFilters}
                            className="text-xs text-red-600 hover:underline dark:text-red-400"
                        >
                            Wyczyść filtry
                        </button>
                    )}
                </div>

                <div className="space-y-3">
                    {TAG_CATEGORIES.map(category => (
                        <div key={category.key}>
                            <span className="text-xs font-medium text-gray-500 dark:text-gray-400">
                                {category.label}
                            </span>
                            <div className="mt-1 flex flex-wrap gap-1.5">
                                {category.tags.map(tag => (
                                    <button
                                        key={tag}
                                        onClick={() => handleTagToggle(tag)}
                                        className={`rounded-full px-2.5 py-0.5 text-xs font-medium transition-colors ${filters.tags.includes(tag)
                                                ? 'bg-blue-600 text-white'
                                                : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300'
                                            }`}
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
                <div className="border-t border-gray-200 pt-3 dark:border-gray-700">
                    <span className="text-xs font-medium text-gray-500 dark:text-gray-400">
                        Aktywne tagi ({filters.tags.length}):
                    </span>
                    <div className="mt-1 flex flex-wrap gap-1.5">
                        {filters.tags.map(tag => (
                            <span
                                key={tag}
                                className="inline-flex items-center rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800 dark:bg-blue-900 dark:text-blue-200"
                            >
                                {tag}
                                <button
                                    onClick={() => handleTagToggle(tag)}
                                    className="ml-1 hover:text-blue-600"
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
