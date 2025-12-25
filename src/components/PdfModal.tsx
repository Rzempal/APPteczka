'use client';

// src/components/PdfModal.tsx
// Modal z podglądem PDF w iframe - Neumorphism Style

interface PdfModalProps {
    url: string;
    title: string;
    onClose: () => void;
}

export default function PdfModal({ url, title, onClose }: PdfModalProps) {
    return (
        <div
            className="fixed inset-0 z-50 flex items-center justify-center p-4 animate-fadeIn"
            style={{ backgroundColor: 'rgba(0, 0, 0, 0.7)' }}
            onClick={onClose}
        >
            <div
                className="neu-flat w-full max-w-4xl h-[85vh] flex flex-col animate-popIn"
                onClick={(e) => e.stopPropagation()}
            >
                {/* Header */}
                <div className="flex items-center justify-between p-4 border-b" style={{ borderColor: 'var(--shadow-dark)' }}>
                    <h2 className="text-lg font-semibold truncate" style={{ color: 'var(--color-text)' }}>
                        📄 {title}
                    </h2>
                    <div className="flex items-center gap-2">
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
                        <button
                            onClick={onClose}
                            className="neu-tag text-lg px-3 py-1"
                            style={{ color: 'var(--color-error)' }}
                            title="Zamknij"
                        >
                            ✕
                        </button>
                    </div>
                </div>

                {/* PDF iframe */}
                <div className="flex-1 p-2">
                    <iframe
                        src={url}
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
}
