'use client';

// src/app/konsultacja/page.tsx
// Strona wyszukiwania w ulotkach leków – prompt do dopasowania objawów
// Neumorphism Style

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
    const [privacyConsent, setPrivacyConsent] = useState(false);

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
            <div className="animate-fadeInUp">
                <h1 className="text-2xl font-bold" style={{ color: 'var(--color-text)' }}>
                    🔍 Wyszukiwarka w Ulotkach
                </h1>
                <p className="text-sm" style={{ color: 'var(--color-text-muted)' }}>
                    Sprawdź dopasowanie leków do objawów w oparciu o treść ulotek
                </p>
            </div>

            {/* Disclaimer */}
            <div className="neu-flat p-5 animate-fadeInUp" style={{
                animationDelay: '0.1s',
                background: 'linear-gradient(145deg, #fee2e2, #fecaca)'
            }}>
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

            {/* Brak leków */}
            {medicines.length === 0 ? (
                <div className="neu-flat p-8 text-center animate-fadeInUp" style={{
                    animationDelay: '0.2s',
                    background: 'linear-gradient(145deg, #fef3c7, #fde68a)'
                }}>
                    <div className="neu-convex w-20 h-20 mx-auto mb-4 flex items-center justify-center animate-popIn">
                        <span className="text-4xl">⚠️</span>
                    </div>
                    <p className="text-lg font-medium" style={{ color: '#92400e' }}>
                        Twoja apteczka jest pusta
                    </p>
                    <p className="mt-2 text-sm" style={{ color: '#78350f' }}>
                        Aby skorzystać z konsultacji, najpierw dodaj leki do apteczki.
                    </p>
                    <Link
                        href="/dodaj"
                        className="mt-6 inline-block neu-btn neu-btn-primary"
                    >
                        ➕ Dodaj leki →
                    </Link>
                </div>
            ) : (
                <>
                    {/* Formularz */}
                    <div className="neu-flat p-6 animate-fadeInUp" style={{ animationDelay: '0.2s' }}>
                        {/* Wybór objawów */}
                        <div>
                            <label className="block text-sm font-medium" style={{ color: 'var(--color-text)' }}>
                                🏥 Wybierz objawy:
                            </label>
                            <div className="mt-3 flex flex-wrap gap-2">
                                {ALLOWED_TAGS.objawy.map(symptom => (
                                    <button
                                        key={symptom}
                                        type="button"
                                        onClick={() => handleSymptomToggle(symptom)}
                                        className={`neu-tag transition-all ${selectedSymptoms.includes(symptom) ? 'active' : ''}`}
                                    >
                                        {symptom}
                                    </button>
                                ))}
                            </div>
                        </div>

                        {/* Dodatkowe uwagi */}
                        <div className="mt-5">
                            <label
                                htmlFor="notes"
                                className="block text-sm font-medium" style={{ color: 'var(--color-text)' }}
                            >
                                📝 Dodatkowe słowa kluczowe (opcjonalne):
                            </label>
                            <textarea
                                id="notes"
                                value={additionalNotes}
                                onChange={(e) => setAdditionalNotes(e.target.value)}
                                placeholder="Np. objawy od 3 dni, temperatura ok. 38°C, ból nasila się wieczorem..."
                                rows={3}
                                className="neu-input mt-2 text-sm"
                                style={{ resize: 'vertical' }}
                            />
                            <p className="mt-1 text-xs" style={{ color: 'var(--color-warning)' }}>
                                ⚠️ Nie wpisuj danych osobowych (imienia, nazwiska, PESEL)
                            </p>
                        </div>

                        {/* Info o apteczce */}
                        <div className="neu-flat-sm mt-5 p-3">
                            <p className="text-xs" style={{ color: 'var(--color-text-muted)' }}>
                                📦 Prompt zawrze listę {medicines.length} leków z Twojej apteczki
                            </p>
                        </div>
                    </div>

                    {/* Podgląd promptu */}
                    {previewPrompt && (
                        <div className="neu-flat p-6 animate-fadeInUp" style={{ animationDelay: '0.3s' }}>
                            <label className="block text-sm font-medium" style={{ color: 'var(--color-text)' }}>
                                📄 Podgląd promptu:
                            </label>
                            <pre className="mt-2 max-h-64 overflow-auto rounded-lg p-4 text-xs" style={{ background: '#1a1f1c', color: 'var(--color-accent-light)' }}>
                                {previewPrompt}
                            </pre>
                        </div>
                    )}

                    {/* Checkbox zgody RODO */}
                    <div className="neu-flat p-4 animate-fadeInUp" style={{
                        animationDelay: '0.35s',
                        background: 'linear-gradient(145deg, #fef3c7, #fde68a)'
                    }}>
                        <label className="flex items-start gap-3 cursor-pointer">
                            <input
                                type="checkbox"
                                checked={privacyConsent}
                                onChange={(e) => setPrivacyConsent(e.target.checked)}
                                className="mt-1 w-4 h-4 accent-amber-600"
                            />
                            <span className="text-xs" style={{ color: '#78350f' }}>
                                Rozumiem, że kopiując ten tekst, przenoszę moje dane o objawach do zewnętrznego narzędzia
                                (np. ChatGPT), które posiada własną politykę prywatności, niezależną od APPteczki.
                            </span>
                        </label>
                    </div>

                    {/* Przycisk kopiowania */}
                    <button
                        onClick={handleCopyPrompt}
                        disabled={selectedSymptoms.length === 0 || !privacyConsent}
                        className={`w-full neu-btn ${copyStatus === 'copied'
                            ? ''
                            : copyStatus === 'error'
                                ? ''
                                : 'neu-btn-primary'
                            } disabled:opacity-50 disabled:cursor-not-allowed animate-fadeInUp`}
                        style={{
                            animationDelay: '0.4s',
                            ...(copyStatus === 'copied'
                                ? { background: 'var(--color-success)', color: 'white' }
                                : copyStatus === 'error'
                                    ? { background: 'var(--color-error)', color: 'white' }
                                    : {})
                        }}
                    >
                        {copyStatus === 'copied' && '✅ Skopiowano! Wklej do ChatGPT/Claude/Gemini'}
                        {copyStatus === 'error' && '❌ Wybierz przynajmniej jeden objaw'}
                        {copyStatus === 'idle' && '📋 Kopiuj prompt do schowka'}
                    </button>

                    {/* Instrukcja */}
                    <div className="neu-flat p-4 animate-fadeInUp" style={{ animationDelay: '0.5s' }}>
                        <p className="text-sm" style={{ color: 'var(--color-accent)' }}>
                            <strong>💡 Jak użyć:</strong> Skopiuj prompt i wklej do ChatGPT, Claude lub Gemini.
                            AI wyszuka w ulotkach leków z Twojej apteczki te, które zawierają wybrane objawy we wskazaniach.
                        </p>
                    </div>
                </>
            )}
        </div>
    );
}
