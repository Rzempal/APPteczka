'use client';

// src/app/import/page.tsx
// Strona importu leków i generatora promptów

import { useState, useEffect } from 'react';
import type { Medicine } from '@/lib/types';
import { getMedicines } from '@/lib/storage';
import ImportForm from '@/components/ImportForm';
import PromptGenerator from '@/components/PromptGenerator';
import Link from 'next/link';

type Tab = 'import' | 'prompts';

export default function ImportPage() {
    const [activeTab, setActiveTab] = useState<Tab>('prompts');
    const [medicines, setMedicines] = useState<Medicine[]>([]);
    const [importedCount, setImportedCount] = useState(0);

    useEffect(() => {
        setMedicines(getMedicines());
    }, []);

    const handleImportSuccess = (imported: Medicine[]) => {
        setMedicines(getMedicines());
        setImportedCount(imported.length);
    };

    return (
        <div className="space-y-6">
            {/* Nagłówek */}
            <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                    Import leków
                </h1>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                    Użyj asystenta AI do rozpoznawania leków ze zdjęć i importuj dane do apteczki.
                </p>
            </div>

            {/* Powiadomienie o imporcie */}
            {importedCount > 0 && (
                <div className="flex items-center justify-between rounded-lg bg-green-50 p-4 dark:bg-green-900/30">
                    <p className="font-medium text-green-800 dark:text-green-200">
                        ✅ Zaimportowano {importedCount} leków!
                    </p>
                    <Link
                        href="/"
                        className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700"
                    >
                        Zobacz apteczkę →
                    </Link>
                </div>
            )}

            {/* Zakładki */}
            <div className="border-b border-gray-200 dark:border-gray-700">
                <nav className="-mb-px flex gap-4">
                    <button
                        onClick={() => setActiveTab('prompts')}
                        className={`border-b-2 px-1 py-3 text-sm font-medium transition-colors ${activeTab === 'prompts'
                                ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400'
                            }`}
                    >
                        📝 Generator promptów
                    </button>
                    <button
                        onClick={() => setActiveTab('import')}
                        className={`border-b-2 px-1 py-3 text-sm font-medium transition-colors ${activeTab === 'import'
                                ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400'
                            }`}
                    >
                        📥 Import danych
                    </button>
                </nav>
            </div>

            {/* Zawartość zakładki */}
            <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                {activeTab === 'prompts' ? (
                    <PromptGenerator medicines={medicines} />
                ) : (
                    <ImportForm onImportSuccess={handleImportSuccess} />
                )}
            </div>

            {/* Instrukcja krok po kroku */}
            <div className="rounded-xl bg-gradient-to-r from-blue-50 to-indigo-50 p-6 dark:from-blue-900/20 dark:to-indigo-900/20">
                <h2 className="mb-4 text-lg font-semibold text-gray-900 dark:text-white">
                    📚 Jak to działa?
                </h2>
                <ol className="space-y-3 text-sm text-gray-700 dark:text-gray-300">
                    <li className="flex gap-3">
                        <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-blue-600 text-xs font-bold text-white">1</span>
                        <span>Skopiuj prompt z zakładki &quot;Generator promptów&quot;</span>
                    </li>
                    <li className="flex gap-3">
                        <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-blue-600 text-xs font-bold text-white">2</span>
                        <span>Wklej prompt do ChatGPT, Claude lub Gemini</span>
                    </li>
                    <li className="flex gap-3">
                        <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-blue-600 text-xs font-bold text-white">3</span>
                        <span>Dodaj zdjęcie opakowań leków do wiadomości</span>
                    </li>
                    <li className="flex gap-3">
                        <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-blue-600 text-xs font-bold text-white">4</span>
                        <span>Skopiuj odpowiedź AI (JSON) i wklej w zakładce &quot;Import danych&quot;</span>
                    </li>
                    <li className="flex gap-3">
                        <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-green-600 text-xs font-bold text-white">✓</span>
                        <span>Leki zostaną dodane do Twojej apteczki!</span>
                    </li>
                </ol>
            </div>
        </div>
    );
}
