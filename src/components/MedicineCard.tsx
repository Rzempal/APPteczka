'use client';

// src/components/MedicineCard.tsx
// Karta pojedynczego leku

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

    const statusColors = {
        expired: 'bg-red-100 border-red-400 dark:bg-red-900/30',
        'expiring-soon': 'bg-yellow-100 border-yellow-400 dark:bg-yellow-900/30',
        valid: 'bg-green-100 border-green-400 dark:bg-green-900/30',
        unknown: 'bg-gray-100 border-gray-300 dark:bg-gray-800'
    };

    const statusLabels = {
        expired: '⚠️ Przeterminowany',
        'expiring-soon': '⏰ Kończy się ważność',
        valid: '✅ Ważny',
        unknown: '❓ Brak daty'
    };

    return (
        <article
            className={`rounded-xl border-2 p-5 shadow-sm transition-all hover:shadow-md ${statusColors[expiryStatus]}`}
        >
            {/* Nagłówek */}
            <header className="mb-3 flex items-start justify-between">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                    {medicine.nazwa || <span className="italic text-gray-500">Nazwa nieznana</span>}
                </h3>
                <button
                    onClick={() => onDelete(medicine.id)}
                    className="rounded-full p-1 text-gray-400 hover:bg-red-100 hover:text-red-600 transition-colors"
                    title="Usuń lek"
                    aria-label="Usuń lek"
                >
                    <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </header>

            {/* Opis */}
            <p className="mb-3 text-sm text-gray-600 dark:text-gray-300">{medicine.opis}</p>

            {/* Wskazania */}
            <div className="mb-3">
                <span className="text-xs font-medium text-gray-500 dark:text-gray-400">Wskazania:</span>
                <ul className="mt-1 list-inside list-disc text-sm text-gray-700 dark:text-gray-300">
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
                        className="rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800 dark:bg-blue-900 dark:text-blue-200"
                    >
                        {tag}
                    </span>
                ))}
            </div>

            {/* Termin ważności */}
            <div className="border-t border-gray-200 pt-3 dark:border-gray-700">
                <div className="flex items-center justify-between">
                    <div>
                        <span className="text-xs font-medium text-gray-500 dark:text-gray-400">Termin ważności:</span>
                        {!isEditing ? (
                            <div className="flex items-center gap-2">
                                <span className="text-sm font-medium">{formatDate(medicine.terminWaznosci)}</span>
                                <span className="text-xs">{statusLabels[expiryStatus]}</span>
                            </div>
                        ) : (
                            <input
                                type="date"
                                value={expiryDate}
                                onChange={(e) => setExpiryDate(e.target.value)}
                                className="mt-1 block rounded border border-gray-300 px-2 py-1 text-sm dark:bg-gray-700 dark:border-gray-600"
                            />
                        )}
                    </div>

                    {!isEditing ? (
                        <button
                            onClick={() => setIsEditing(true)}
                            className="text-xs text-blue-600 hover:underline dark:text-blue-400"
                        >
                            Edytuj datę
                        </button>
                    ) : (
                        <div className="flex gap-2">
                            <button
                                onClick={handleSaveExpiry}
                                className="text-xs text-green-600 hover:underline"
                            >
                                Zapisz
                            </button>
                            <button
                                onClick={() => setIsEditing(false)}
                                className="text-xs text-gray-500 hover:underline"
                            >
                                Anuluj
                            </button>
                        </div>
                    )}
                </div>
            </div>

            {/* Data dodania */}
            <div className="mt-2 text-xs text-gray-400">
                Dodano: {formatDate(medicine.dataDodania)}
            </div>
        </article>
    );
}
