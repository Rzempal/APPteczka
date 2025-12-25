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

    if (!mounted) return null;

    const modalContent = (
        <div
            className="fixed inset-0 flex items-center justify-center p-4 animate-fadeIn"
            style={{
                backgroundColor: 'rgba(0, 0, 0, 0.8)',
                zIndex: 9999 // Bardzo wysoki z-index
            }}
            onClick={onClose}
        >
            <div
                className="neu-flat w-full max-w-5xl h-[90vh] flex flex-col animate-popIn"
                style={{ maxHeight: 'calc(100vh - 2rem)' }}
                onClick={(e) => e.stopPropagation()}
            >
                {/* Header */}
                <div className="flex items-center justify-between p-4 border-b" style={{ borderColor: 'var(--shadow-dark)' }}>
                    <h2 className="text-lg font-semibold truncate flex-1 mr-4" style={{ color: 'var(--color-text)' }}>
                        📄 {title}
                    </h2>
                    <div className="flex items-center gap-2 flex-shrink-0">
                        <a
                            href={url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="neu-tag text-xs"
                            style={{ color: 'var(--color-accent)' }}
                            title="Otwórz w nowej karcie"
                        >
                            🔗 Nowa karta
                        </a>
                        <a
                            href={proxyUrl}
                            download={`${title}.pdf`}
                            className="neu-tag text-xs"
                            style={{ color: 'var(--color-accent)' }}
                            title="Pobierz PDF"
                        >
                            📥 Pobierz
                        </a>
                        <button
                            onClick={onClose}
                            className="neu-tag text-lg px-3 py-1"
                            style={{ color: 'var(--color-error)' }}
                            title="Zamknij (Esc)"
                        >
                            ✕
                        </button>
                    </div>
                </div>

                {/* PDF iframe */}
                <div className="flex-1 p-2 min-h-0">
                    <iframe
                        src={proxyUrl}
                        className="w-full h-full rounded-lg"
                        style={{
                            backgroundColor: 'white',
                            border: 'none'
                        }}
                        title={title}
                    />
                </div>
            </div>
        </div>
    );

    // Renderuj portal na document.body
    return createPortal(modalContent, document.body);
}
