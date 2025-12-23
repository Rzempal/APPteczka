'use client';

// src/app/dodaj/page.tsx
// Strona dodawania leków – prompt rozpoznawania + import JSON

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
            {/* Nagłówek */}
            <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                    ➕ Dodaj leki
                </h1>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                    Zeskanuj opakowania leków przez AI i zaimportuj je do apteczki
                </p>
            </div>

            {/* Krok 1: Prompt */}
            <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                <div className="flex items-start gap-4">
                    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-blue-100 text-blue-600 font-bold dark:bg-blue-900 dark:text-blue-300">
                        1
                    </div>
                    <div className="flex-1">
                        <h2 className="font-semibold text-gray-900 dark:text-white">
                            Skopiuj prompt dla AI
                        </h2>
                        <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">
                            Wklej ten prompt do ChatGPT, Claude lub Gemini, a następnie dodaj zdjęcie opakowań leków.
                        </p>

                        {/* Podgląd promptu */}
                        <details className="mt-3">
                            <summary className="cursor-pointer text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400">
                                Pokaż podgląd promptu
                            </summary>
                            <pre className="mt-2 max-h-48 overflow-auto rounded-lg bg-gray-900 p-3 text-xs text-green-400">
                                {generateImportPrompt()}
                            </pre>
                        </details>

                        <button
                            onClick={handleCopyPrompt}
                            className={`mt-4 flex items-center gap-2 rounded-lg px-4 py-2 font-medium transition-colors ${copyStatus === 'copied'
                                    ? 'bg-green-600 text-white'
                                    : 'bg-blue-600 text-white hover:bg-blue-700'
                                }`}
                        >
                            {copyStatus === 'copied' ? '✅ Skopiowano!' : '📋 Kopiuj prompt'}
                        </button>
                    </div>
                </div>
            </div>

            {/* Krok 2: Zdjęcie */}
            <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                <div className="flex items-start gap-4">
                    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-gray-100 text-gray-600 font-bold dark:bg-gray-700 dark:text-gray-300">
                        2
                    </div>
                    <div>
                        <h2 className="font-semibold text-gray-900 dark:text-white">
                            Zrób zdjęcie i wyślij do AI
                        </h2>
                        <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">
                            Zrób zdjęcie opakowań leków (może być kilka na jednym zdjęciu) i wyślij razem z promptem.
                            AI zwróci dane w formacie JSON.
                        </p>
                    </div>
                </div>
            </div>

            {/* Krok 3: Import */}
            <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                <div className="flex items-start gap-4">
                    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-gray-100 text-gray-600 font-bold dark:bg-gray-700 dark:text-gray-300">
                        3
                    </div>
                    <div className="flex-1">
                        <h2 className="font-semibold text-gray-900 dark:text-white">
                            Zaimportuj odpowiedź AI
                        </h2>
                        <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">
                            Skopiuj odpowiedź JSON z AI i wklej poniżej, lub wczytaj plik z kopii zapasowej.
                        </p>

                        {!showImport ? (
                            <button
                                onClick={() => setShowImport(true)}
                                className="mt-4 rounded-lg border border-blue-600 px-4 py-2 text-sm font-medium text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20"
                            >
                                Pokaż formularz importu
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
            <div className="rounded-xl bg-gradient-to-r from-blue-50 to-indigo-50 p-6 dark:from-blue-900/20 dark:to-indigo-900/20">
                <div className="flex items-center justify-between">
                    <div>
                        <p className="text-sm text-gray-600 dark:text-gray-400">Leków w apteczce:</p>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{medicineCount}</p>
                    </div>
                    <Link
                        href="/"
                        className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
                    >
                        Zobacz apteczkę →
                    </Link>
                </div>
            </div>
        </div>
    );
}
