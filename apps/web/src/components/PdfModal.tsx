'use client';

// src/components/PdfModal.tsx
// Modal z podglądem PDF w iframe - Neumorphism Style
// Używa React Portal aby renderować nad całą stroną

import { useEffect, useState } from 'react';
import { createPortal } from 'react-dom';

interface PdfModalProps {
    url: string;
    title: string;
    onClose: () => void;
}

export default function PdfModal({ url, title, onClose }: PdfModalProps) {
    const [mounted, setMounted] = useState(false);
    const [pdfError, setPdfError] = useState(false);
    const [loading, setLoading] = useState(true);

    // Proxy URL do omijania blokad X-Frame-Options
    const proxyUrl = `/api/pdf-proxy?url=${encodeURIComponent(url)}`;

    // Montuj portal po stronie klienta
    useEffect(() => {
        setMounted(true);
        // Blokuj scroll na body gdy modal jest otwarty
        document.body.style.overflow = 'hidden';
        return () => {
            document.body.style.overflow = '';
        };
    }, []);

    // Zamknij na Escape
    useEffect(() => {
        const handleEscape = (e: KeyboardEvent) => {
            if (e.key === 'Escape') onClose();
        };
        window.addEventListener('keydown', handleEscape);
        return () => window.removeEventListener('keydown', handleEscape);
    }, [onClose]);

    // Sprawdź czy PDF proxy działa
    useEffect(() => {
        const checkPdf = async () => {
            try {
                const res = await fetch(proxyUrl, { method: 'HEAD' });
                if (!res.ok) {
                    setPdfError(true);
                }
            } catch {
                setPdfError(true);
            } finally {
                setLoading(false);
            }
        };
        checkPdf();
    }, [proxyUrl]);

    if (!mounted) return null;

    const modalContent = (
        <div
            className="fixed inset-0 flex items-center justify-center p-2 sm:p-4 animate-fadeIn"
            style={{
                backgroundColor: 'rgba(0, 0, 0, 0.8)',
                zIndex: 9999
            }}
            onClick={onClose}
        >
            <div
                className="neu-flat w-full max-w-5xl h-[95vh] sm:h-[90vh] flex flex-col animate-popIn"
                style={{ maxHeight: 'calc(100vh - 1rem)' }}
                onClick={(e) => e.stopPropagation()}
            >
                {/* Header - responsywny */}
                <div className="p-3 sm:p-4 border-b" style={{ borderColor: 'var(--shadow-dark)' }}>
                    {/* Tytuł i zamknij w jednym wierszu */}
                    <div className="flex items-center justify-between gap-2 mb-2 sm:mb-0">
                        <h2 className="text-sm sm:text-lg font-semibold truncate flex-1" style={{ color: 'var(--color-text)' }}>
                            📄 {title}
                        </h2>
                        <button
                            onClick={onClose}
                            className="neu-tag text-lg px-3 py-1 flex-shrink-0"
                            style={{ color: 'var(--color-error)' }}
                            title="Zamknij (Esc)"
                        >
                            ✕
                        </button>
                    </div>
                    {/* Przyciski akcji - osobny wiersz na mobile */}
                    <div className="flex items-center gap-2 flex-wrap">
                        <a
                            href={url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="neu-tag text-xs"
                            style={{ color: 'var(--color-accent)' }}
                        >
                            🔗 Otwórz w RPL
                        </a>
                        <a
                            href={proxyUrl}
                            download={`${title}.pdf`}
                            className="neu-tag text-xs"
                            style={{ color: 'var(--color-accent)' }}
                        >
                            📥 Pobierz PDF
                        </a>
                    </div>
                </div>

                {/* PDF iframe lub komunikat błędu */}
                <div className="flex-1 p-2 min-h-0 flex items-center justify-center">
                    {loading && (
                        <div className="text-center" style={{ color: 'var(--color-text-muted)' }}>
                            <div className="text-2xl mb-2">⏳</div>
                            <p>Ładowanie ulotki...</p>
                        </div>
                    )}

                    {!loading && pdfError && (
                        <div className="text-center p-4" style={{ color: 'var(--color-text)' }}>
                            <div className="text-4xl mb-4">📄</div>
                            <p className="mb-4">Nie można wyświetlić podglądu ulotki.</p>
                            <p className="text-sm mb-4" style={{ color: 'var(--color-text-muted)' }}>
                                Użyj przycisków powyżej, aby otworzyć lub pobrać PDF.
                            </p>
                            <a
                                href={url}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="neu-button inline-block px-6 py-3"
                                style={{ color: 'var(--color-accent)' }}
                            >
                                🔗 Otwórz w Rejestrze MZ
                            </a>
                        </div>
                    )}

                    {!loading && !pdfError && (
                        <iframe
                            src={proxyUrl}
                            className="w-full h-full rounded-lg"
                            style={{
                                backgroundColor: 'white',
                                border: 'none'
                            }}
                            title={title}
                            onError={() => setPdfError(true)}
                        />
                    )}
                </div>
            </div>
        </div>
    );

    // Renderuj portal na document.body
    return createPortal(modalContent, document.body);
}

