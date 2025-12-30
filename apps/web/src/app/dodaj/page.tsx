'use client';

// src/app/dodaj/page.tsx
// Strona dodawania leków – Gemini AI Scanner + prompt rozpoznawania + import JSON
// Neumorphism Style

import { useState, useEffect, useRef } from 'react';
import { generateImportPrompt, copyToClipboard } from '@/lib/prompts';
import ImportForm from '@/components/ImportForm';
import GeminiScanner from '@/components/GeminiScanner';
import type { Medicine } from '@/lib/types';
import { getMedicines, importMedicinesWithDuplicateHandling } from '@/lib/storage';
import Link from 'next/link';
import { SvgIcon } from '@/components/SvgIcon';

interface ScanResult {
    leki: Array<{
        nazwa: string | null;
        opis: string;
        wskazania: string[];
        tagi: string[];
    }>;
}

export default function DodajLekiPage() {
    const [copyStatus, setCopyStatus] = useState<'idle' | 'copied' | 'error'>('idle');
    const [medicineCount, setMedicineCount] = useState(0);
    const [showImport, setShowImport] = useState(false);
    const [scanResult, setScanResult] = useState<ScanResult | null>(null);
    const backupInputRef = useRef<HTMLInputElement>(null);

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
        setScanResult(null);
    };

    const handleScanResult = (result: ScanResult) => {
        setScanResult(result);
    };

    // Import bezpośrednio z GeminiScanner
    const handleDirectImport = () => {
        if (!scanResult) return;
        const imported = importMedicinesWithDuplicateHandling(
            { leki: scanResult.leki },
            new Map()
        );
        setMedicineCount(prev => prev + imported.length);
        setScanResult(null);
    };

    // Import backup z pliku
    const handleBackupFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;
        try {
            console.log('[Import] Loading file:', file.name, 'size:', file.size);
            const text = await file.text();
            console.log('[Import] File content length:', text.length);
            const data = JSON.parse(text);
            console.log('[Import] Parsed data, leki count:', data.leki?.length, 'labels count:', data.labels?.length);
            if (data.leki) {
                setScanResult(data);
                // ImportForm is shown automatically via {scanResult && ...} section
            } else {
                console.warn('[Import] File does not contain leki array');
                alert('Plik nie zawiera tablicy "leki"');
            }
        } catch (err) {
            console.error('[Import] Error loading file:', err);
            alert('Nieprawidłowy format pliku backup: ' + (err instanceof Error ? err.message : String(err)));
        }
        if (backupInputRef.current) backupInputRef.current.value = '';
    };

    return (
        <div className="space-y-6">
            {/* Nagłówek - kontener w stylu kroków */}
            <div className="neu-flat p-6 animate-fadeInUp">
                <div className="flex flex-wrap items-start justify-between gap-4">
                    <div className="flex items-start gap-4">
                        <div className="neu-convex flex h-10 w-10 shrink-0 items-center justify-center font-bold text-lg" style={{ borderRadius: '50%' }}>
                            <SvgIcon name="plus" size={20} style={{ color: '#8b5cf6' }} />
                        </div>
                        <div>
                            <h1 className="text-xl font-bold" style={{ color: 'var(--color-text)' }}>
                                Dodaj leki
                            </h1>
                            <p className="mt-1 text-sm" style={{ color: 'var(--color-text-muted)' }}>
                                Zeskanuj opakowania leków przez AI lub zaimportuj backup
                            </p>
                        </div>
                    </div>
                    <div className="flex flex-wrap gap-2">
                        <button
                            onClick={() => backupInputRef.current?.click()}
                            className="neu-btn neu-btn-secondary text-sm flex items-center gap-1.5"
                        >
                            <SvgIcon name="folder-input" size={16} /> Import backup
                        </button>
                        <input
                            ref={backupInputRef}
                            type="file"
                            accept=".json"
                            onChange={handleBackupFileChange}
                            className="hidden"
                        />
                    </div>
                </div>
            </div>

            {/* 🤖 Gemini AI Scanner - szybka opcja */}
            <div className="animate-fadeInUp" style={{ animationDelay: '0.05s' }}>
                <GeminiScanner
                    onResult={handleScanResult}
                    onImport={scanResult ? handleDirectImport : undefined}
                    scannedCount={scanResult?.leki.length}
                />
            </div>

            {/* 📂 Import z pliku backup - pokazuje się gdy załadowano plik */}
            {scanResult && (
                <div className="neu-flat p-6 animate-fadeInUp" style={{ animationDelay: '0.1s' }}>
                    <div className="flex items-start gap-4 mb-4">
                        <div className="neu-convex flex h-10 w-10 shrink-0 items-center justify-center font-bold" style={{ color: 'var(--color-accent)', borderRadius: '50%' }}>
                            <SvgIcon name="folder-input" size={20} />
                        </div>
                        <div>
                            <h2 className="font-semibold" style={{ color: 'var(--color-text)' }}>
                                Zaimportuj dane z pliku
                            </h2>
                            <p className="mt-1 text-sm" style={{ color: 'var(--color-text-muted)' }}>
                                Wykryto {scanResult.leki.length} leków do importu
                            </p>
                        </div>
                        <button
                            onClick={() => setScanResult(null)}
                            className="ml-auto neu-btn neu-btn-secondary text-sm"
                            title="Anuluj import"
                        >
                            <SvgIcon name="x-circle" size={16} />
                        </button>
                    </div>
                    <ImportForm
                        onImportSuccess={handleImportSuccess}
                        initialData={scanResult}
                    />
                </div>
            )}

            {/* Separator - alternatywa ręczna */}
            <details className="group animate-fadeInUp" style={{ animationDelay: '0.1s' }}>
                <summary className="neu-flat p-4 cursor-pointer flex items-center gap-2 list-none" style={{ color: 'var(--color-text-muted)' }}>
                    <svg className="h-4 w-4 transition-transform group-open:rotate-90" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                    </svg>
                    <span className="text-sm font-medium flex items-center gap-1.5"><SvgIcon name="clipboard-plus" size={14} /> Ręczny prompt (alternatywa przy limicie API)</span>
                </summary>

                {/* Krok 1: Prompt (alternatywa ręczna) */}
                <div id="prompt-generator" className="neu-flat p-6 animate-fadeInUp" style={{ animationDelay: '0.15s' }}>
                    <div className="flex items-start gap-4">
                        <div className="neu-convex flex h-10 w-10 shrink-0 items-center justify-center font-bold" style={{ color: 'var(--color-text-muted)', borderRadius: '50%' }}>
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
                                    <SvgIcon name="search" size={14} /> Pokaż podgląd promptu
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
                                {copyStatus === 'copied' ? <><SvgIcon name="check-circle" size={16} /> Skopiowano!</> : <><SvgIcon name="clipboard" size={16} /> Kopiuj prompt</>}
                            </button>
                        </div>
                    </div>
                </div>

                {/* Krok 2: Zdjęcie (ręczna metoda) */}
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
                                    <SvgIcon name="clipboard" size={16} /> Pokaż formularz importu
                                </button>
                            ) : (
                                <div className="mt-4">
                                    <ImportForm
                                        onImportSuccess={handleImportSuccess}
                                        initialData={scanResult || undefined}
                                    />
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            </details>

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
