'use client';

// src/components/LabelSelector.tsx
// Wybór etykiet dla pojedynczego leku (dropdown z checkboxami)

import { useState, useEffect, useRef } from 'react';
import type { UserLabel, LabelColor } from '@/lib/types';
import { LABEL_COLORS, MAX_LABELS_PER_MEDICINE, MAX_LABELS_GLOBAL } from '@/lib/types';
import { getLabels, createLabel, getLabelsByIds } from '@/lib/labelStorage';

interface LabelSelectorProps {
    selectedLabelIds: string[];
    onChange: (labelIds: string[]) => void;
    onLabelsCreated?: () => void;
}

export default function LabelSelector({ selectedLabelIds, onChange, onLabelsCreated }: LabelSelectorProps) {
    const [isOpen, setIsOpen] = useState(false);
    const [labels, setLabels] = useState<UserLabel[]>([]);
    const [isCreating, setIsCreating] = useState(false);
    const [newName, setNewName] = useState('');
    const [newColor, setNewColor] = useState<LabelColor>('green');
    const [error, setError] = useState('');
    const dropdownRef = useRef<HTMLDivElement>(null);

    // Załaduj etykiety
    useEffect(() => {
        setLabels(getLabels());
    }, [isOpen]);

    // Zamknij dropdown przy kliknięciu na zewnątrz
    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
                setIsOpen(false);
                setIsCreating(false);
            }
        };

        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    const selectedLabels = getLabelsByIds(selectedLabelIds);
    const canAddMore = selectedLabelIds.length < MAX_LABELS_PER_MEDICINE;

    const handleToggle = (labelId: string) => {
        if (selectedLabelIds.includes(labelId)) {
            onChange(selectedLabelIds.filter(id => id !== labelId));
        } else if (canAddMore) {
            onChange([...selectedLabelIds, labelId]);
        }
    };

    const handleCreate = () => {
        setError('');

        if (!newName.trim()) {
            setError('Nazwa jest wymagana');
            return;
        }

        if (labels.length >= MAX_LABELS_GLOBAL) {
            setError(`Limit ${MAX_LABELS_GLOBAL} etykiet`);
            return;
        }

        const result = createLabel(newName.trim(), newColor);

        if (!result) {
            setError('Etykieta już istnieje');
            return;
        }

        setLabels(getLabels());
        setNewName('');
        setNewColor('green');
        setIsCreating(false);
        onLabelsCreated?.();

        // Powiadom inne komponenty o nowej etykiecie
        window.dispatchEvent(new CustomEvent('labelsUpdated'));

        // Automatycznie zaznacz nową etykietę
        if (canAddMore) {
            onChange([...selectedLabelIds, result.id]);
        }
    };

    const colorOptions = Object.entries(LABEL_COLORS) as [LabelColor, typeof LABEL_COLORS[LabelColor]][];

    return (
        <div className="relative" ref={dropdownRef}>
            {/* Przycisk otwierający */}
            <button
                onClick={(e) => { e.stopPropagation(); setIsOpen(!isOpen); }}
                className="neu-tag text-xs flex items-center gap-1"
                style={{ color: 'var(--color-accent)' }}
            >
                🏷️ Etykiety
                {selectedLabelIds.length > 0 && (
                    <span className="ml-1 px-1.5 py-0.5 rounded-full text-white text-xs"
                        style={{ backgroundColor: 'var(--color-accent)' }}>
                        {selectedLabelIds.length}
                    </span>
                )}
            </button>

            {/* Dropdown */}
            {isOpen && (
                <div
                    className="absolute left-0 bottom-full mb-1 z-[100] neu-flat p-3 min-w-[200px] animate-popIn"
                    onClick={(e) => e.stopPropagation()}
                >
                    {/* Limit info */}
                    {!canAddMore && (
                        <p className="text-xs mb-2" style={{ color: 'var(--color-warning)' }}>
                            Max {MAX_LABELS_PER_MEDICINE} etykiet na lek
                        </p>
                    )}

                    {/* Lista etykiet */}
                    {labels.length > 0 ? (
                        <div className="space-y-1.5 mb-2">
                            {labels.map(label => {
                                const isSelected = selectedLabelIds.includes(label.id);
                                const isDisabled = !isSelected && !canAddMore;

                                return (
                                    <button
                                        key={label.id}
                                        onClick={() => !isDisabled && handleToggle(label.id)}
                                        className={`w-full flex items-center gap-2 px-2 py-1.5 rounded-lg text-left text-xs transition-all ${isSelected ? 'neu-tag active' : 'neu-tag'
                                            } ${isDisabled ? 'opacity-50 cursor-not-allowed' : ''}`}
                                        disabled={isDisabled}
                                    >
                                        <span
                                            className="w-3 h-3 rounded-full flex-shrink-0"
                                            style={{ backgroundColor: LABEL_COLORS[label.color].hex }}
                                        />
                                        <span className={isSelected ? 'text-white' : ''}>{label.name}</span>
                                        {isSelected && <span className="ml-auto">✓</span>}
                                    </button>
                                );
                            })}
                        </div>
                    ) : !isCreating && (
                        <p className="text-xs mb-2" style={{ color: 'var(--color-text-muted)' }}>
                            Brak etykiet
                        </p>
                    )}

                    {/* Formularz tworzenia */}
                    {isCreating ? (
                        <div className="space-y-2 pt-2" style={{ borderTop: '1px solid var(--shadow-dark)' }}>
                            <input
                                type="text"
                                value={newName}
                                onChange={(e) => setNewName(e.target.value)}
                                placeholder="Nazwa..."
                                className="neu-input text-xs w-full"
                                style={{ padding: '0.375rem' }}
                                maxLength={20}
                                autoFocus
                                onKeyDown={(e) => e.key === 'Enter' && handleCreate()}
                            />
                            <div className="flex flex-wrap gap-1">
                                {colorOptions.map(([key, value]) => (
                                    <button
                                        key={key}
                                        onClick={() => setNewColor(key)}
                                        className={`w-5 h-5 rounded-full ${newColor === key ? 'ring-2 ring-offset-1' : ''}`}
                                        style={{ backgroundColor: value.hex }}
                                        title={value.name}
                                    />
                                ))}
                            </div>
                            {error && <p className="text-xs" style={{ color: 'var(--color-error)' }}>{error}</p>}
                            <div className="flex gap-1">
                                <button onClick={handleCreate} className="neu-tag text-xs" style={{ color: 'var(--color-success)' }}>Zapisz</button>
                                <button onClick={() => { setIsCreating(false); setError(''); }} className="neu-tag text-xs">Anuluj</button>
                            </div>
                        </div>
                    ) : labels.length < MAX_LABELS_GLOBAL && (
                        <button
                            onClick={() => setIsCreating(true)}
                            className="w-full neu-tag text-xs mt-1"
                            style={{ color: 'var(--color-accent)' }}
                        >
                            + Nowa etykieta
                        </button>
                    )}
                </div>
            )}

            {/* Wyświetlanie wybranych etykiet (poza dropdownem) */}
            {selectedLabels.length > 0 && !isOpen && (
                <div className="flex flex-wrap gap-1 mt-1.5">
                    {selectedLabels.map(label => (
                        <span
                            key={label.id}
                            className="inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded-full"
                            style={{ backgroundColor: LABEL_COLORS[label.color].hex, color: 'white' }}
                        >
                            {label.name}
                            <button
                                onClick={(e) => { e.stopPropagation(); handleToggle(label.id); }}
                                className="opacity-70 hover:opacity-100"
                            >
                                ×
                            </button>
                        </span>
                    ))}
                </div>
            )}
        </div>
    );
}
