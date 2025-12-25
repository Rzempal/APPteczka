'use client';

// src/components/PromptGenerator.tsx
// Generator promptu do rozpoznawania leków ze zdjęcia (OCR) - Neumorphism Style

import { useState } from 'react';
import { generateImportPrompt, copyToClipboard } from '@/lib/prompts';

export default function PromptGenerator() {
    const [copyStatus, setCopyStatus] = useState<'idle' | 'copied' | 'error'>('idle');

    const handleCopy = async () => {
        const prompt = generateImportPrompt();
        const success = await copyToClipboard(prompt);
        setCopyStatus(success ? 'copied' : 'error');
        setTimeout(() => setCopyStatus('idle'), 2000);
    };

    const previewPrompt = generateImportPrompt();

    return (
        <div className="space-y-4">
            {/* Opis promptu */}
            <div className="neu-flat p-5">
                <h3 className="font-medium" style={{ color: 'var(--color-text)' }}>
                    📷 Prompt do rozpoznawania leków ze zdjęcia
                </h3>
                <p className="mt-1 text-sm" style={{ color: 'var(--color-text-muted)' }}>
                    Wklej ten prompt do ChatGPT, Claude lub Gemini, a następnie dodaj zdjęcie opakowań leków.
                    AI zwróci dane w formacie JSON, które możesz zaimportować do apteczki.
                </p>
            </div>

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
                className={`w-full neu-btn ${copyStatus === 'copied'
                    ? ''
                    : copyStatus === 'error'
                        ? ''
                        : 'neu-btn-primary'
                    }`}
                style={
                    copyStatus === 'copied'
                        ? { background: 'var(--color-success)', color: 'white' }
                        : copyStatus === 'error'
                            ? { background: 'var(--color-error)', color: 'white' }
                            : {}
                }
            >
                {copyStatus === 'copied' && '✅ Skopiowano!'}
                {copyStatus === 'error' && '❌ Błąd kopiowania'}
                {copyStatus === 'idle' && '📋 Kopiuj prompt do schowka'}
            </button>

            {/* Instrukcja */}
            <div className="neu-flat p-4">
                <p className="text-sm" style={{ color: 'var(--color-accent)' }}>
                    <strong>💡 Jak użyć:</strong> Skopiuj prompt, wklej do ChatGPT/Claude/Gemini, dodaj zdjęcie leków, skopiuj odpowiedź JSON i zaimportuj w zakładce &quot;Import danych&quot;.
                </p>
            </div>
        </div>
    );
}
