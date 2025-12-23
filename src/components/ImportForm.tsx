'use client';

// src/components/ImportForm.tsx
// Formularz do importu leków z JSON (wklej lub plik)

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

    // STEP: Duplikaty
    if (step === 'duplicates') {
        return (
            <div className="space-y-4">
                <div className="rounded-lg border-2 border-orange-300 bg-orange-50 p-4 dark:border-orange-700 dark:bg-orange-900/20">
                    <h3 className="flex items-center gap-2 font-bold text-orange-800 dark:text-orange-200">
                        ⚠️ Wykryto duplikaty
                    </h3>
                    <p className="mt-1 text-sm text-orange-700 dark:text-orange-300">
                        Niektóre leki już istnieją w Twojej apteczce. Co chcesz zrobić?
                    </p>
                </div>

                <div className="space-y-3">
                    {duplicates.map(dup => (
                        <div
                            key={dup.nazwa}
                            className="rounded-lg border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-800"
                        >
                            <p className="font-medium text-gray-900 dark:text-white">
                                {dup.nazwa}
                            </p>
                            <div className="mt-2 flex flex-wrap gap-2">
                                <button
                                    type="button"
                                    onClick={() => handleDuplicateAction(dup.nazwa, 'replace')}
                                    className={`rounded-lg px-3 py-1.5 text-sm font-medium transition-colors ${duplicateActions.get(dup.nazwa) === 'replace'
                                            ? 'bg-blue-600 text-white'
                                            : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300'
                                        }`}
                                >
                                    🔄 Zastąp istniejący
                                </button>
                                <button
                                    type="button"
                                    onClick={() => handleDuplicateAction(dup.nazwa, 'add')}
                                    className={`rounded-lg px-3 py-1.5 text-sm font-medium transition-colors ${duplicateActions.get(dup.nazwa) === 'add'
                                            ? 'bg-green-600 text-white'
                                            : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300'
                                        }`}
                                >
                                    ➕ Dodaj kolejny
                                </button>
                                <button
                                    type="button"
                                    onClick={() => handleDuplicateAction(dup.nazwa, 'skip')}
                                    className={`rounded-lg px-3 py-1.5 text-sm font-medium transition-colors ${duplicateActions.get(dup.nazwa) === 'skip'
                                            ? 'bg-gray-600 text-white'
                                            : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300'
                                        }`}
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
                        className="rounded-lg bg-blue-600 px-6 py-2 font-medium text-white hover:bg-blue-700 disabled:bg-gray-400"
                    >
                        {isProcessing ? 'Importuję...' : 'Potwierdź i importuj'}
                    </button>
                    <button
                        type="button"
                        onClick={handleCancelDuplicates}
                        className="rounded-lg border border-gray-300 px-4 py-2 text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300"
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
            <div className="space-y-4">
                <div className="rounded-lg bg-green-50 p-6 text-center dark:bg-green-900/30">
                    <p className="text-4xl">✅</p>
                    <p className="mt-2 text-lg font-medium text-green-800 dark:text-green-200">
                        {successMessage}
                    </p>
                </div>
                <button
                    type="button"
                    onClick={resetForm}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300"
                >
                    Importuj więcej
                </button>
            </div>
        );
    }

    // STEP: Input (domyślny)
    return (
        <form onSubmit={handleSubmit} className="space-y-4">
            {/* Input z pliku lub textarea */}
            <div>
                <label className="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Źródło danych:
                </label>
                <div className="flex gap-2 mb-3">
                    <button
                        type="button"
                        onClick={() => fileInputRef.current?.click()}
                        className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300"
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
                    <span className="flex items-center text-sm text-gray-500">lub wklej JSON poniżej</span>
                </div>

                <textarea
                    id="import-json"
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    placeholder={exampleJson}
                    rows={12}
                    className="w-full rounded-lg border border-gray-300 px-3 py-2 font-mono text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                />
            </div>

            {/* Błędy */}
            {errors.length > 0 && (
                <div className="rounded-lg bg-red-50 p-4 dark:bg-red-900/30">
                    <h3 className="mb-2 font-medium text-red-800 dark:text-red-200">
                        ❌ Błędy walidacji:
                    </h3>
                    <ul className="list-inside list-disc space-y-1 text-sm text-red-700 dark:text-red-300">
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
                    className="rounded-lg bg-blue-600 px-6 py-2 font-medium text-white transition-colors hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
                >
                    {isProcessing ? 'Importuję...' : 'Importuj leki'}
                </button>

                <button
                    type="button"
                    onClick={() => setInput(exampleJson)}
                    className="rounded-lg border border-gray-300 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                >
                    Wstaw przykład
                </button>
            </div>

            {/* Instrukcja */}
            <div className="rounded-lg bg-blue-50 p-4 text-sm text-blue-800 dark:bg-blue-900/30 dark:text-blue-200">
                <strong>💡 Obsługiwane formaty:</strong>
                <ul className="mt-2 list-inside list-disc space-y-1">
                    <li><strong>Import z AI</strong> – odpowiedź z ChatGPT/Claude/Gemini</li>
                    <li><strong>Backup</strong> – plik wyeksportowany z APPteczka (z terminami ważności)</li>
                </ul>
            </div>
        </form>
    );
}
