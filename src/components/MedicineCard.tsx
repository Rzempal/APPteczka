'use client';

// src/components/MedicineCard.tsx
// Karta pojedynczego leku - Neumorphism Style

import { useState } from 'react';
import type { Medicine } from '@/lib/types';

interface MedicineCardProps {
    medicine: Medicine;
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
 * Formatuje datę do czytelnej postaci
 */
function formatDate(dateString?: string): string {
    if (!dateString) return 'Nie ustawiono';
    return new Date(dateString).toLocaleDateString('pl-PL');
}

export default function MedicineCard({ medicine, onDelete, onUpdateExpiry }: MedicineCardProps) {
    const [isEditing, setIsEditing] = useState(false);
    const [expiryDate, setExpiryDate] = useState(medicine.terminWaznosci || '');

    const expiryStatus = getExpiryStatus(medicine.terminWaznosci);

    const handleSaveExpiry = () => {
        onUpdateExpiry(medicine.id, expiryDate || undefined);
        setIsEditing(false);
    };

    const statusClasses = {
        expired: 'neu-status-error',
        'expiring-soon': 'neu-status-warning',
        valid: 'neu-status-valid',
        unknown: 'neu-status-unknown'
    };

    const statusLabels = {
        expired: '⚠️ Przeterminowany',
        'expiring-soon': '⏰ Kończy się ważność',
        valid: '✅ Ważny',
        unknown: '❓ Brak daty'
    };

    return (
        <article
            className={`p-5 rounded-2xl transition-all duration-300 hover:-translate-y-1 ${statusClasses[expiryStatus]}`}
            style={{ borderRadius: '20px' }}
        >
            {/* Nagłówek */}
            <header className="mb-3 flex items-start justify-between">
                <h3 className="text-lg font-semibold" style={{ color: 'var(--color-text)' }}>
                    {medicine.nazwa || <span className="italic" style={{ color: 'var(--color-text-muted)' }}>Nazwa nieznana</span>}
                </h3>
                <button
                    onClick={() => onDelete(medicine.id)}
                    className="neu-tag p-2 hover:scale-110 transition-transform"
                    title="Usuń lek"
                    aria-label="Usuń lek"
                    style={{ borderRadius: '50%' }}
                >
                    <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" style={{ color: 'var(--color-error)' }}>
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </header>

            {/* Opis */}
            <p className="mb-3 text-sm" style={{ color: 'var(--color-text-muted)' }}>{medicine.opis}</p>

            {/* Wskazania */}
            <div className="mb-3">
                <span className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>Wskazania:</span>
                <ul className="mt-1 list-inside list-disc text-sm" style={{ color: 'var(--color-text)' }}>
                    {medicine.wskazania.map((wskazanie, i) => (
                        <li key={i}>{wskazanie}</li>
                    ))}
                </ul>
            </div>

            {/* Tagi */}
            <div className="mb-4 flex flex-wrap gap-1.5">
                {medicine.tagi.map((tag, i) => (
                    <span
                        key={i}
                        className="neu-tag text-xs"
                        style={{
                            background: 'linear-gradient(145deg, var(--color-accent-light), var(--color-accent))',
                            color: 'white',
                            padding: '0.25rem 0.625rem'
                        }}
                    >
                        {tag}
                    </span>
                ))}
            </div>

            {/* Termin ważności */}
            <div className="pt-3" style={{ borderTop: '1px solid var(--shadow-dark)' }}>
                <div className="flex items-center justify-between">
                    <div>
                        <span className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>Termin ważności:</span>
                        {!isEditing ? (
                            <div className="flex items-center gap-2">
                                <span className="text-sm font-medium" style={{ color: 'var(--color-text)' }}>{formatDate(medicine.terminWaznosci)}</span>
                                <span className="text-xs">{statusLabels[expiryStatus]}</span>
                            </div>
                        ) : (
                            <input
                                type="date"
                                value={expiryDate}
                                onChange={(e) => setExpiryDate(e.target.value)}
                                className="neu-input mt-1 text-sm"
                                style={{ padding: '0.5rem', fontSize: '0.875rem' }}
                            />
                        )}
                    </div>

                    {!isEditing ? (
                        <button
                            onClick={() => setIsEditing(true)}
                            className="neu-tag text-xs"
                            style={{ color: 'var(--color-accent)' }}
                        >
                            Edytuj datę
                        </button>
                    ) : (
                        <div className="flex gap-2">
                            <button
                                onClick={handleSaveExpiry}
                                className="neu-tag text-xs"
                                style={{ color: 'var(--color-success)' }}
                            >
                                Zapisz
                            </button>
                            <button
                                onClick={() => setIsEditing(false)}
                                className="neu-tag text-xs"
                            >
                                Anuluj
                            </button>
                        </div>
                    )}
                </div>
            </div>

            {/* Data dodania */}
            <div className="mt-2 text-xs" style={{ color: 'var(--color-text-muted)' }}>
                Dodano: {formatDate(medicine.dataDodania)}
            </div>
        </article>
    );
}
