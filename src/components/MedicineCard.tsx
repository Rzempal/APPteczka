'use client';

// src/components/MedicineCard.tsx
// Karta pojedynczego leku - Neumorphism Style

import { useState } from 'react';
import type { Medicine } from '@/lib/types';
import LabelSelector from './LabelSelector';
import PdfModal from './PdfModal';
import { searchMedicineInRpl, type RplSearchResult } from '@/actions/rplActions';

interface MedicineCardProps {
    medicine: Medicine;
    onDelete: (id: string) => void;
    onUpdateExpiry: (id: string, date: string | undefined) => void;
    onUpdateLabels: (id: string, labelIds: string[]) => void;
    onUpdateNote: (id: string, note: string | undefined) => void;
    onUpdateLeaflet: (id: string, url: string | undefined) => void;
    isCollapsed?: boolean;
    onToggleCollapse?: () => void;
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

export default function MedicineCard({ medicine, onDelete, onUpdateExpiry, onUpdateLabels, onUpdateNote, onUpdateLeaflet, isCollapsed = false, onToggleCollapse }: MedicineCardProps) {
    const [isEditing, setIsEditing] = useState(false);
    const [expiryDate, setExpiryDate] = useState(medicine.terminWaznosci || '');
    const [isEditingNote, setIsEditingNote] = useState(false);
    const [noteText, setNoteText] = useState(medicine.notatka || '');

    // Stany dla wyszukiwarki ulotek
    const [isSearchingLeaflet, setIsSearchingLeaflet] = useState(false);
    const [leafletSearchResults, setLeafletSearchResults] = useState<RplSearchResult[]>([]);
    const [leafletLoading, setLeafletLoading] = useState(false);
    const [isPdfModalOpen, setIsPdfModalOpen] = useState(false);
    const [leafletSearchQuery, setLeafletSearchQuery] = useState('');

    const expiryStatus = getExpiryStatus(medicine.terminWaznosci);

    const handleSaveExpiry = () => {
        onUpdateExpiry(medicine.id, expiryDate || undefined);
        setIsEditing(false);
    };

    const handleSaveNote = () => {
        onUpdateNote(medicine.id, noteText.trim() || undefined);
        setIsEditingNote(false);
    };

    // Otwórz panel wyszukiwania
    const handleOpenLeafletSearch = () => {
        setLeafletSearchQuery(medicine.nazwa || '');
        setIsSearchingLeaflet(true);
        setLeafletSearchResults([]);
    };

    // Wyszukiwanie ulotki w RPL
    const handleSearchLeaflet = async (query?: string) => {
        const searchQuery = query || leafletSearchQuery;
        if (!searchQuery || searchQuery.trim().length < 3) return;

        setLeafletLoading(true);

        try {
            const results = await searchMedicineInRpl(searchQuery.trim());
            setLeafletSearchResults(results);
        } catch (error) {
            console.error('Błąd wyszukiwania ulotki:', error);
            setLeafletSearchResults([]);
        } finally {
            setLeafletLoading(false);
        }
    };

    // Przypisanie ulotki do leku
    const handleSelectLeaflet = (url: string) => {
        onUpdateLeaflet(medicine.id, url);
        setIsSearchingLeaflet(false);
        setLeafletSearchResults([]);
        setLeafletSearchQuery('');
    };

    // Odepnięcie ulotki
    const handleRemoveLeaflet = () => {
        onUpdateLeaflet(medicine.id, undefined);
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
        <>
            <article
                className={`p-5 rounded-2xl transition-all duration-300 hover:-translate-y-1 ${statusClasses[expiryStatus]}`}
                style={{ borderRadius: '20px', overflow: 'visible' }}
            >
                {/* Nagłówek - klikalny do zwijania */}
                <header
                    className="mb-3 flex items-start justify-between cursor-pointer group"
                    onClick={onToggleCollapse}
                    role="button"
                    aria-expanded={!isCollapsed}
                >
                    <h3 className="text-lg font-semibold" style={{ color: 'var(--color-text)' }}>
                        {medicine.nazwa || <span className="italic" style={{ color: 'var(--color-text-muted)' }}>Nazwa nieznana</span>}
                    </h3>
                    <span
                        className={`neu-tag p-2 transition-all group-hover:scale-110 ${isCollapsed ? 'active' : ''}`}
                        style={{ borderRadius: '50%' }}
                    >
                        <svg
                            className={`h-4 w-4 transition-transform duration-300 ${isCollapsed ? '' : 'rotate-180'}`}
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                            style={{ color: 'var(--color-text-muted)' }}
                        >
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                        </svg>
                    </span>
                </header>

                {/* Opis - zawsze widoczny */}
                <p className="mb-3 text-sm" style={{ color: 'var(--color-text-muted)' }}>{medicine.opis}</p>

                {/* Szczegóły wewnętrzne - ukryte gdy zwinięte (BEZ etykiet - one są poza overflow-hidden) */}
                <div
                    className={`overflow-hidden transition-all duration-300 ease-in-out ${isCollapsed ? 'max-h-0 opacity-0' : 'max-h-[400px] opacity-100'}`}
                >
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
                    <div className="mb-3 flex flex-wrap gap-1.5 pr-1">
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
                </div>

                {/* Etykiety użytkownika - POZA overflow-hidden, aby dropdown był widoczny */}
                {!isCollapsed && (
                    <div className="mb-4 pr-1">
                        <LabelSelector
                            selectedLabelIds={medicine.labels || []}
                            onChange={(labelIds) => onUpdateLabels(medicine.id, labelIds)}
                            buttonPosition="right"
                        />
                    </div>
                )}

                {/* Sekcje poniżej etykiet - ukryte gdy zwinięte */}
                {!isCollapsed && (
                    <>
                        {/* Separator przed notatką */}
                        <div className="pt-3 mb-3 pr-1" style={{ borderTop: '1px solid var(--shadow-dark)' }}>
                            <div className="flex items-start justify-between gap-3">
                                <div className="flex-1">
                                    <span className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>Notatka:</span>
                                    {!isEditingNote ? (
                                        <p className="mt-1 text-sm" style={{ color: medicine.notatka ? 'var(--color-text)' : 'var(--color-text-muted)' }}>
                                            {medicine.notatka || 'Brak notatki'}
                                        </p>
                                    ) : (
                                        <textarea
                                            value={noteText}
                                            onChange={(e) => setNoteText(e.target.value)}
                                            onClick={(e) => e.stopPropagation()}
                                            className="neu-input mt-1 text-sm w-full resize-none"
                                            style={{ padding: '0.5rem', fontSize: '0.875rem', minHeight: '4rem' }}
                                            placeholder="Dodaj notatkę..."
                                            maxLength={500}
                                            autoFocus
                                        />
                                    )}
                                </div>

                                {!isEditingNote ? (
                                    <button
                                        onClick={(e) => { e.stopPropagation(); setIsEditingNote(true); setNoteText(medicine.notatka || ''); }}
                                        className="neu-tag text-xs flex-shrink-0"
                                        style={{ color: 'var(--color-accent)' }}
                                    >
                                        Edytuj notkę
                                    </button>
                                ) : (
                                    <div className="flex gap-2 flex-shrink-0">
                                        <button
                                            onClick={(e) => { e.stopPropagation(); handleSaveNote(); }}
                                            className="neu-tag text-xs"
                                            style={{ color: 'var(--color-success)' }}
                                        >
                                            Zapisz
                                        </button>
                                        <button
                                            onClick={(e) => { e.stopPropagation(); setIsEditingNote(false); }}
                                            className="neu-tag text-xs"
                                        >
                                            Anuluj
                                        </button>
                                    </div>
                                )}
                            </div>
                        </div>

                        {/* Termin ważności */}
                        <div className="pt-3 pr-1" style={{ borderTop: '1px solid var(--shadow-dark)' }}>
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
                                            onClick={(e) => e.stopPropagation()}
                                            className="neu-input mt-1 text-sm"
                                            style={{ padding: '0.5rem', fontSize: '0.875rem' }}
                                        />
                                    )}
                                </div>

                                {!isEditing ? (
                                    <button
                                        onClick={(e) => { e.stopPropagation(); setIsEditing(true); }}
                                        className="neu-tag text-xs"
                                        style={{ color: 'var(--color-accent)' }}
                                    >
                                        Edytuj datę
                                    </button>
                                ) : (
                                    <div className="flex gap-2">
                                        <button
                                            onClick={(e) => { e.stopPropagation(); handleSaveExpiry(); }}
                                            className="neu-tag text-xs"
                                            style={{ color: 'var(--color-success)' }}
                                        >
                                            Zapisz
                                        </button>
                                        <button
                                            onClick={(e) => { e.stopPropagation(); setIsEditing(false); }}
                                            className="neu-tag text-xs"
                                        >
                                            Anuluj
                                        </button>
                                    </div>
                                )}
                            </div>
                        </div>

                        {/* Ulotka PDF */}
                        <div className="pt-3 pr-1" style={{ borderTop: '1px solid var(--shadow-dark)' }}>
                            <span className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>Ulotka PDF:</span>

                            {medicine.leafletUrl ? (
                                /* Lek ma ulotkę - pokaż przycisk otwierający modal i przycisk odpięcia */
                                <div className="mt-1 flex items-center justify-between gap-2">
                                    <button
                                        onClick={(e) => { e.stopPropagation(); setIsPdfModalOpen(true); }}
                                        className="neu-tag text-xs flex items-center gap-1 hover:scale-105 transition-transform"
                                        style={{ color: 'var(--color-accent)' }}
                                    >
                                        📄 Pokaż ulotkę PDF
                                    </button>
                                    <button
                                        onClick={(e) => { e.stopPropagation(); handleRemoveLeaflet(); }}
                                        className="neu-tag text-xs"
                                        style={{ color: 'var(--color-error)' }}
                                        title="Odepnij ulotkę"
                                    >
                                        Odepnij
                                    </button>
                                </div>
                            ) : (
                                /* Brak ulotki - pokaż przycisk szukania lub wyniki */
                                <div className="mt-1">
                                    {!isSearchingLeaflet ? (
                                        <button
                                            onClick={(e) => { e.stopPropagation(); handleOpenLeafletSearch(); }}
                                            className="neu-tag text-xs flex items-center gap-1"
                                            style={{ color: 'var(--color-accent)' }}
                                            title="Wyszukaj ulotkę w Rejestrze Produktów Leczniczych"
                                        >
                                            🔍 Znajdź i podepnij ulotkę
                                        </button>
                                    ) : (
                                        /* Panel wyników wyszukiwania */
                                        <div
                                            className="rounded-lg p-3 animate-fadeIn"
                                            style={{ background: 'var(--color-bg-dark)', opacity: 0.95 }}
                                            onClick={(e) => e.stopPropagation()}
                                        >
                                            <div className="flex justify-between items-center mb-2">
                                                <span className="text-xs font-bold" style={{ color: 'var(--color-text)' }}>
                                                    Szukaj w bazie MZ:
                                                </span>
                                                <button
                                                    onClick={() => { setIsSearchingLeaflet(false); setLeafletSearchResults([]); setLeafletSearchQuery(''); }}
                                                    className="text-xs px-2 py-1 rounded"
                                                    style={{ color: 'var(--color-error)' }}
                                                >
                                                    ✕ Anuluj
                                                </button>
                                            </div>

                                            {/* Pole wyszukiwania */}
                                            <div className="flex gap-2 mb-2">
                                                <input
                                                    type="text"
                                                    value={leafletSearchQuery}
                                                    onChange={(e) => setLeafletSearchQuery(e.target.value)}
                                                    onKeyDown={(e) => { if (e.key === 'Enter') handleSearchLeaflet(); }}
                                                    placeholder="Wpisz nazwę leku..."
                                                    className="neu-input flex-1 text-xs"
                                                    style={{ padding: '0.5rem' }}
                                                />
                                                <button
                                                    onClick={() => handleSearchLeaflet()}
                                                    disabled={leafletSearchQuery.trim().length < 3 || leafletLoading}
                                                    className="neu-tag text-xs"
                                                    style={{ color: 'var(--color-accent)' }}
                                                >
                                                    {leafletLoading ? '...' : '🔍'}
                                                </button>
                                            </div>

                                            {leafletLoading && (
                                                <div className="text-xs p-2" style={{ color: 'var(--color-text-muted)' }}>
                                                    Szukanie w Rejestrze Produktów Leczniczych...
                                                </div>
                                            )}

                                            {!leafletLoading && leafletSearchResults.length === 0 && leafletSearchQuery.trim().length >= 3 && (
                                                <div className="text-xs p-2" style={{ color: 'var(--color-text-muted)' }}>
                                                    Nie znaleziono - spróbuj inną nazwę lub tylko pierwsze słowo
                                                </div>
                                            )}

                                            {!leafletLoading && leafletSearchResults.length > 0 && (
                                                <div className="max-h-40 overflow-y-auto space-y-1 custom-scrollbar">
                                                    {leafletSearchResults.map((res) => (
                                                        <button
                                                            key={res.id}
                                                            onClick={() => handleSelectLeaflet(res.ulotkaUrl)}
                                                            className="w-full text-left text-xs p-2 rounded transition-colors flex justify-between group neu-tag"
                                                            style={{ marginBottom: '0.25rem' }}
                                                        >
                                                            <span style={{ color: 'var(--color-text)' }}>
                                                                {res.nazwa}{' '}
                                                                <span style={{ opacity: 0.7 }}>
                                                                    ({res.moc}{res.postac ? `, ${res.postac}` : ''})
                                                                </span>
                                                            </span>
                                                            <span className="hidden group-hover:inline" style={{ color: 'var(--color-accent)' }}>
                                                                ➕
                                                            </span>
                                                        </button>
                                                    ))}
                                                </div>
                                            )}
                                        </div>
                                    )}
                                </div>
                            )}
                        </div>

                        {/* Footer: Data dodania + Usuń */}
                        <div className="flex items-center justify-between mt-3 pr-1">
                            <span className="text-xs" style={{ color: 'var(--color-text-muted)' }}>
                                Dodano: {formatDate(medicine.dataDodania)}
                            </span>
                            <button
                                onClick={(e) => { e.stopPropagation(); onDelete(medicine.id); }}
                                className="neu-tag text-xs hover:scale-105 transition-transform"
                                title="Usuń lek"
                                aria-label="Usuń lek"
                                style={{ color: 'var(--color-error)' }}
                            >
                                Usuń lek
                            </button>
                        </div>
                    </>
                )}
            </article>

            {/* Modal z podglądem PDF */}
            {
                isPdfModalOpen && medicine.leafletUrl && (
                    <PdfModal
                        url={medicine.leafletUrl}
                        title={medicine.nazwa || 'Ulotka leku'}
                        onClose={() => setIsPdfModalOpen(false)}
                    />
                )
            }
        </>
    );
}
