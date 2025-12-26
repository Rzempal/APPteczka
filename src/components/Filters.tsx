'use client';

// src/components/Filters.tsx
// Filtry dla listy léków - Neumorphism Style z możliwością zwijania

import { useState, useEffect } from 'react';
import Image from 'next/image';
import type { FilterState, ExpiryFilter, UserLabel } from '@/lib/types';
import { TAG_CATEGORIES, LABEL_COLORS } from '@/lib/types';
import { getLabels } from '@/lib/labelStorage';
import LabelManager from './LabelManager';

interface FiltersProps {
    filters: FilterState;
    onFiltersChange: (filters: FilterState) => void;
    onExportPDF?: () => void;
    onCopyList?: () => void;
    onClearAll?: () => void;
}

export default function Filters({ filters, onFiltersChange, onExportPDF, onCopyList, onClearAll }: FiltersProps) {
    // Domyślnie wszystko schowane
    const [isExpiryCollapsed, setIsExpiryCollapsed] = useState(true);
    const [isFiltersCollapsed, setIsFiltersCollapsed] = useState(true);
    const [isLabelsCollapsed, setIsLabelsCollapsed] = useState(true);
    const [isLabelManagerOpen, setIsLabelManagerOpen] = useState(false);
    const [userLabels, setUserLabels] = useState<UserLabel[]>([]);
    // Stan zwijania poszczególnych kategorii tagów
    const [collapsedCategories, setCollapsedCategories] = useState<Record<string, boolean>>({});

    // Załaduj stan zwijania z localStorage
    useEffect(() => {
        const savedExpiry = localStorage.getItem('expiryCollapsed');
        const savedFilters = localStorage.getItem('filtersCollapsed');
        const savedLabels = localStorage.getItem('labelsCollapsed');

        if (savedExpiry !== null) setIsExpiryCollapsed(savedExpiry === 'true');
        if (savedFilters !== null) setIsFiltersCollapsed(savedFilters === 'true');
        if (savedLabels !== null) setIsLabelsCollapsed(savedLabels === 'true');
        // Załaduj stan zwijania kategorii
        const savedCategories = localStorage.getItem('collapsedCategories');
        if (savedCategories) {
            try {
                setCollapsedCategories(JSON.parse(savedCategories));
            } catch { /* ignore */ }
        }
    }, []);

    // Zapisz stan zwijania do localStorage
    useEffect(() => {
        localStorage.setItem('expiryCollapsed', String(isExpiryCollapsed));
    }, [isExpiryCollapsed]);

    useEffect(() => {
        localStorage.setItem('filtersCollapsed', String(isFiltersCollapsed));
    }, [isFiltersCollapsed]);

    useEffect(() => {
        localStorage.setItem('labelsCollapsed', String(isLabelsCollapsed));
    }, [isLabelsCollapsed]);

    // Zapisz stan zwijania kategorii
    useEffect(() => {
        localStorage.setItem('collapsedCategories', JSON.stringify(collapsedCategories));
    }, [collapsedCategories]);

    const toggleCategory = (key: string) => {
        setCollapsedCategories(prev => ({ ...prev, [key]: !prev[key] }));
    };

    // Załaduj etykiety
    useEffect(() => {
        setUserLabels(getLabels());
    }, []);

    // Nasłuchuj na zmiany etykiet (z kart leków)
    useEffect(() => {
        const handleLabelsUpdated = () => {
            setUserLabels(getLabels());
        };
        window.addEventListener('labelsUpdated', handleLabelsUpdated);
        return () => window.removeEventListener('labelsUpdated', handleLabelsUpdated);
    }, []);

    const refreshLabels = () => {
        setUserLabels(getLabels());
    };

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

    const handleLabelToggle = (labelId: string) => {
        const newLabels = filters.labels.includes(labelId)
            ? filters.labels.filter(l => l !== labelId)
            : [...filters.labels, labelId];
        onFiltersChange({ ...filters, labels: newLabels });
    };

    const handleClearFilters = () => {
        onFiltersChange({ tags: [], labels: [], search: '', expiry: 'all' });
    };

    const hasActiveFilters = filters.tags.length > 0 || filters.labels.length > 0 || filters.search || filters.expiry !== 'all';

    return (
        <div className="neu-flat p-5 space-y-5 animate-fadeInUp">
            {/* Tytuł strony + przyciski */}
            <div className="flex flex-wrap items-center justify-between gap-2">
                <h1 className="text-xl font-bold flex items-center gap-2" style={{ color: 'var(--color-text)' }}>
                    <Image src="/icons/twoja_apteczka.png" alt="Twoja apteczka" width={36} height={36} />
                    Twoja apteczka
                </h1>
                <div className="flex flex-wrap gap-2">
                    {onCopyList && (
                        <button
                            onClick={onCopyList}
                            className="neu-btn neu-btn-secondary text-sm"
                            title="Kopiuj listę leków"
                        >
                            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                            </svg>
                            Lista
                        </button>
                    )}
                    {onExportPDF && (
                        <button
                            onClick={onExportPDF}
                            className="neu-btn neu-btn-secondary text-sm"
                            title="Eksportuj do PDF"
                        >
                            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
                            </svg>
                            PDF
                        </button>
                    )}
                    {onClearAll && (
                        <button
                            onClick={() => {
                                if (window.confirm('Czy na pewno chcesz wyczyścić całą apteczkę? Tej operacji nie można cofnąć.')) {
                                    onClearAll();
                                }
                            }}
                            className="neu-btn neu-btn-secondary text-sm"
                            style={{ color: 'var(--color-error)' }}
                            title="Wyczyść całą apteczkę"
                        >
                            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                            Wyczyść
                        </button>
                    )}
                </div>
            </div>

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

            {/* Filtr terminu ważności - zwijalna */}
            <div>
                {/* Nagłówek - klikalny do zwijania */}
                <div
                    className="mb-2 flex items-center justify-between cursor-pointer group"
                    onClick={() => setIsExpiryCollapsed(!isExpiryCollapsed)}
                    role="button"
                    aria-expanded={!isExpiryCollapsed}
                >
                    <label className="text-sm font-medium cursor-pointer flex items-center gap-2" style={{ color: 'var(--color-text)' }}>
                        📅 Termin ważności
                        <span
                            className={`neu-tag p-1 transition-all group-hover:scale-110 ${isExpiryCollapsed ? 'active' : ''}`}
                            style={{ borderRadius: '50%' }}
                        >
                            <svg
                                className={`h-3 w-3 transition-transform duration-300 ${isExpiryCollapsed ? '' : 'rotate-180'}`}
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                                style={{ color: isExpiryCollapsed ? 'white' : 'var(--color-text-muted)' }}
                            >
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                            </svg>
                        </span>
                    </label>
                    {/* Pokaż aktywny filtr terminu gdy zwinięte */}
                    {isExpiryCollapsed && filters.expiry !== 'all' && (
                        <span className="neu-tag active text-xs">
                            {filters.expiry === 'expired' && '⚠️ Przeterminowane'}
                            {filters.expiry === 'expiring-soon' && '⏰ Kończą się'}
                            {filters.expiry === 'valid' && '✅ Ważne'}
                        </span>
                    )}
                </div>

                {/* Przyciski terminu - ukryte gdy zwinięte */}
                <div
                    className={`overflow-hidden transition-all duration-300 ease-in-out ${isExpiryCollapsed ? 'max-h-0 opacity-0' : 'max-h-[100px] opacity-100'}`}
                >
                    <div className="flex flex-wrap gap-2 pt-2 pb-2">
                        {[
                            { value: 'all', label: 'Wszystkie', icon: '📋' },
                            { value: 'expired', label: 'Przeterminowane', icon: '⚠️' },
                            { value: 'expiring-soon', label: 'Kończą się', icon: '⏰' },
                            { value: 'valid', label: 'Ważne', icon: '✅' }
                        ].map(option => (
                            <button
                                key={option.value}
                                onClick={(e) => { e.stopPropagation(); handleExpiryChange(option.value as ExpiryFilter); }}
                                className={`neu-tag transition-all ${filters.expiry === option.value ? 'active' : ''}`}
                            >
                                {option.icon} {option.label}
                            </button>
                        ))}
                    </div>
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
                    className={`overflow-hidden transition-all duration-300 ease-in-out ${isFiltersCollapsed ? 'max-h-0 opacity-0' : 'max-h-[2000px] opacity-100'}`}
                >
                    <div className="space-y-3 py-3 px-2">
                        {TAG_CATEGORIES.map(category => {
                            const isCollapsed = collapsedCategories[category.key] ?? true;
                            const activeCount = category.tags.filter(tag => filters.tags.includes(tag)).length;

                            return (
                                <div key={category.key} className="mb-2">
                                    {/* Nagłówek kategorii - klikalny, wypukły */}
                                    <button
                                        type="button"
                                        onClick={() => toggleCategory(category.key)}
                                        className="neu-flat-sm w-full flex items-center justify-between text-left py-2 px-3 rounded-xl transition-all duration-200 cursor-pointer select-none"
                                    >
                                        <span
                                            className="text-xs font-medium flex items-center gap-1.5"
                                            style={{ color: isCollapsed ? 'var(--color-text-muted)' : 'var(--color-accent)' }}
                                        >
                                            <svg
                                                className={`h-2.5 w-2.5 transition-transform duration-200 ${isCollapsed ? '' : 'rotate-90'}`}
                                                fill="none"
                                                stroke="currentColor"
                                                viewBox="0 0 24 24"
                                            >
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                                            </svg>
                                            {category.label}
                                        </span>
                                        <div className="flex items-center gap-1.5">
                                            <span className="text-[10px]" style={{ color: 'var(--color-text-muted)', opacity: 0.5 }}>
                                                {category.tags.length}
                                            </span>
                                            {activeCount > 0 && (
                                                <span
                                                    className="text-[10px] min-w-[16px] text-center px-1 py-0.5 rounded-full"
                                                    style={{ background: 'var(--color-accent)', color: 'white' }}
                                                >
                                                    {activeCount}
                                                </span>
                                            )}
                                        </div>
                                    </button>

                                    {/* Tagi - ukryte gdy kategoria zwinięta */}
                                    <div
                                        className={`overflow-hidden transition-all duration-200 ${isCollapsed ? 'max-h-0 opacity-0' : 'max-h-[500px] opacity-100 mt-2'}`}
                                    >
                                        <div className="flex flex-wrap gap-1.5 pl-3 pr-1 py-1">
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
                                </div>
                            );
                        })}
                    </div>
                </div>
            </div>

            {/* Sekcja Moje etykiety - zwijalna */}
            <div className="mt-4">
                {/* Nagłówek */}
                <div
                    className="mb-2 flex items-center justify-between cursor-pointer group"
                    onClick={() => setIsLabelsCollapsed(!isLabelsCollapsed)}
                    role="button"
                    aria-expanded={!isLabelsCollapsed}
                >
                    <label className="text-sm font-medium cursor-pointer flex items-center gap-2" style={{ color: 'var(--color-text)' }}>
                        🏷️ Moje etykiety
                        <span
                            className={`neu-tag p-1 transition-all group-hover:scale-110 ${isLabelsCollapsed ? 'active' : ''}`}
                            style={{ borderRadius: '50%' }}
                        >
                            <svg
                                className={`h-3 w-3 transition-transform duration-300 ${isLabelsCollapsed ? '' : 'rotate-180'}`}
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                                style={{ color: isLabelsCollapsed ? 'white' : 'var(--color-text-muted)' }}
                            >
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                            </svg>
                        </span>
                    </label>
                    {!isLabelsCollapsed && (
                        <button
                            onClick={(e) => { e.stopPropagation(); setIsLabelManagerOpen(!isLabelManagerOpen); }}
                            className="neu-tag text-xs"
                            style={{ color: 'var(--color-accent)' }}
                        >
                            ⚙️ Zarządzaj
                        </button>
                    )}
                </div>

                {/* Zawartość - ukryta gdy zwinięta */}
                <div
                    className={`overflow-hidden transition-all duration-300 ease-in-out ${isLabelsCollapsed ? 'max-h-0 opacity-0' : 'max-h-[500px] opacity-100'}`}
                >
                    {/* LabelManager */}
                    {isLabelManagerOpen && (
                        <div className="mb-3 neu-concave p-3">
                            <LabelManager onLabelsChange={refreshLabels} />
                        </div>
                    )}

                    {/* Filtry etykiet */}
                    {userLabels.length > 0 ? (
                        <div className="flex flex-wrap gap-1.5">
                            {userLabels.map(label => (
                                <button
                                    key={label.id}
                                    onClick={() => handleLabelToggle(label.id)}
                                    className={`text-xs px-2.5 py-1 rounded-full transition-all ${filters.labels.includes(label.id)
                                        ? 'ring-2 ring-offset-1'
                                        : 'opacity-80 hover:opacity-100'
                                        }`}
                                    style={{
                                        backgroundColor: LABEL_COLORS[label.color].hex,
                                        color: 'white'
                                    }}
                                >
                                    {label.name}
                                </button>
                            ))}
                        </div>
                    ) : (
                        <p className="text-xs" style={{ color: 'var(--color-text-muted)' }}>
                            Brak etykiet. Kliknij "Zarządzaj" aby dodać.
                        </p>
                    )}
                </div>
            </div>

            {/* Aktywne filtry (podsumowanie) */}
            {(filters.tags.length > 0 || filters.labels.length > 0) && (
                <div className="pt-4" style={{ borderTop: '1px solid var(--shadow-dark)' }}>
                    <span className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>
                        Aktywne filtry ({filters.tags.length + filters.labels.length}):
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
                        {filters.labels.map(labelId => {
                            const label = userLabels.find(l => l.id === labelId);
                            if (!label) return null;
                            return (
                                <span
                                    key={labelId}
                                    className="text-xs inline-flex items-center px-2 py-0.5 rounded-full"
                                    style={{ backgroundColor: LABEL_COLORS[label.color].hex, color: 'white' }}
                                >
                                    {label.name}
                                    <button
                                        onClick={() => handleLabelToggle(labelId)}
                                        className="ml-1.5 hover:scale-110 transition-transform opacity-70 hover:opacity-100"
                                        aria-label={`Usuń etykietę ${label.name}`}
                                    >
                                        ×
                                    </button>
                                </span>
                            );
                        })}
                    </div>
                </div>
            )}
        </div>
    );
}
