'use client';

// src/components/ImportForm.tsx
// Formularz do importu leków z JSON

import { useState } from 'react';
import { parseImportInput, validateMedicineImport, isUncertainRecognition } from '@/lib/validation';
import { importMedicines } from '@/lib/storage';
import type { Medicine } from '@/lib/types';

interface ImportFormProps {
    onImportSuccess: (medicines: Medicine[]) => void;
}

export default function ImportForm({ onImportSuccess }: ImportFormProps) {
    const [input, setInput] = useState('');
    const [errors, setErrors] = useState<string[]>([]);
    const [isProcessing, setIsProcessing] = useState(false);
    const [successMessage, setSuccessMessage] = useState('');

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

            // 3. Waliduj strukturę danych
            const validationResult = validateMedicineImport(parseResult.data);

            if (!validationResult.success) {
                setErrors(validationResult.errors);
                return;
            }

            // 4. Importuj leki
            const imported = importMedicines(validationResult.data);
            setSuccessMessage(`Zaimportowano ${imported.length} leków!`);
            setInput('');
            onImportSuccess(imported);

        } catch {
            setErrors(['Wystąpił nieoczekiwany błąd podczas importu.']);
        } finally {
            setIsProcessing(false);
        }
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

    return (
        <form onSubmit={handleSubmit} className="space-y-4">
            <div>
                <label htmlFor="import-json" className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300">
                    Wklej dane JSON z asystenta AI
                </label>
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

            {/* Sukces */}
            {successMessage && (
                <div className="rounded-lg bg-green-50 p-4 dark:bg-green-900/30">
                    <p className="font-medium text-green-800 dark:text-green-200">
                        ✅ {successMessage}
                    </p>
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
                <strong>💡 Jak użyć:</strong>
                <ol className="mt-2 list-inside list-decimal space-y-1">
                    <li>Skopiuj prompt z zakładki &quot;Generator promptów&quot;</li>
                    <li>Wklej prompt do ChatGPT, Claude lub Gemini</li>
                    <li>Dodaj zdjęcie opakowań leków</li>
                    <li>Skopiuj odpowiedź (JSON) i wklej tutaj</li>
                </ol>
            </div>
        </form>
    );
}
