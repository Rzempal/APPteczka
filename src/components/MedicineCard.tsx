'use client';

// src/components/MedicineCard.tsx
// Karta pojedynczego leku - Neumorphism Style

import { useState } from 'react';
import type { Medicine } from '@/lib/types';
import { LABEL_COLORS } from '@/lib/types';
import { getLabelsByIds } from '@/lib/labelStorage';
import LabelSelector from './LabelSelector';
import PdfModal from './PdfModal';
import { searchMedicineInRpl, type RplSearchResult } from '@/actions/rplActions';
import { SvgIcon } from './SvgIcon';

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

    const statusLabels: Record<string, React.ReactNode> = {
        expired: <><SvgIcon name="alert-triangle" size={14} style={{ color: 'var(--color-error)' }} /> Przeterminowany</>,
        'expiring-soon': <><SvgIcon name="clock" size={14} style={{ color: 'var(--color-warning)' }} /> Kończy się ważność</>,
        valid: <><SvgIcon name="check-circle" size={14} style={{ color: 'var(--color-success)' }} /> Ważny</>,
        unknown: <><SvgIcon name="help-circle" size={14} style={{ color: 'var(--color-text-muted)' }} /> Brak daty</>
    };

    // Ikony statusu (dla nagłówka terminu ważności)
    const statusIcons: Record<string, React.ReactNode> = {
        expired: <SvgIcon name="alert-triangle" size={16} style={{ color: 'var(--color-error)' }} />,
        'expiring-soon': <SvgIcon name="clock" size={16} style={{ color: 'var(--color-warning)' }} />,
        valid: <SvgIcon name="check-circle" size={16} style={{ color: 'var(--color-success)' }} />,
        unknown: <SvgIcon name="help-circle" size={16} style={{ color: 'var(--color-text-muted)' }} />
    };

    // Teksty statusu (bez ikony)
    const statusTexts: Record<string, string> = {
        expired: 'Przeterminowany',
        'expiring-soon': 'Kończy się ważność',
        valid: 'Ważny',
        unknown: 'Brak daty'
    };

    return (
        <>
            <article
                className={`p-5 rounded-2xl transition-all duration-300 hover:-translate-y-1 glass-dark ${statusClasses[expiryStatus]}`}
                style={{ borderRadius: '20px', overflow: 'visible' }}
            >
                {/* Nagłówek - klikalny do zwijania */}
                <header
                    className="mb-3 flex items-start justify-between cursor-pointer group"
                    onClick={onToggleCollapse}
                    role="button"
                    aria-expanded={!isCollapsed}
                >
                    <div className="flex flex-wrap items-center gap-x-3 gap-y-1 flex-1">
                        <h3 className="text-lg font-semibold" style={{ color: 'var(--color-text)' }}>
                            {medicine.nazwa || <span className="italic" style={{ color: 'var(--color-text-muted)' }}>Nazwa nieznana</span>}
                        </h3>
                        {/* Etykiety w widoku zwiniętym (collapsed) - obok nazwy jeśli jest miejsce */}
                        {isCollapsed && medicine.labels && medicine.labels.length > 0 && (
                            <div className="flex flex-wrap gap-1 pl-1">
                                {getLabelsByIds(medicine.labels).map(label => (
                                    <span
                                        key={label.id}
                                        className="inline-flex items-center text-xs px-1.5 py-0.5 rounded-full"
                                        style={{
                                            backgroundColor: LABEL_COLORS[label.color].hex,
                                            color: 'white',
                                            fontSize: '0.65rem',
                                            boxShadow: '1px 1px 2px rgba(0,0,0,0.15), -1px -1px 2px rgba(255,255,255,0.1)'
                                        }}
                                    >
                                        {label.name}
                                    </span>
                                ))}
                            </div>
                        )}
                    </div>
                    <span
                        className={`neu-tag p-2 transition-all group-hover:scale-110 flex-shrink-0 ${isCollapsed ? 'active' : ''}`}
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
                    className={`overflow-hidden transition-all duration-300 ease-in-out ${isCollapsed ? 'max-h-0 opacity-0' : 'max-h-[500px] opacity-100'}`}
                >
                    {/* Ulotka PDF - pierwsza po rozwinieciu */}
                    <div className="mb-3 pl-1">
                        <span className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>Ulotka PDF:</span>

                        {medicine.leafletUrl ? (
                            <div className="mt-1 flex items-center gap-2 flex-wrap">
                                <button
                                    onClick={(e) => { e.stopPropagation(); setIsPdfModalOpen(true); }}
                                    className="neu-tag text-xs flex items-center gap-1 hover:scale-105 transition-transform"
                                >
                                    <SvgIcon name="file-text" size={14} style={{ color: 'var(--color-success)' }} />
                                    <span style={{ color: 'var(--color-text)' }}>Pokaż ulotkę PDF</span>
                                </button>
                                <button
                                    onClick={(e) => { e.stopPropagation(); handleRemoveLeaflet(); }}
                                    className="neu-tag text-xs flex items-center gap-1"
                                    title="Odepnij ulotkę"
                                >
                                    <SvgIcon name="pin-off" size={14} style={{ color: 'var(--color-error)' }} />
                                    <span style={{ color: 'var(--color-text)' }}>Odepnij</span>
                                </button>
                            </div>
                        ) : (
                            <div className="mt-1">
                                {!isSearchingLeaflet ? (
                                    <button
                                        onClick={(e) => { e.stopPropagation(); handleOpenLeafletSearch(); }}
                                        className="neu-tag text-xs flex items-center gap-1"
                                        title="Wyszukaj ulotkę w Rejestrze Produktów Leczniczych"
                                    >
                                        <SvgIcon name="file-search" size={14} style={{ color: 'var(--color-text)' }} />
                                        <span style={{ color: 'var(--color-text)' }}>Znajdź i podepnij ulotkę</span>
                                    </button>
                                ) : (
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
                                                className="neu-tag text-xs flex items-center gap-1"
                                            >
                                                <SvgIcon name="x" size={12} style={{ color: 'var(--color-error)' }} />
                                                <span style={{ color: 'var(--color-text)' }}>Anuluj</span>
                                            </button>
                                        </div>

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
                                            >
                                                {leafletLoading ? <SvgIcon name="loader" size={14} /> : <SvgIcon name="search" size={14} style={{ color: 'var(--color-text)' }} />}
                                            </button>
                                        </div>

                                        {leafletLoading && (
                                            <div className="text-xs p-2" style={{ color: 'var(--color-text-muted)' }}>
                                                Szukanie w Rejestrze Produktów Leczniczych...
                                            </div>
                                        )}

                                        {!leafletLoading && leafletSearchResults.length === 0 && leafletSearchQuery.trim().length >= 3 && (
                                            <div className="text-xs p-2" style={{ color: 'var(--color-text-muted)' }}>
                                                Nie znaleziono - spróbuj inną nazwę lub tylko pierwsze słowo.
                                                <br />
                                                <span style={{ fontSize: '0.65rem' }}>Uwaga: suplementy diety nie są w Rejestrze Produktów Leczniczych.</span>
                                            </div>
                                        )}

                                        {!leafletLoading && leafletSearchResults.length > 0 && (
                                            <div className="max-h-40 overflow-y-auto space-y-1.5 p-1 custom-scrollbar">
                                                {leafletSearchResults.map((res) => (
                                                    <button
                                                        key={res.id}
                                                        onClick={() => handleSelectLeaflet(res.ulotkaUrl)}
                                                        className="w-full text-left text-xs p-2 rounded transition-colors flex justify-between group neu-tag"
                                                    >
                                                        <span style={{ color: 'var(--color-text)' }}>
                                                            {res.nazwa}{' '}
                                                            <span style={{ opacity: 0.7 }}>
                                                                ({res.moc}{res.postac ? `, ${res.postac}` : ''})
                                                            </span>
                                                        </span>
                                                        <span className="hidden group-hover:inline" style={{ color: 'var(--color-accent)' }}>
                                                            <SvgIcon name="plus" size={14} />
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
                    <div className="mb-3 flex flex-wrap gap-1.5 px-1">
                        {medicine.tagi.map((tag, i) => (
                            <span
                                key={i}
                                className="neu-tag text-xs"
                                style={{
                                    color: 'var(--color-text)',
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
                    <div className="mb-4 px-1">
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
                                        className="neu-tag text-xs flex-shrink-0 flex items-center gap-1 group/btn"
                                        style={{ color: 'var(--color-text)' }}
                                    >
                                        <SvgIcon name="file-pen-line" size={14} />
                                        <span className="group-hover/btn:text-[var(--color-accent)] transition-colors">Edytuj notkę</span>
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
                            <div className="flex items-start justify-between">
                                <div className="flex-1">
                                    {/* Linia 1: Nagłówek z ikoną statusu */}
                                    <div className="flex items-center gap-1.5 mb-1">
                                        <span className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>Termin ważności:</span>
                                        {statusIcons[expiryStatus]}
                                    </div>
                                    {/* Linia 2: Data i tekst statusu */}
                                    {!isEditing ? (
                                        <div className="flex items-center gap-2 flex-wrap">
                                            <span className="text-sm font-semibold" style={{ color: 'var(--color-text)' }}>{formatDate(medicine.terminWaznosci)}</span>
                                            <span className="text-xs" style={{ color: 'var(--color-text-muted)' }}>{statusTexts[expiryStatus]}</span>
                                        </div>
                                    ) : (
                                        <input
                                            type="date"
                                            value={expiryDate}
                                            onChange={(e) => setExpiryDate(e.target.value)}
                                            onClick={(e) => e.stopPropagation()}
                                            className="neu-input text-sm"
                                            style={{ padding: '0.5rem', fontSize: '0.875rem' }}
                                        />
                                    )}
                                </div>

                                {!isEditing ? (
                                    <button
                                        onClick={(e) => { e.stopPropagation(); setIsEditing(true); }}
                                        className="neu-tag text-xs flex items-center gap-1 group/btn"
                                        style={{ color: 'var(--color-text)' }}
                                    >
                                        <SvgIcon name="calendar-sync" size={14} />
                                        <span className="group-hover/btn:text-[var(--color-accent)] transition-colors">Edytuj datę</span>
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


                        {/* Footer: Data dodania + Usuń */}
                        <div className="flex items-center justify-between mt-3 pr-1">
                            <span className="text-xs" style={{ color: 'var(--color-text-muted)' }}>
                                Dodano: {formatDate(medicine.dataDodania)}
                            </span>
                            <button
                                onClick={(e) => { e.stopPropagation(); onDelete(medicine.id); }}
                                className="neu-tag text-xs hover:scale-105 transition-all flex items-center gap-1 group/del"
                                title="Usuń lek"
                                aria-label="Usuń lek"
                            >
                                <SvgIcon name="trash" size={14} style={{ color: 'var(--color-error)' }} />
                                <span className="group-hover/del:text-[var(--color-error)] transition-colors" style={{ color: 'var(--color-text)' }}>Usuń lek</span>
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
