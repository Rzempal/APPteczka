'use client';

// src/app/konsultacja/page.tsx
// Strona konsultacji AI – prompt do analizy objawów

import { useState, useEffect } from 'react';
import type { Medicine } from '@/lib/types';
import { getMedicines } from '@/lib/storage';
import { generateAnalysisPrompt, copyToClipboard } from '@/lib/prompts';
import { ALLOWED_TAGS } from '@/lib/types';
import Link from 'next/link';

export default function KonsultacjaPage() {
    const [medicines, setMedicines] = useState<Medicine[]>([]);
    const [selectedSymptoms, setSelectedSymptoms] = useState<string[]>([]);
    const [additionalNotes, setAdditionalNotes] = useState('');
    const [copyStatus, setCopyStatus] = useState<'idle' | 'copied' | 'error'>('idle');

    useEffect(() => {
        setMedicines(getMedicines());
    }, []);

    const handleSymptomToggle = (symptom: string) => {
        setSelectedSymptoms(prev =>
            prev.includes(symptom)
                ? prev.filter(s => s !== symptom)
                : [...prev, symptom]
        );
    };

    const handleCopyPrompt = async () => {
        if (selectedSymptoms.length === 0) {
            setCopyStatus('error');
            setTimeout(() => setCopyStatus('idle'), 2000);
            return;
        }

        const prompt = generateAnalysisPrompt(medicines, selectedSymptoms, additionalNotes);
        const success = await copyToClipboard(prompt);
        setCopyStatus(success ? 'copied' : 'error');
        setTimeout(() => setCopyStatus('idle'), 2000);
    };

    const previewPrompt = selectedSymptoms.length > 0
        ? generateAnalysisPrompt(medicines, selectedSymptoms, additionalNotes)
        : '';

    return (
        <div className="space-y-6">
            {/* Nagłówek */}
            <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                    🩺 Konsultacja AI
                </h1>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                    Zapytaj AI lekarza, które z Twoich leków mogą pomóc przy objawach
                </p>
            </div>

            {/* Disclaimer */}
            <div className="rounded-xl border-2 border-red-200 bg-red-50 p-4 dark:border-red-800 dark:bg-red-900/20">
                <div className="flex items-start gap-3">
                    <span className="text-2xl">⚠️</span>
                    <div>
                        <h4 className="font-bold text-red-800 dark:text-red-200">
                            WAŻNE – przeczytaj przed użyciem
                        </h4>
                        <ul className="mt-2 space-y-1 text-sm text-red-700 dark:text-red-300">
                            <li>• To narzędzie <strong>NIE zastępuje</strong> wizyty u prawdziwego lekarza</li>
                            <li>• AI może się mylić – zawsze weryfikuj informacje</li>
                            <li>• W nagłych przypadkach dzwoń na 112 lub jedź na izbę przyjęć</li>
                            <li>• Przed przyjęciem leku przeczytaj ulotkę</li>
                        </ul>
                    </div>
                </div>
            </div>

            {/* Brak leków */}
            {medicines.length === 0 ? (
                <div className="rounded-xl bg-orange-50 p-6 text-center dark:bg-orange-900/20">
                    <p className="text-lg font-medium text-orange-800 dark:text-orange-200">
                        ⚠️ Twoja apteczka jest pusta
                    </p>
                    <p className="mt-2 text-sm text-orange-700 dark:text-orange-300">
                        Aby skorzystać z konsultacji, najpierw dodaj leki do apteczki.
                    </p>
                    <Link
                        href="/dodaj"
                        className="mt-4 inline-block rounded-lg bg-orange-600 px-6 py-2 font-medium text-white hover:bg-orange-700"
                    >
                        Dodaj leki →
                    </Link>
                </div>
            ) : (
                <>
                    {/* Formularz */}
                    <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                        {/* Wybór objawów */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                                Wybierz objawy:
                            </label>
                            <div className="mt-2 flex flex-wrap gap-1.5">
                                {ALLOWED_TAGS.objawy.map(symptom => (
                                    <button
                                        key={symptom}
                                        type="button"
                                        onClick={() => handleSymptomToggle(symptom)}
                                        className={`rounded-full px-3 py-1 text-sm font-medium transition-colors ${selectedSymptoms.includes(symptom)
                                                ? 'bg-blue-600 text-white'
                                                : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300'
                                            }`}
                                    >
                                        {symptom}
                                    </button>
                                ))}
                            </div>
                        </div>

                        {/* Dodatkowe uwagi */}
                        <div className="mt-4">
                            <label
                                htmlFor="notes"
                                className="block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                Dodatkowe uwagi (opcjonalne):
                            </label>
                            <textarea
                                id="notes"
                                value={additionalNotes}
                                onChange={(e) => setAdditionalNotes(e.target.value)}
                                placeholder="Np. objawy od 3 dni, temperatura ok. 38°C, ból nasila się wieczorem..."
                                rows={3}
                                className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                            />
                        </div>

                        {/* Info o apteczce */}
                        <div className="mt-4 rounded-lg bg-gray-50 p-3 dark:bg-gray-700">
                            <p className="text-xs text-gray-600 dark:text-gray-400">
                                📦 Prompt zawrze listę {medicines.length} leków z Twojej apteczki
                            </p>
                        </div>
                    </div>

                    {/* Podgląd promptu */}
                    {previewPrompt && (
                        <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                                Podgląd promptu:
                            </label>
                            <pre className="mt-2 max-h-64 overflow-auto rounded-lg bg-gray-900 p-4 text-xs text-green-400">
                                {previewPrompt}
                            </pre>
                        </div>
                    )}

                    {/* Przycisk kopiowania */}
                    <button
                        onClick={handleCopyPrompt}
                        disabled={selectedSymptoms.length === 0}
                        className={`w-full rounded-lg px-6 py-3 font-medium transition-colors ${copyStatus === 'copied'
                                ? 'bg-green-600 text-white'
                                : copyStatus === 'error'
                                    ? 'bg-red-600 text-white'
                                    : 'bg-blue-600 text-white hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed'
                            }`}
                    >
                        {copyStatus === 'copied' && '✅ Skopiowano! Wklej do ChatGPT/Claude/Gemini'}
                        {copyStatus === 'error' && '❌ Wybierz przynajmniej jeden objaw'}
                        {copyStatus === 'idle' && '📋 Kopiuj prompt do schowka'}
                    </button>

                    {/* Instrukcja */}
                    <div className="rounded-lg bg-blue-50 p-4 text-sm text-blue-800 dark:bg-blue-900/30 dark:text-blue-200">
                        <strong>💡 Jak użyć:</strong> Skopiuj prompt i wklej do ChatGPT, Claude lub Gemini.
                        AI wcieli się w rolę lekarza i przeanalizuje, które leki z Twojej apteczki mogą pomóc.
                    </div>
                </>
            )}
        </div>
    );
}
