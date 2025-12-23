'use client';

// src/app/backup/page.tsx
// Strona kopii zapasowej – eksport i instrukcje

import { useState, useEffect } from 'react';
import { getMedicines, exportMedicines } from '@/lib/storage';
import Link from 'next/link';

export default function BackupPage() {
    const [medicineCount, setMedicineCount] = useState(0);
    const [copyStatus, setCopyStatus] = useState<'idle' | 'copied' | 'error'>('idle');
    const [downloadStatus, setDownloadStatus] = useState<'idle' | 'success' | 'error'>('idle');

    useEffect(() => {
        setMedicineCount(getMedicines().length);
    }, []);

    const handleDownload = () => {
        try {
            const json = exportMedicines();
            const dataUrl = 'data:application/json;charset=utf-8,' + encodeURIComponent(json);
            const link = document.createElement('a');
            link.setAttribute('href', dataUrl);
            link.setAttribute('download', `apteczka_backup_${new Date().toISOString().split('T')[0]}.json`);
            link.style.display = 'none';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            setDownloadStatus('success');
            setTimeout(() => setDownloadStatus('idle'), 3000);
        } catch {
            setDownloadStatus('error');
            setTimeout(() => setDownloadStatus('idle'), 3000);
        }
    };

    const handleCopyJson = async () => {
        try {
            const json = exportMedicines();
            await navigator.clipboard.writeText(json);
            setCopyStatus('copied');
            setTimeout(() => setCopyStatus('idle'), 2000);
        } catch {
            setCopyStatus('error');
            setTimeout(() => setCopyStatus('idle'), 2000);
        }
    };

    const exampleBackup = `{
  "leki": [
    {
      "id": "abc-123",
      "nazwa": "Paracetamol",
      "opis": "Lek przeciwbólowy...",
      "wskazania": ["ból głowy"],
      "tagi": ["przeciwbólowy"],
      "terminWaznosci": "2025-12-31",
      "dataDodania": "2024-01-15"
    }
  ]
}`;

    return (
        <div className="space-y-6">
            {/* Nagłówek */}
            <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                    💾 Kopia zapasowa
                </h1>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                    Pobierz lub skopiuj dane apteczki, aby je zachować lub przenieść
                </p>
            </div>

            {/* Status */}
            <div className="rounded-xl bg-gradient-to-r from-blue-50 to-indigo-50 p-6 dark:from-blue-900/20 dark:to-indigo-900/20">
                <div className="flex items-center gap-4">
                    <div className="flex h-12 w-12 items-center justify-center rounded-full bg-blue-100 text-2xl dark:bg-blue-900">
                        📦
                    </div>
                    <div>
                        <p className="text-sm text-gray-600 dark:text-gray-400">Leków w apteczce:</p>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white">{medicineCount}</p>
                    </div>
                </div>
            </div>

            {medicineCount === 0 ? (
                <div className="rounded-xl bg-orange-50 p-6 text-center dark:bg-orange-900/20">
                    <p className="text-lg font-medium text-orange-800 dark:text-orange-200">
                        📭 Apteczka jest pusta
                    </p>
                    <p className="mt-2 text-sm text-orange-700 dark:text-orange-300">
                        Nie ma czego eksportować. Najpierw dodaj leki.
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
                    {/* Eksport */}
                    <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                        <h2 className="font-semibold text-gray-900 dark:text-white">
                            Eksportuj dane
                        </h2>
                        <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">
                            Plik zawiera wszystkie leki wraz z terminami ważności i datami dodania.
                        </p>

                        <div className="mt-4 flex flex-wrap gap-3">
                            {/* Pobierz plik */}
                            <button
                                onClick={handleDownload}
                                className={`flex items-center gap-2 rounded-lg px-4 py-2 font-medium transition-colors ${downloadStatus === 'success'
                                        ? 'bg-green-600 text-white'
                                        : downloadStatus === 'error'
                                            ? 'bg-red-600 text-white'
                                            : 'bg-blue-600 text-white hover:bg-blue-700'
                                    }`}
                            >
                                <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                                </svg>
                                {downloadStatus === 'success' && '✅ Pobrano!'}
                                {downloadStatus === 'error' && '❌ Błąd pobierania'}
                                {downloadStatus === 'idle' && 'Pobierz plik .json'}
                            </button>

                            {/* Kopiuj JSON */}
                            <button
                                onClick={handleCopyJson}
                                className={`flex items-center gap-2 rounded-lg border px-4 py-2 font-medium transition-colors ${copyStatus === 'copied'
                                        ? 'border-green-600 bg-green-50 text-green-700'
                                        : 'border-gray-300 text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300'
                                    }`}
                            >
                                <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                                </svg>
                                {copyStatus === 'copied' ? '✅ Skopiowano!' : 'Kopiuj JSON'}
                            </button>
                        </div>
                    </div>

                    {/* Gdy pobieranie nie działa */}
                    <div className="rounded-xl bg-yellow-50 p-6 dark:bg-yellow-900/20">
                        <h3 className="font-semibold text-yellow-800 dark:text-yellow-200">
                            ⚠️ Pobieranie nie działa?
                        </h3>
                        <p className="mt-2 text-sm text-yellow-700 dark:text-yellow-300">
                            Niektóre przeglądarki zarządzane przez organizację blokują pobieranie plików.
                            W takim przypadku:
                        </p>
                        <ol className="mt-3 list-inside list-decimal space-y-1 text-sm text-yellow-700 dark:text-yellow-300">
                            <li>Kliknij <strong>&quot;Kopiuj JSON&quot;</strong> powyżej</li>
                            <li>Otwórz Notatnik (Windows) lub TextEdit (Mac)</li>
                            <li>Wklej skopiowany tekst (Ctrl+V)</li>
                            <li>Zapisz jako <code className="rounded bg-yellow-100 px-1 dark:bg-yellow-800">apteczka_backup.json</code></li>
                        </ol>
                    </div>
                </>
            )}

            {/* Przywracanie */}
            <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                <h2 className="font-semibold text-gray-900 dark:text-white">
                    📥 Przywracanie kopii zapasowej
                </h2>
                <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">
                    Aby przywrócić dane z kopii zapasowej, przejdź do zakładki <strong>&quot;Dodaj leki&quot;</strong>
                    i wczytaj plik .json lub wklej skopiowany JSON.
                </p>
                <Link
                    href="/dodaj"
                    className="mt-4 inline-flex items-center gap-2 rounded-lg border border-blue-600 px-4 py-2 text-sm font-medium text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20"
                >
                    Przejdź do importu →
                </Link>
            </div>

            {/* Format pliku */}
            <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                <h2 className="font-semibold text-gray-900 dark:text-white">
                    📄 Format pliku kopii zapasowej
                </h2>
                <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">
                    Jeśli chcesz ręcznie utworzyć lub edytować plik, użyj tego formatu:
                </p>
                <pre className="mt-3 overflow-auto rounded-lg bg-gray-900 p-4 text-xs text-green-400">
                    {exampleBackup}
                </pre>
                <p className="mt-3 text-xs text-gray-500 dark:text-gray-400">
                    Pola <code>id</code> i <code>dataDodania</code> zostaną wygenerowane automatycznie przy imporcie, jeśli ich brakuje.
                </p>
            </div>
        </div>
    );
}
