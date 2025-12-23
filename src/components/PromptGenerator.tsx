'use client';

// src/components/PromptGenerator.tsx
// Generator promptów do kopiowania

import { useState } from 'react';
import { generateImportPrompt, generateAnalysisPrompt, copyToClipboard } from '@/lib/prompts';
import type { Medicine } from '@/lib/types';
import { ALLOWED_TAGS } from '@/lib/types';

interface PromptGeneratorProps {
    medicines: Medicine[];
}

type PromptType = 'import' | 'analysis';

export default function PromptGenerator({ medicines }: PromptGeneratorProps) {
    const [activePrompt, setActivePrompt] = useState<PromptType>('import');
    const [selectedSymptoms, setSelectedSymptoms] = useState<string[]>([]);
    const [additionalNotes, setAdditionalNotes] = useState('');
    const [copyStatus, setCopyStatus] = useState<'idle' | 'copied' | 'error'>('idle');

    const handleCopy = async () => {
        let prompt: string;

        if (activePrompt === 'import') {
            prompt = generateImportPrompt();
        } else {
            if (selectedSymptoms.length === 0) {
                setCopyStatus('error');
                setTimeout(() => setCopyStatus('idle'), 2000);
                return;
            }
            prompt = generateAnalysisPrompt(medicines, selectedSymptoms, additionalNotes);
        }

        const success = await copyToClipboard(prompt);
        setCopyStatus(success ? 'copied' : 'error');
        setTimeout(() => setCopyStatus('idle'), 2000);
    };

    const handleSymptomToggle = (symptom: string) => {
        setSelectedSymptoms(prev =>
            prev.includes(symptom)
                ? prev.filter(s => s !== symptom)
                : [...prev, symptom]
        );
    };

    const previewPrompt = activePrompt === 'import'
        ? generateImportPrompt()
        : selectedSymptoms.length > 0
            ? generateAnalysisPrompt(medicines, selectedSymptoms, additionalNotes)
            : '(Wybierz przynajmniej jeden objaw, aby wygenerować prompt)';

    return (
        <div className="space-y-4">
            {/* Wybór typu promptu */}
            <div className="flex gap-2">
                <button
                    onClick={() => setActivePrompt('import')}
                    className={`rounded-lg px-4 py-2 font-medium transition-colors ${activePrompt === 'import'
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300'
                        }`}
                >
                    📷 Rozpoznawanie leków
                </button>
                <button
                    onClick={() => setActivePrompt('analysis')}
                    className={`rounded-lg px-4 py-2 font-medium transition-colors ${activePrompt === 'analysis'
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300'
                        }`}
                >
                    🩺 Konsultacja lekarska
                </button>
            </div>

            {/* Opis promptu */}
            <div className="rounded-lg bg-gray-50 p-4 dark:bg-gray-800">
                {activePrompt === 'import' ? (
                    <>
                        <h3 className="font-medium text-gray-900 dark:text-white">
                            📷 Prompt do rozpoznawania leków ze zdjęcia
                        </h3>
                        <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">
                            Wklej ten prompt do ChatGPT, Claude lub Gemini, a następnie dodaj zdjęcie opakowań leków.
                            AI zwróci dane w formacie JSON, które możesz zaimportować do apteczki.
                        </p>
                    </>
                ) : (
                    <>
                        <h3 className="font-medium text-gray-900 dark:text-white">
                            🩺 Konsultacja z wirtualnym lekarzem
                        </h3>
                        <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">
                            AI wcieli się w rolę lekarza internisty i przeanalizuje, które z Twoich leków mogą pomóc przy objawach.
                        </p>

                        {/* Wybór objawów */}
                        <div className="mt-4">
                            <span className="text-xs font-medium text-gray-500 dark:text-gray-400">
                                Wybierz objawy:
                            </span>
                            <div className="mt-2 flex flex-wrap gap-1.5">
                                {ALLOWED_TAGS.objawy.map(symptom => (
                                    <button
                                        key={symptom}
                                        onClick={() => handleSymptomToggle(symptom)}
                                        className={`rounded-full px-2.5 py-0.5 text-xs font-medium transition-colors ${selectedSymptoms.includes(symptom)
                                            ? 'bg-blue-600 text-white'
                                            : 'bg-gray-200 text-gray-700 hover:bg-gray-300 dark:bg-gray-700 dark:text-gray-300'
                                            }`}
                                    >
                                        {symptom}
                                    </button>
                                ))}
                            </div>

                            {/* Dodatkowe uwagi - NOWE */}
                            <div className="mt-4">
                                <label
                                    htmlFor="additional-notes"
                                    className="text-xs font-medium text-gray-500 dark:text-gray-400"
                                >
                                    Dodatkowe uwagi (opcjonalne):
                                </label>
                                <textarea
                                    id="additional-notes"
                                    value={additionalNotes}
                                    onChange={(e) => setAdditionalNotes(e.target.value)}
                                    placeholder="Np. &quot;Objawy od 3 dni, ból nasila się wieczorem, temperatura ok. 38°C&quot;"
                                    rows={3}
                                    className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm placeholder:text-gray-400 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white dark:placeholder:text-gray-500"
                                />
                            </div>

                            {medicines.length === 0 && (
                                <p className="mt-2 text-xs text-orange-600 dark:text-orange-400">
                                    ⚠️ Apteczka jest pusta. Najpierw zaimportuj leki.
                                </p>
                            )}
                        </div>
                    </>
                )}
            </div>

            {/* Disclaimer - WZMOCNIONY dla analizy */}
            {activePrompt === 'analysis' && (
                <div className="rounded-lg border-2 border-red-200 bg-red-50 p-4 dark:border-red-800 dark:bg-red-900/20">
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
            )}

            {/* Podgląd promptu */}
            <div>
                <label className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Podgląd promptu:
                </label>
                <pre className="max-h-64 overflow-auto rounded-lg bg-gray-900 p-4 text-xs text-green-400">
                    {previewPrompt}
                </pre>
            </div>

            {/* Przycisk kopiowania */}
            <button
                onClick={handleCopy}
                disabled={activePrompt === 'analysis' && (selectedSymptoms.length === 0 || medicines.length === 0)}
                className={`w-full rounded-lg px-6 py-3 font-medium transition-colors ${copyStatus === 'copied'
                    ? 'bg-green-600 text-white'
                    : copyStatus === 'error'
                        ? 'bg-red-600 text-white'
                        : 'bg-blue-600 text-white hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed'
                    }`}
            >
                {copyStatus === 'copied' && '✅ Skopiowano!'}
                {copyStatus === 'error' && '❌ Błąd (wybierz objawy)'}
                {copyStatus === 'idle' && '📋 Kopiuj prompt do schowka'}
            </button>

            {/* Instrukcja dla importu */}
            {activePrompt === 'import' && (
                <div className="rounded-lg bg-blue-50 p-4 text-sm text-blue-800 dark:bg-blue-900/30 dark:text-blue-200">
                    <strong>💡 Jak użyć:</strong> Skopiuj prompt, wklej do ChatGPT/Claude/Gemini, dodaj zdjęcie leków, skopiuj odpowiedź JSON i zaimportuj w zakładce &quot;Import danych&quot;.
                </div>
            )}
        </div>
    );
}
