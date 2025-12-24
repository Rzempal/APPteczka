'use client';

// src/components/ImportForm.tsx
// Formularz do importu leków z JSON - Neumorphism Style

import { useState, useRef } from 'react';
import { parseImportInput, validateMedicineImport, isUncertainRecognition } from '@/lib/validation';
import {
    findDuplicates,
    importMedicinesWithDuplicateHandling,
    importBackup,
    isBackupFormat,
    type DuplicateAction
} from '@/lib/storage';
import type { Medicine } from '@/lib/types';

interface ImportFormProps {
    onImportSuccess: (medicines: Medicine[]) => void;
}

interface DuplicateInfo {
    nazwa: string;
    existingId: string;
}

type ImportStep = 'input' | 'duplicates' | 'success';

export default function ImportForm({ onImportSuccess }: ImportFormProps) {
    const [input, setInput] = useState('');
    const [errors, setErrors] = useState<string[]>([]);
    const [isProcessing, setIsProcessing] = useState(false);
    const [successMessage, setSuccessMessage] = useState('');

    // Stan dla obsługi duplikatów
    const [step, setStep] = useState<ImportStep>('input');
    const [duplicates, setDuplicates] = useState<DuplicateInfo[]>([]);
    const [duplicateActions, setDuplicateActions] = useState<Map<string, DuplicateAction>>(new Map());
    const [pendingData, setPendingData] = useState<unknown>(null);
    const [isBackup, setIsBackup] = useState(false);

    const fileInputRef = useRef<HTMLInputElement>(null);

    const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        try {
            const text = await file.text();
            setInput(text);
            setErrors([]);
        } catch {
            setErrors(['Nie udało się odczytać pliku.']);
        }

        // Reset input
        if (fileInputRef.current) {
            fileInputRef.current.value = '';
        }
    };

    const processImport = async (data: unknown) => {
        const backupFormat = isBackupFormat(data);
        setIsBackup(backupFormat);

        // Sprawdź duplikaty
        const leki = (data as { leki: { nazwa: string | null }[] }).leki;
        const foundDuplicates = findDuplicates(leki);

        if (foundDuplicates.length > 0) {
            // Są duplikaty - pokaż dialog
            setDuplicates(foundDuplicates);
            setPendingData(data);

            // Domyślnie: dodaj kolejny
            const defaultActions = new Map<string, DuplicateAction>();
            foundDuplicates.forEach(d => defaultActions.set(d.nazwa, 'add'));
            setDuplicateActions(defaultActions);

            setStep('duplicates');
            return;
        }

        // Brak duplikatów - importuj od razu
        await executeImport(data, backupFormat, new Map());
    };

    const executeImport = async (
        data: unknown,
        backupFormat: boolean,
        actions: Map<string, DuplicateAction>
    ) => {
        try {
            let imported: Medicine[];

            if (backupFormat) {
                imported = importBackup(data as { leki: Medicine[] }, actions);
            } else {
                const validationResult = validateMedicineImport(data);
                if (!validationResult.success) {
                    setErrors(validationResult.errors);
                    setStep('input');
                    return;
                }
                imported = importMedicinesWithDuplicateHandling(validationResult.data, actions);
            }

            const replacedCount = Array.from(actions.values()).filter(a => a === 'replace').length;
            const skippedCount = Array.from(actions.values()).filter(a => a === 'skip').length;

            let message = `Zaimportowano ${imported.length} leków`;
            if (replacedCount > 0) message += `, zastąpiono ${replacedCount}`;
            if (skippedCount > 0) message += `, pominięto ${skippedCount}`;

            setSuccessMessage(message + '!');
            setInput('');
            setStep('success');
            onImportSuccess(imported);

        } catch {
            setErrors(['Wystąpił nieoczekiwany błąd podczas importu.']);
            setStep('input');
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setErrors([]);
        setSuccessMessage('');
        setIsProcessing(true);

        try {
            // 1. Parsuj input
            const parseResult = parseImportInput(input);

            if ('error' in parseResult) {
                setErrors([parseResult.error]);
                return;
            }

            // 2. Sprawdź czy to "niepewne rozpoznanie" z AI
            if (isUncertainRecognition(parseResult.data)) {
                setErrors([
                    'AI zwróciło "niepewne rozpoznanie". Wybierz jedną z opcji:',
                    'A) Zrób lepsze zdjęcie',
                    'B) Podaj nazwę leku ręcznie',
                    'C) Zostaw nazwę pustą i spróbuj ponownie'
                ]);
                return;
            }

            // 3. Sprawdź czy są leki
            const data = parseResult.data as { leki?: unknown[] };
            if (!data.leki || data.leki.length === 0) {
                setErrors(['Brak leków do zaimportowania.']);
                return;
            }

            // 4. Przetwórz import (sprawdzi duplikaty)
            await processImport(parseResult.data);

        } catch {
            setErrors(['Wystąpił nieoczekiwany błąd podczas importu.']);
        } finally {
            setIsProcessing(false);
        }
    };

    const handleDuplicateAction = (nazwa: string, action: DuplicateAction) => {
        const newActions = new Map(duplicateActions);
        newActions.set(nazwa, action);
        setDuplicateActions(newActions);
    };

    const handleConfirmDuplicates = async () => {
        setIsProcessing(true);
        await executeImport(pendingData, isBackup, duplicateActions);
        setIsProcessing(false);
    };

    const handleCancelDuplicates = () => {
        setStep('input');
        setDuplicates([]);
        setPendingData(null);
    };

    const resetForm = () => {
        setStep('input');
        setSuccessMessage('');
        setErrors([]);
        setDuplicates([]);
    };

    const exampleJson = `{
  "leki": [
    {
      "nazwa": "Paracetamol",
      "opis": "Lek przeciwbólowy i przeciwgorączkowy. Stosować zgodnie z ulotką.",
      "wskazania": ["ból głowy", "gorączka"],
      "tagi": ["przeciwbólowy", "przeciwgorączkowy", "dla dorosłych"]
    }
  ]
}`;

    // Bulk actions for all duplicates
    const setAllDuplicateActions = (action: DuplicateAction) => {
        const newActions = new Map<string, DuplicateAction>();
        duplicates.forEach(d => newActions.set(d.nazwa, action));
        setDuplicateActions(newActions);
    };

    // STEP: Duplikaty
    if (step === 'duplicates') {
        return (
            <div className="space-y-4 animate-fadeInUp">
                <div className="neu-flat p-4" style={{ background: 'linear-gradient(145deg, #fef3c7, #fde68a)' }}>
                    <h3 className="flex items-center gap-2 font-bold" style={{ color: '#92400e' }}>
                        ⚠️ Wykryto duplikaty
                    </h3>
                    <p className="mt-1 text-sm" style={{ color: '#78350f' }}>
                        Niektóre leki już istnieją w Twojej apteczce. Co chcesz zrobić?
                    </p>

                    {/* Bulk action buttons */}
                    <div className="mt-3 flex flex-wrap gap-2">
                        <button
                            type="button"
                            onClick={() => setAllDuplicateActions('replace')}
                            className="neu-tag text-xs transition-all hover:scale-105"
                            style={{ background: 'rgba(255,255,255,0.5)' }}
                        >
                            🔄 Zastąp wszystkie
                        </button>
                        <button
                            type="button"
                            onClick={() => setAllDuplicateActions('add')}
                            className="neu-tag text-xs transition-all hover:scale-105"
                            style={{ background: 'rgba(255,255,255,0.5)' }}
                        >
                            ➕ Dodaj wszystkie
                        </button>
                        <button
                            type="button"
                            onClick={() => setAllDuplicateActions('skip')}
                            className="neu-tag text-xs transition-all hover:scale-105"
                            style={{ background: 'rgba(255,255,255,0.5)' }}
                        >
                            ⏭️ Pomiń wszystkie
                        </button>
                    </div>
                </div>

                <div className="space-y-3">
                    {duplicates.map(dup => (
                        <div
                            key={dup.nazwa}
                            className="neu-flat p-4"
                        >
                            <p className="font-medium" style={{ color: 'var(--color-text)' }}>
                                {dup.nazwa}
                            </p>
                            <div className="mt-3 flex flex-wrap gap-2">
                                <button
                                    type="button"
                                    onClick={() => handleDuplicateAction(dup.nazwa, 'replace')}
                                    className={`neu-tag transition-all ${duplicateActions.get(dup.nazwa) === 'replace' ? 'active' : ''}`}
                                >
                                    🔄 Zastąp istniejący
                                </button>
                                <button
                                    type="button"
                                    onClick={() => handleDuplicateAction(dup.nazwa, 'add')}
                                    className={`neu-tag transition-all ${duplicateActions.get(dup.nazwa) === 'add' ? 'active' : ''}`}
                                >
                                    ➕ Dodaj kolejny
                                </button>
                                <button
                                    type="button"
                                    onClick={() => handleDuplicateAction(dup.nazwa, 'skip')}
                                    className={`neu-tag transition-all ${duplicateActions.get(dup.nazwa) === 'skip' ? 'active' : ''}`}
                                >
                                    ⏭️ Pomiń
                                </button>
                            </div>
                        </div>
                    ))}
                </div>

                <div className="flex gap-3">
                    <button
                        type="button"
                        onClick={handleConfirmDuplicates}
                        disabled={isProcessing}
                        className="neu-btn neu-btn-primary"
                    >
                        {isProcessing ? '⏳ Importuję...' : '✅ Potwierdź i importuj'}
                    </button>
                    <button
                        type="button"
                        onClick={handleCancelDuplicates}
                        className="neu-btn neu-btn-secondary"
                    >
                        Anuluj
                    </button>
                </div>
            </div>
        );
    }

    // STEP: Sukces
    if (step === 'success') {
        return (
            <div className="space-y-4 animate-fadeInUp">
                <div className="neu-flat p-8 text-center" style={{ background: 'linear-gradient(145deg, #d1fae5, #a7f3d0)' }}>
                    <div className="neu-convex w-20 h-20 mx-auto mb-4 flex items-center justify-center animate-popIn">
                        <span className="text-4xl">✅</span>
                    </div>
                    <p className="text-lg font-medium" style={{ color: '#065f46' }}>
                        {successMessage}
                    </p>
                </div>
                <button
                    type="button"
                    onClick={resetForm}
                    className="w-full neu-btn neu-btn-secondary"
                >
                    ➕ Importuj więcej
                </button>
            </div>
        );
    }

    // STEP: Input (domyślny)
    return (
        <form onSubmit={handleSubmit} className="space-y-4 animate-fadeInUp">
            {/* Input z pliku lub textarea */}
            <div>
                <label className="mb-2 block text-sm font-medium" style={{ color: 'var(--color-text)' }}>
                    📄 Źródło danych:
                </label>
                <div className="flex gap-2 mb-3">
                    <button
                        type="button"
                        onClick={() => fileInputRef.current?.click()}
                        className="neu-btn neu-btn-secondary text-sm"
                    >
                        <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                        </svg>
                        Wczytaj z pliku
                    </button>
                    <input
                        ref={fileInputRef}
                        type="file"
                        accept=".json"
                        onChange={handleFileChange}
                        className="hidden"
                    />
                    <span className="flex items-center text-sm" style={{ color: 'var(--color-text-muted)' }}>lub wklej JSON poniżej</span>
                </div>

                <textarea
                    id="import-json"
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    placeholder={exampleJson}
                    rows={12}
                    className="neu-input font-mono text-sm"
                    style={{ resize: 'vertical' }}
                />
            </div>

            {/* Błędy */}
            {errors.length > 0 && (
                <div className="neu-flat p-4" style={{ background: 'linear-gradient(145deg, #fee2e2, #fecaca)' }}>
                    <h3 className="mb-2 font-medium" style={{ color: '#991b1b' }}>
                        ❌ Błędy walidacji:
                    </h3>
                    <ul className="list-inside list-disc space-y-1 text-sm" style={{ color: '#7f1d1d' }}>
                        {errors.map((error, i) => (
                            <li key={i}>{error}</li>
                        ))}
                    </ul>
                </div>
            )}

            <div className="flex gap-3">
                <button
                    type="submit"
                    disabled={!input.trim() || isProcessing}
                    className="neu-btn neu-btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    {isProcessing ? '⏳ Importuję...' : '📥 Importuj leki'}
                </button>

                <button
                    type="button"
                    onClick={() => setInput(exampleJson)}
                    className="neu-btn neu-btn-secondary text-sm"
                >
                    📝 Wstaw przykład
                </button>
            </div>

            {/* Instrukcja */}
            <div className="neu-flat p-4">
                <p className="text-sm font-medium" style={{ color: 'var(--color-accent)' }}>
                    💡 Obsługiwane formaty:
                </p>
                <ul className="mt-2 list-inside list-disc space-y-1 text-sm" style={{ color: 'var(--color-text-muted)' }}>
                    <li><strong>Import z AI</strong> – odpowiedź z ChatGPT/Claude/Gemini</li>
                    <li><strong>Backup</strong> – plik wyeksportowany z APPteczka (z terminami ważności)</li>
                </ul>
            </div>
        </form>
    );
}
