'use client';

// src/components/GeminiScanner.tsx
// Komponent do skanowania leków ze zdjęć przez Gemini AI

import { useState, useCallback, useRef } from 'react';

interface ScanResult {
    leki: Array<{
        nazwa: string | null;
        opis: string;
        wskazania: string[];
        tagi: string[];
    }>;
}

interface ScanError {
    error: string;
    code: string;
}

type ScanStatus = 'idle' | 'loading' | 'success' | 'error';

interface GeminiScannerProps {
    onResult: (result: ScanResult) => void;
    onImport?: () => void;
    scannedCount?: number;
}

export default function GeminiScanner({ onResult, onImport, scannedCount }: GeminiScannerProps) {
    const [status, setStatus] = useState<ScanStatus>('idle');
    const [error, setError] = useState<string | null>(null);
    const [preview, setPreview] = useState<string | null>(null);
    const [isDragging, setIsDragging] = useState(false);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const processFile = useCallback(async (file: File) => {
        // Walidacja typu
        if (!file.type.startsWith('image/')) {
            setError('Wybierz plik graficzny (JPEG, PNG, WebP)');
            return;
        }

        // Walidacja rozmiaru (4MB)
        if (file.size > 4 * 1024 * 1024) {
            setError('Obraz jest za duży. Maksymalny rozmiar: 4MB');
            return;
        }

        // Ustaw podgląd
        const reader = new FileReader();
        reader.onload = (e) => {
            setPreview(e.target?.result as string);
        };
        reader.readAsDataURL(file);

        // Konwertuj do base64
        const base64Promise = new Promise<string>((resolve) => {
            const r = new FileReader();
            r.onload = () => {
                const result = r.result as string;
                // Usuń prefix "data:image/...;base64,"
                const base64 = result.split(',')[1];
                resolve(base64);
            };
            r.readAsDataURL(file);
        });

        setStatus('loading');
        setError(null);

        try {
            const base64 = await base64Promise;

            const response = await fetch('/api/gemini-ocr', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    image: base64,
                    mimeType: file.type,
                }),
            });

            const data = await response.json();

            if (!response.ok || data.error) {
                setStatus('error');
                setError(data.error || 'Wystąpił błąd podczas skanowania');
                return;
            }

            setStatus('success');
            onResult(data as ScanResult);

        } catch (err) {
            setStatus('error');
            setError(err instanceof Error ? err.message : 'Błąd połączenia z serwerem');
        }
    }, [onResult]);

    const handleDrop = useCallback((e: React.DragEvent) => {
        e.preventDefault();
        setIsDragging(false);

        const file = e.dataTransfer.files[0];
        if (file) {
            processFile(file);
        }
    }, [processFile]);

    const handleDragOver = useCallback((e: React.DragEvent) => {
        e.preventDefault();
        setIsDragging(true);
    }, []);

    const handleDragLeave = useCallback(() => {
        setIsDragging(false);
    }, []);

    const handleFileSelect = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            processFile(file);
        }
    }, [processFile]);

    const handleClick = () => {
        fileInputRef.current?.click();
    };

    const handleReset = () => {
        setStatus('idle');
        setError(null);
        setPreview(null);
        if (fileInputRef.current) {
            fileInputRef.current.value = '';
        }
    };

    return (
        <div className="space-y-4">
            {/* Nagłówek */}
            <div className="neu-flat p-5">
                <h3 className="font-medium flex items-center gap-2" style={{ color: 'var(--color-text)' }}>
                    <span className="text-xl">🤖</span>
                    Skanuj leki z Gemini AI
                </h3>
                <p className="mt-1 text-sm" style={{ color: 'var(--color-text-muted)' }}>
                    Prześlij zdjęcie opakowań leków. AI automatycznie rozpozna leki i wygeneruje dane do importu.
                </p>
            </div>

            {/* Strefa upload */}
            <div
                onClick={handleClick}
                onDrop={handleDrop}
                onDragOver={handleDragOver}
                onDragLeave={handleDragLeave}
                className={`
          neu-concave p-8 rounded-xl cursor-pointer transition-all duration-300
          flex flex-col items-center justify-center min-h-[200px]
          ${isDragging ? 'ring-2 ring-offset-2' : ''}
          ${status === 'loading' ? 'opacity-50 pointer-events-none' : ''}
        `}
                style={{
                    borderColor: isDragging ? 'var(--color-accent)' : 'transparent',
                }}
            >
                <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/jpeg,image/png,image/webp,image/gif"
                    onChange={handleFileSelect}
                    className="hidden"
                />

                {preview ? (
                    <div className="relative w-full max-w-xs">
                        <img
                            src={preview}
                            alt="Podgląd"
                            className="rounded-lg shadow-lg max-h-48 mx-auto object-contain"
                        />
                        {status === 'loading' && (
                            <div className="absolute inset-0 flex items-center justify-center bg-black/50 rounded-lg">
                                <div className="animate-spin rounded-full h-12 w-12 border-4 border-white border-t-transparent" />
                            </div>
                        )}
                    </div>
                ) : (
                    <>
                        <div className="text-5xl mb-4">📷</div>
                        <p className="text-center font-medium" style={{ color: 'var(--color-text)' }}>
                            {isDragging ? 'Upuść zdjęcie tutaj' : 'Kliknij lub przeciągnij zdjęcie'}
                        </p>
                        <p className="text-sm mt-2" style={{ color: 'var(--color-text-muted)' }}>
                            JPEG, PNG, WebP • max 4MB
                        </p>
                    </>
                )}
            </div>

            {/* Status / Błąd */}
            {status === 'loading' && (
                <div className="neu-flat p-4 flex items-center gap-3" style={{ color: 'var(--color-accent)' }}>
                    <div className="animate-spin rounded-full h-5 w-5 border-2 border-current border-t-transparent" />
                    <span>Analizuję zdjęcie z Gemini AI...</span>
                </div>
            )}

            {status === 'error' && error && (
                <div className="neu-flat p-4 space-y-3">
                    <div className="flex items-start gap-3" style={{ color: 'var(--color-error)' }}>
                        <span className="text-xl">❌</span>
                        <div>
                            <p className="font-medium">Błąd skanowania</p>
                            <p className="text-sm mt-1" style={{ color: 'var(--color-text-muted)' }}>{error}</p>
                        </div>
                    </div>
                    <div className="flex gap-2">
                        <button onClick={handleReset} className="neu-btn text-sm">
                            Spróbuj ponownie
                        </button>
                        <a
                            href="#prompt-generator"
                            className="neu-btn text-sm"
                            style={{ color: 'var(--color-accent)' }}
                        >
                            Użyj ręcznego promptu →
                        </a>
                    </div>
                </div>
            )}

            {status === 'success' && (
                <div className="neu-flat p-4 space-y-3">
                    <div className="flex items-center gap-3" style={{ color: 'var(--color-success)' }}>
                        <span className="text-xl">✅</span>
                        <div className="flex-1">
                            <p className="font-medium">Leki rozpoznane!</p>
                            <p className="text-sm" style={{ color: 'var(--color-text-muted)' }}>
                                {scannedCount ? `Rozpoznano ${scannedCount} leków.` : 'Dane gotowe do importu.'}
                            </p>
                        </div>
                        <button onClick={handleReset} className="neu-btn text-sm">
                            Skanuj kolejne
                        </button>
                    </div>
                    {onImport && (
                        <button
                            onClick={onImport}
                            className="w-full neu-btn neu-btn-primary"
                        >
                            📥 Importuj {scannedCount || ''} leków do apteczki
                        </button>
                    )}
                </div>
            )}
        </div>
    );
}
