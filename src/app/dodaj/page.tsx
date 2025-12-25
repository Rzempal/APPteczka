'use client';

// src/app/dodaj/page.tsx
// Strona dodawania leków – prompt rozpoznawania + import JSON
// Neumorphism Style

import { useState, useEffect } from 'react';
import { generateImportPrompt, copyToClipboard } from '@/lib/prompts';
import ImportForm from '@/components/ImportForm';
import type { Medicine } from '@/lib/types';
import { getMedicines } from '@/lib/storage';
import Link from 'next/link';

export default function DodajLekiPage() {
    const [copyStatus, setCopyStatus] = useState<'idle' | 'copied' | 'error'>('idle');
    const [medicineCount, setMedicineCount] = useState(0);
    const [showImport, setShowImport] = useState(false);

    useEffect(() => {
        setMedicineCount(getMedicines().length);
    }, []);

    const handleCopyPrompt = async () => {
        const prompt = generateImportPrompt();
        const success = await copyToClipboard(prompt);
        setCopyStatus(success ? 'copied' : 'error');
        setTimeout(() => setCopyStatus('idle'), 2000);
    };

    const handleImportSuccess = (imported: Medicine[]) => {
        setMedicineCount(prev => prev + imported.length);
    };

    return (
        <div className="space-y-6">
            {/* Nagłówek - kontener w stylu kroków */}
            <div className="neu-flat p-6 animate-fadeInUp">
                <div className="flex items-start gap-4">
                    <div className="neu-convex flex h-10 w-10 shrink-0 items-center justify-center font-bold text-lg" style={{ color: 'var(--color-accent)', borderRadius: '50%' }}>
                        ➕
                    </div>
                    <div>
                        <h1 className="text-xl font-bold" style={{ color: 'var(--color-text)' }}>
                            Dodaj leki
                        </h1>
                        <p className="mt-1 text-sm" style={{ color: 'var(--color-text-muted)' }}>
                            Zeskanuj opakowania leków przez AI i zaimportuj je do apteczki
                        </p>
                    </div>
                </div>
            </div>

            {/* Krok 1: Prompt */}
            <div className="neu-flat p-6 animate-fadeInUp" style={{ animationDelay: '0.1s' }}>
                <div className="flex items-start gap-4">
                    <div className="neu-convex flex h-10 w-10 shrink-0 items-center justify-center font-bold" style={{ color: 'var(--color-accent)', borderRadius: '50%' }}>
                        1
                    </div>
                    <div className="flex-1">
                        <h2 className="font-semibold" style={{ color: 'var(--color-text)' }}>
                            Skopiuj prompt dla AI
                        </h2>
                        <p className="mt-1 text-sm" style={{ color: 'var(--color-text-muted)' }}>
                            Wklej ten prompt do ChatGPT, Claude lub Gemini, a następnie dodaj zdjęcie opakowań leków.
                        </p>

                        {/* Podgląd promptu */}
                        <details className="mt-3">
                            <summary className="cursor-pointer text-sm" style={{ color: 'var(--color-accent)' }}>
                                👁️ Pokaż podgląd promptu
                            </summary>
                            <pre className="mt-2 max-h-48 overflow-auto rounded-lg p-3 text-xs" style={{ background: '#1a1f1c', color: 'var(--color-accent-light)' }}>
                                {generateImportPrompt()}
                            </pre>
                        </details>

                        <button
                            onClick={handleCopyPrompt}
                            className={`mt-4 neu-btn ${copyStatus === 'copied' ? '' : 'neu-btn-primary'}`}
                            style={copyStatus === 'copied' ? { background: 'var(--color-success)', color: 'white' } : {}}
                        >
                            {copyStatus === 'copied' ? '✅ Skopiowano!' : '📋 Kopiuj prompt'}
                        </button>
                    </div>
                </div>
            </div>

            {/* Krok 2: Zdjęcie */}
            <div className="neu-flat p-6 animate-fadeInUp" style={{ animationDelay: '0.2s' }}>
                <div className="flex items-start gap-4">
                    <div className="neu-convex flex h-10 w-10 shrink-0 items-center justify-center font-bold" style={{ color: 'var(--color-text-muted)', borderRadius: '50%' }}>
                        2
                    </div>
                    <div>
                        <h2 className="font-semibold" style={{ color: 'var(--color-text)' }}>
                            Zrób zdjęcie i wyślij do AI
                        </h2>
                        <p className="mt-1 text-sm" style={{ color: 'var(--color-text-muted)' }}>
                            Zrób zdjęcie opakowań leków (może być kilka na jednym zdjęciu) i wyślij razem z promptem.
                            AI zwróci dane w formacie JSON.
                        </p>
                    </div>
                </div>
            </div>

            {/* Krok 3: Import */}
            <div className="neu-flat p-6 animate-fadeInUp" style={{ animationDelay: '0.3s' }}>
                <div className="flex items-start gap-4">
                    <div className="neu-convex flex h-10 w-10 shrink-0 items-center justify-center font-bold" style={{ color: 'var(--color-text-muted)', borderRadius: '50%' }}>
                        3
                    </div>
                    <div className="flex-1">
                        <h2 className="font-semibold" style={{ color: 'var(--color-text)' }}>
                            Zaimportuj odpowiedź AI
                        </h2>
                        <p className="mt-1 text-sm" style={{ color: 'var(--color-text-muted)' }}>
                            Skopiuj odpowiedź JSON z AI i wklej poniżej, lub wczytaj plik z kopii zapasowej.
                        </p>

                        {!showImport ? (
                            <button
                                onClick={() => setShowImport(true)}
                                className="mt-4 neu-btn neu-btn-secondary"
                            >
                                📝 Pokaż formularz importu
                            </button>
                        ) : (
                            <div className="mt-4">
                                <ImportForm onImportSuccess={handleImportSuccess} />
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* Status apteczki */}
            <div className="neu-flat p-6 animate-fadeInUp" style={{
                animationDelay: '0.4s',
                background: 'linear-gradient(145deg, var(--color-bg-light), var(--color-bg-dark))'
            }}>
                <div className="flex items-center justify-between">
                    <div>
                        <p className="text-sm" style={{ color: 'var(--color-text-muted)' }}>Leków w apteczce:</p>
                        <p className="text-3xl font-bold" style={{ color: 'var(--color-accent)' }}>{medicineCount}</p>
                    </div>
                    <Link
                        href="/"
                        className="neu-btn neu-btn-primary"
                    >
                        Zobacz apteczkę →
                    </Link>
                </div>
            </div>
        </div>
    );
}
