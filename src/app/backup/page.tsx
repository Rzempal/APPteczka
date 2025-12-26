'use client';

// src/app/backup/page.tsx
// Strona kopii zapasowej – eksport i instrukcje
// Neumorphism Style

import { useState, useEffect } from 'react';
import { getMedicines, exportMedicines } from '@/lib/storage';
import Link from 'next/link';
import Image from 'next/image';
import { SvgIcon } from '@/components/SvgIcon';

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
            {/* Nagłówek + Status - połączony kontener */}
            <div className="neu-flat p-6 animate-fadeInUp" style={{
                animationDelay: '0.1s',
                background: 'linear-gradient(145deg, var(--color-bg-light), var(--color-bg-dark))'
            }}>
                <div className="flex items-center gap-4 flex-wrap">
                    {/* Tytuł + Opis */}
                    <div>
                        <h1 className="text-xl font-bold" style={{ color: 'var(--color-text)' }}>
                            Kopia zapasowa
                        </h1>
                        <p className="text-sm" style={{ color: 'var(--color-text-muted)' }}>
                            Pobierz lub skopiuj dane apteczki
                        </p>
                    </div>

                    {/* Ikony */}
                    <div className="flex items-center gap-2">
                        <div className="neu-convex flex h-12 w-12 items-center justify-center" style={{ borderRadius: '50%' }}>
                            <Image
                                src="/icons/backup.png"
                                alt="Pudełko otwarte"
                                width={28}
                                height={28}
                            />
                        </div>
                        <span style={{ color: 'var(--color-text-muted)' }}>→</span>
                        <div className="neu-convex flex h-12 w-12 items-center justify-center" style={{ borderRadius: '50%' }}>
                            <Image
                                src="/icons/backup_closed.png"
                                alt="Pudełko zamknięte"
                                width={28}
                                height={28}
                            />
                        </div>
                    </div>

                    {/* Licznik */}
                    <div className="flex items-baseline gap-2">
                        <span className="text-sm" style={{ color: 'var(--color-text-muted)' }}>Liczba leków w pudełku:</span>
                        <span className="text-2xl font-bold" style={{ color: 'var(--color-accent)' }}>{medicineCount}</span>
                    </div>
                </div>
            </div>

            {medicineCount === 0 ? (
                <div className="neu-flat p-8 text-center animate-fadeInUp" style={{
                    animationDelay: '0.2s',
                    background: 'linear-gradient(145deg, #fef3c7, #fde68a)'
                }}>
                    <div className="neu-convex w-20 h-20 mx-auto mb-4 flex items-center justify-center animate-popIn">
                        <SvgIcon name="package" size={40} style={{ color: 'var(--color-warning)' }} />
                    </div>
                    <p className="text-lg font-medium" style={{ color: '#92400e' }}>
                        Apteczka jest pusta
                    </p>
                    <p className="mt-2 text-sm" style={{ color: '#78350f' }}>
                        Nie ma czego eksportować. Najpierw dodaj leki.
                    </p>
                    <Link
                        href="/dodaj"
                        className="mt-6 inline-flex items-center gap-1.5 neu-btn neu-btn-primary"
                    >
                        <SvgIcon name="plus" size={16} style={{ color: '#8b5cf6' }} /> Dodaj leki →
                    </Link>
                </div>
            ) : (
                <>
                    {/* Eksport */}
                    <div className="neu-flat p-6 animate-fadeInUp" style={{ animationDelay: '0.2s' }}>
                        <h2 className="font-semibold flex items-center gap-1.5" style={{ color: 'var(--color-text)' }}>
                            <SvgIcon name="folder-output" size={18} /> Eksportuj dane
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
                                {downloadStatus === 'success' && <><SvgIcon name="check-circle" size={14} /> Pobrano!</>}
                                {downloadStatus === 'error' && <><SvgIcon name="x-circle" size={14} /> Błąd pobierania</>}
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
                                {copyStatus === 'copied' ? <><SvgIcon name="check-circle" size={14} /> Skopiowano!</> : 'Kopiuj JSON'}
                            </button>
                        </div>
                    </div>

                    {/* Gdy pobieranie nie działa */}
                    <div className="warning-card neu-flat p-5 animate-fadeInUp" style={{
                        animationDelay: '0.3s'
                    }}>
                        <h3 className="warning-card-title font-semibold flex items-center gap-1.5">
                            <SvgIcon name="alert-triangle" size={18} /> Pobieranie nie działa?
                        </h3>
                        <p className="warning-card-text mt-2 text-sm">
                            Niektóre przeglądarki zarządzane przez organizację blokują pobieranie plików.
                            W takim przypadku:
                        </p>
                        <ol className="warning-card-text mt-3 list-inside list-decimal space-y-1 text-sm">
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
                <h2 className="font-semibold flex items-center gap-1.5" style={{ color: 'var(--color-text)' }}>
                    <SvgIcon name="folder-input" size={18} /> Przywracanie kopii zapasowej
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
                <h2 className="font-semibold flex items-center gap-1.5" style={{ color: 'var(--color-text)' }}>
                    <SvgIcon name="file-text" size={18} /> Format pliku kopii zapasowej
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
