'use client';

// src/components/LabelManager.tsx
// Zarządzanie etykietami użytkownika (tworzenie, edycja, usuwanie)

import { useState, useEffect } from 'react';
import type { UserLabel, LabelColor } from '@/lib/types';
import { LABEL_COLORS, MAX_LABELS_GLOBAL } from '@/lib/types';
import { getLabels, createLabel, deleteLabel, updateLabel } from '@/lib/labelStorage';

interface LabelManagerProps {
    onLabelsChange?: () => void;
}

export default function LabelManager({ onLabelsChange }: LabelManagerProps) {
    const [labels, setLabels] = useState<UserLabel[]>([]);
    const [isAdding, setIsAdding] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [newName, setNewName] = useState('');
    const [newColor, setNewColor] = useState<LabelColor>('green');
    const [error, setError] = useState('');

    // Załaduj etykiety przy montowaniu
    useEffect(() => {
        setLabels(getLabels());
    }, []);

    const refreshLabels = () => {
        setLabels(getLabels());
        onLabelsChange?.();
    };

    const handleCreate = () => {
        setError('');

        if (!newName.trim()) {
            setError('Nazwa jest wymagana');
            return;
        }

        const result = createLabel(newName.trim(), newColor);

        if (!result) {
            if (labels.length >= MAX_LABELS_GLOBAL) {
                setError(`Maksymalnie ${MAX_LABELS_GLOBAL} etykiet`);
            } else {
                setError('Etykieta o tej nazwie już istnieje');
            }
            return;
        }

        setNewName('');
        setNewColor('green');
        setIsAdding(false);
        refreshLabels();
    };

    const handleDelete = (id: string) => {
        if (confirm('Usunąć etykietę? Zostanie usunięta ze wszystkich leków.')) {
            deleteLabel(id);
            refreshLabels();
        }
    };

    const handleUpdate = (id: string, name: string, color: LabelColor) => {
        const result = updateLabel(id, { name, color });
        if (!result) {
            setError('Etykieta o tej nazwie już istnieje');
            return;
        }
        setEditingId(null);
        refreshLabels();
    };

    const colorOptions = Object.entries(LABEL_COLORS) as [LabelColor, typeof LABEL_COLORS[LabelColor]][];

    return (
        <div className="space-y-3">
            {/* Nagłówek */}
            <div className="flex items-center justify-between">
                <span className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>
                    Moje etykiety ({labels.length}/{MAX_LABELS_GLOBAL})
                </span>
                {!isAdding && labels.length < MAX_LABELS_GLOBAL && (
                    <button
                        onClick={() => setIsAdding(true)}
                        className="neu-tag text-xs"
                        style={{ color: 'var(--color-accent)' }}
                    >
                        + Dodaj
                    </button>
                )}
            </div>

            {/* Formularz dodawania */}
            {isAdding && (
                <div className="neu-concave p-3 space-y-2">
                    <input
                        type="text"
                        value={newName}
                        onChange={(e) => setNewName(e.target.value)}
                        placeholder="Nazwa etykiety..."
                        className="neu-input text-sm"
                        style={{ padding: '0.5rem' }}
                        maxLength={20}
                        autoFocus
                    />

                    {/* Wybór koloru */}
                    <div className="flex flex-wrap gap-1.5">
                        {colorOptions.map(([key, value]) => (
                            <button
                                key={key}
                                onClick={() => setNewColor(key)}
                                className={`w-6 h-6 rounded-full transition-all ${newColor === key ? 'ring-2 ring-offset-2' : ''}`}
                                style={{
                                    backgroundColor: value.hex,
                                    outlineColor: newColor === key ? value.hex : undefined
                                }}
                                title={value.name}
                            />
                        ))}
                    </div>

                    {error && (
                        <p className="text-xs" style={{ color: 'var(--color-error)' }}>{error}</p>
                    )}

                    <div className="flex gap-2">
                        <button
                            onClick={handleCreate}
                            className="neu-tag text-xs"
                            style={{ color: 'var(--color-success)' }}
                        >
                            Zapisz
                        </button>
                        <button
                            onClick={() => { setIsAdding(false); setError(''); setNewName(''); }}
                            className="neu-tag text-xs"
                        >
                            Anuluj
                        </button>
                    </div>
                </div>
            )}

            {/* Lista etykiet */}
            {labels.length > 0 ? (
                <div className="flex flex-wrap gap-1.5">
                    {labels.map(label => (
                        <div
                            key={label.id}
                            className="group relative"
                        >
                            {editingId === label.id ? (
                                <EditLabelForm
                                    label={label}
                                    onSave={(name, color) => handleUpdate(label.id, name, color)}
                                    onCancel={() => setEditingId(null)}
                                />
                            ) : (
                                <span
                                    className="neu-label inline-flex items-center gap-1 text-xs px-2 py-1 rounded-full cursor-pointer"
                                    style={{
                                        backgroundColor: LABEL_COLORS[label.color].hex,
                                        color: 'white'
                                    }}
                                    onClick={() => setEditingId(label.id)}
                                    title="Kliknij, aby edytować"
                                >
                                    {label.name}
                                    <button
                                        onClick={(e) => { e.stopPropagation(); handleDelete(label.id); }}
                                        className="ml-0.5 opacity-60 hover:opacity-100"
                                    >
                                        ×
                                    </button>
                                </span>
                            )}
                        </div>
                    ))}
                </div>
            ) : !isAdding && (
                <p className="text-xs" style={{ color: 'var(--color-text-muted)' }}>
                    Brak etykiet. Dodaj pierwszą etykietę.
                </p>
            )}
        </div>
    );
}

// Komponent edycji etykiety
function EditLabelForm({
    label,
    onSave,
    onCancel
}: {
    label: UserLabel;
    onSave: (name: string, color: LabelColor) => void;
    onCancel: () => void;
}) {
    const [name, setName] = useState(label.name);
    const [color, setColor] = useState<LabelColor>(label.color);
    const colorOptions = Object.entries(LABEL_COLORS) as [LabelColor, typeof LABEL_COLORS[LabelColor]][];

    return (
        <div className="neu-concave p-2 space-y-2" style={{ minWidth: '150px' }}>
            <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="neu-input text-xs w-full"
                style={{ padding: '0.375rem' }}
                maxLength={20}
                autoFocus
            />
            <div className="flex flex-wrap gap-1">
                {colorOptions.map(([key, value]) => (
                    <button
                        key={key}
                        onClick={() => setColor(key)}
                        className={`w-5 h-5 rounded-full ${color === key ? 'ring-2 ring-offset-1' : ''}`}
                        style={{ backgroundColor: value.hex }}
                    />
                ))}
            </div>
            <div className="flex gap-1">
                <button onClick={() => onSave(name, color)} className="neu-tag text-xs" style={{ color: 'var(--color-success)' }}>✓</button>
                <button onClick={onCancel} className="neu-tag text-xs">✕</button>
            </div>
        </div>
    );
}
