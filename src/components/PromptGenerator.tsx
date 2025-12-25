'use client';

// src/components/PromptGenerator.tsx
// Generator promptów do kopiowania - Neumorphism Style

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
            <div className="neu-flat-sm p-1 inline-flex gap-1">
                <button
                    onClick={() => setActivePrompt('import')}
                    className={`neu-tag transition-all ${activePrompt === 'import' ? 'active' : ''}`}
                >
                    📷 Rozpoznawanie leków
                </button>
                <button
                    onClick={() => setActivePrompt('analysis')}
                    className={`neu-tag transition-all ${activePrompt === 'analysis' ? 'active' : ''}`}
                >
                    📄 Analiza ulotek
                </button>
            </div>

            {/* Opis promptu */}
            <div className="neu-flat p-5">
                {activePrompt === 'import' ? (
                    <>
                        <h3 className="font-medium" style={{ color: 'var(--color-text)' }}>
                            📷 Prompt do rozpoznawania leków ze zdjęcia
                        </h3>
                        <p className="mt-1 text-sm" style={{ color: 'var(--color-text-muted)' }}>
                            Wklej ten prompt do ChatGPT, Claude lub Gemini, a następnie dodaj zdjęcie opakowań leków.
                            AI zwróci dane w formacie JSON, które możesz zaimportować do apteczki.
                        </p>
                    </>
                ) : (
                    <>
                        <h3 className="font-medium" style={{ color: 'var(--color-text)' }}>
                            📄 Wyszukiwanie w ulotkach leków
                        </h3>
                        <p className="mt-1 text-sm" style={{ color: 'var(--color-text-muted)' }}>
                            AI wyszuka w ulotkach (ChPL) leków z Twojej apteczki te, które zawierają wybrane objawy we wskazaniach.
                        </p>

                        {/* Wybór objawów */}
                        <div className="mt-4">
                            <span className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>
                                Wybierz objawy:
                            </span>
                            <div className="mt-2 flex flex-wrap gap-1.5">
                                {ALLOWED_TAGS.objawy.map(symptom => (
                                    <button
                                        key={symptom}
                                        onClick={() => handleSymptomToggle(symptom)}
                                        className={`neu-tag text-xs transition-all ${selectedSymptoms.includes(symptom) ? 'active' : ''}`}
                                    >
                                        {symptom}
                                    </button>
                                ))}
                            </div>

                            {/* Dodatkowe uwagi */}
                            <div className="mt-4">
                                <label
                                    htmlFor="additional-notes"
                                    className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}
                                >
                                    Dodatkowe słowa kluczowe (opcjonalne):
                                </label>
                                <textarea
                                    id="additional-notes"
                                    value={additionalNotes}
                                    onChange={(e) => setAdditionalNotes(e.target.value)}
                                    placeholder='Np. "Objawy od 3 dni, ból nasila się wieczorem, temperatura ok. 38°C"'
                                    rows={3}
                                    className="neu-input mt-1 text-sm"
                                    style={{ resize: 'vertical' }}
                                />
                                <p className="mt-1 text-xs" style={{ color: 'var(--color-warning)' }}>
                                    ⚠️ Nie wpisuj danych osobowych (imienia, nazwiska, PESEL)
                                </p>
                            </div>

                            {medicines.length === 0 && (
                                <p className="mt-2 text-xs" style={{ color: 'var(--color-warning)' }}>
                                    ⚠️ Apteczka jest pusta. Najpierw zaimportuj leki.
                                </p>
                            )}
                        </div>
                    </>
                )}
            </div>

            {/* Disclaimer - WZMOCNIONY dla analizy */}
            {activePrompt === 'analysis' && (
                <div className="neu-flat p-4" style={{ background: 'linear-gradient(145deg, #fee2e2, #fecaca)' }}>
                    <div className="flex items-start gap-3">
                        <span className="text-2xl">⚠️</span>
                        <div>
                            <h4 className="font-bold" style={{ color: '#991b1b' }}>
                                WAŻNE – przeczytaj przed użyciem
                            </h4>
                            <ul className="mt-2 space-y-1 text-sm" style={{ color: '#7f1d1d' }}>
                                <li>• To jest <strong>wyszukiwarka informacji</strong>, NIE porada medyczna</li>
                                <li>• AI może się mylić – zawsze weryfikuj informacje w pełnej ulotce</li>
                                <li>• <strong>Aplikacja NIE weryfikuje interakcji międzylekowych</strong></li>
                                <li>• W nagłych przypadkach dzwoń na 112 lub jedź na izbę przyjęć</li>
                                <li>• Przed przyjęciem leku przeczytaj ulotkę i skonsultuj się z lekarzem/farmaceutą</li>
                            </ul>
                        </div>
                    </div>
                </div>
            )}

            {/* Podgląd promptu */}
            <div>
                <label className="mb-1 block text-sm font-medium" style={{ color: 'var(--color-text)' }}>
                    📄 Podgląd promptu:
                </label>
                <pre className="max-h-64 overflow-auto rounded-lg p-4 text-xs" style={{ background: '#1a1f1c', color: 'var(--color-accent-light)' }}>
                    {previewPrompt}
                </pre>
            </div>

            {/* Przycisk kopiowania */}
            <button
                onClick={handleCopy}
                disabled={activePrompt === 'analysis' && (selectedSymptoms.length === 0 || medicines.length === 0)}
                className={`w-full neu-btn ${copyStatus === 'copied'
                    ? ''
                    : copyStatus === 'error'
                        ? ''
                        : 'neu-btn-primary'
                    } disabled:opacity-50 disabled:cursor-not-allowed`}
                style={
                    copyStatus === 'copied'
                        ? { background: 'var(--color-success)', color: 'white' }
                        : copyStatus === 'error'
                            ? { background: 'var(--color-error)', color: 'white' }
                            : {}
                }
            >
                {copyStatus === 'copied' && '✅ Skopiowano!'}
                {copyStatus === 'error' && '❌ Błąd (wybierz objawy)'}
                {copyStatus === 'idle' && '📋 Kopiuj prompt do schowka'}
            </button>

            {/* Instrukcja dla importu */}
            {activePrompt === 'import' && (
                <div className="neu-flat p-4">
                    <p className="text-sm" style={{ color: 'var(--color-accent)' }}>
                        <strong>💡 Jak użyć:</strong> Skopiuj prompt, wklej do ChatGPT/Claude/Gemini, dodaj zdjęcie leków, skopiuj odpowiedź JSON i zaimportuj w zakładce &quot;Import danych&quot;.
                    </p>
                </div>
            )}
        </div>
    );
}
