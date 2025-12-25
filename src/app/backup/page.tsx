'use client';

// src/app/backup/page.tsx
// Strona kopii zapasowej – eksport i instrukcje
// Neumorphism Style

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
      "labels": ["label-id-1"],
      "notatka": "Dawkowanie: 1 tabletka co 6h",
      "terminWaznosci": "2025-12-31",
      "dataDodania": "2024-01-15"
    }
  ]
}`;

    return (
        <div className="space-y-6">
            {/* Nagłówek */}
            <div className="animate-fadeInUp">
                <h1 className="text-2xl font-bold" style={{ color: 'var(--color-text)' }}>
                    💾 Kopia zapasowa
                </h1>
                <p className="text-sm" style={{ color: 'var(--color-text-muted)' }}>
                    Pobierz lub skopiuj dane apteczki, aby je zachować lub przenieść
                </p>
            </div>

            {/* Status */}
            <div className="neu-flat p-6 animate-fadeInUp" style={{
                animationDelay: '0.1s',
                background: 'linear-gradient(145deg, var(--color-bg-light), var(--color-bg-dark))'
            }}>
                <div className="flex items-center gap-4">
                    <div className="neu-convex flex h-14 w-14 items-center justify-center text-3xl" style={{ borderRadius: '50%' }}>
                        📦
                    </div>
                    <div>
                        <p className="text-sm" style={{ color: 'var(--color-text-muted)' }}>Leków w apteczce:</p>
                        <p className="text-3xl font-bold" style={{ color: 'var(--color-accent)' }}>{medicineCount}</p>
                    </div>
                </div>
            </div>

            {medicineCount === 0 ? (
                <div className="neu-flat p-8 text-center animate-fadeInUp" style={{
                    animationDelay: '0.2s',
                    background: 'linear-gradient(145deg, #fef3c7, #fde68a)'
                }}>
                    <div className="neu-convex w-20 h-20 mx-auto mb-4 flex items-center justify-center animate-popIn">
                        <span className="text-4xl">📭</span>
                    </div>
                    <p className="text-lg font-medium" style={{ color: '#92400e' }}>
                        Apteczka jest pusta
                    </p>
                    <p className="mt-2 text-sm" style={{ color: '#78350f' }}>
                        Nie ma czego eksportować. Najpierw dodaj leki.
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
                    {/* Eksport */}
                    <div className="neu-flat p-6 animate-fadeInUp" style={{ animationDelay: '0.2s' }}>
                        <h2 className="font-semibold" style={{ color: 'var(--color-text)' }}>
                            📤 Eksportuj dane
                        </h2>
                        <p className="mt-1 text-sm" style={{ color: 'var(--color-text-muted)' }}>
                            Plik zawiera wszystkie leki wraz z terminami ważności i datami dodania.
                        </p>

                        <div className="mt-4 flex flex-wrap gap-3">
                            {/* Pobierz plik */}
                            <button
                                onClick={handleDownload}
                                className={`neu-btn ${downloadStatus === 'success'
                                    ? ''
                                    : downloadStatus === 'error'
                                        ? ''
                                        : 'neu-btn-primary'
                                    }`}
                                style={
                                    downloadStatus === 'success'
                                        ? { background: 'var(--color-success)', color: 'white' }
                                        : downloadStatus === 'error'
                                            ? { background: 'var(--color-error)', color: 'white' }
                                            : {}
                                }
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
                                className={`neu-btn neu-btn-secondary ${copyStatus === 'copied' ? '' : ''}`}
                                style={copyStatus === 'copied' ? { color: 'var(--color-success)' } : {}}
                            >
                                <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                                </svg>
                                {copyStatus === 'copied' ? '✅ Skopiowano!' : 'Kopiuj JSON'}
                            </button>
                        </div>
                    </div>

                    {/* Gdy pobieranie nie działa */}
                    <div className="neu-flat p-5 animate-fadeInUp" style={{
                        animationDelay: '0.3s',
                        background: 'linear-gradient(145deg, #fef3c7, #fde68a)'
                    }}>
                        <h3 className="font-semibold" style={{ color: '#92400e' }}>
                            ⚠️ Pobieranie nie działa?
                        </h3>
                        <p className="mt-2 text-sm" style={{ color: '#78350f' }}>
                            Niektóre przeglądarki zarządzane przez organizację blokują pobieranie plików.
                            W takim przypadku:
                        </p>
                        <ol className="mt-3 list-inside list-decimal space-y-1 text-sm" style={{ color: '#78350f' }}>
                            <li>Kliknij <strong>&quot;Kopiuj JSON&quot;</strong> powyżej</li>
                            <li>Otwórz Notatnik (Windows) lub TextEdit (Mac)</li>
                            <li>Wklej skopiowany tekst (Ctrl+V)</li>
                            <li>Zapisz jako <code className="neu-tag text-xs">apteczka_backup.json</code></li>
                        </ol>
                    </div>
                </>
            )}

            {/* Przywracanie */}
            <div className="neu-flat p-6 animate-fadeInUp" style={{ animationDelay: '0.4s' }}>
                <h2 className="font-semibold" style={{ color: 'var(--color-text)' }}>
                    📥 Przywracanie kopii zapasowej
                </h2>
                <p className="mt-1 text-sm" style={{ color: 'var(--color-text-muted)' }}>
                    Aby przywrócić dane z kopii zapasowej, przejdź do zakładki <strong>&quot;Dodaj leki&quot;</strong>
                    i wczytaj plik .json lub wklej skopiowany JSON.
                </p>
                <Link
                    href="/dodaj"
                    className="mt-4 inline-block neu-btn neu-btn-secondary"
                >
                    Przejdź do importu →
                </Link>
            </div>

            {/* Format pliku */}
            <div className="neu-flat p-6 animate-fadeInUp" style={{ animationDelay: '0.5s' }}>
                <h2 className="font-semibold" style={{ color: 'var(--color-text)' }}>
                    📄 Format pliku kopii zapasowej
                </h2>
                <p className="mt-1 text-sm" style={{ color: 'var(--color-text-muted)' }}>
                    Jeśli chcesz ręcznie utworzyć lub edytować plik, użyj tego formatu:
                </p>
                <pre className="mt-3 overflow-auto rounded-lg p-4 text-xs" style={{ background: '#1a1f1c', color: 'var(--color-accent-light)' }}>
                    {exampleBackup}
                </pre>
                <p className="mt-3 text-xs" style={{ color: 'var(--color-text-muted)' }}>
                    Pola <code className="neu-tag text-xs">id</code> i <code className="neu-tag text-xs">dataDodania</code> zostaną wygenerowane automatycznie przy imporcie, jeśli ich brakuje.
                </p>
            </div>
        </div>
    );
}
