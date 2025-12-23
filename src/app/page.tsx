'use client';

// src/app/page.tsx
// Strona główna – lista leków z filtrami

import { useState, useEffect } from 'react';
import type { Medicine, FilterState } from '@/lib/types';
import { getMedicines, deleteMedicine, updateMedicine, exportMedicines } from '@/lib/storage';
import MedicineList from '@/components/MedicineList';
import Filters from '@/components/Filters';

export default function HomePage() {
  const [medicines, setMedicines] = useState<Medicine[]>([]);
  const [filters, setFilters] = useState<FilterState>({
    tags: [],
    search: '',
    expiry: 'all'
  });
  const [isLoaded, setIsLoaded] = useState(false);

  // Załaduj leki z localStorage przy starcie
  useEffect(() => {
    setMedicines(getMedicines());
    setIsLoaded(true);
  }, []);

  const handleDelete = (id: string) => {
    if (confirm('Czy na pewno chcesz usunąć ten lek z apteczki?')) {
      deleteMedicine(id);
      setMedicines(getMedicines());
    }
  };

  const handleUpdateExpiry = (id: string, date: string | undefined) => {
    updateMedicine(id, { terminWaznosci: date });
    setMedicines(getMedicines());
  };

  const handleExport = () => {
    const json = exportMedicines();
    const dataUrl = 'data:application/json;charset=utf-8,' + encodeURIComponent(json);
    const link = document.createElement('a');
    link.setAttribute('href', dataUrl);
    link.setAttribute('download', `apteczka_${new Date().toISOString().split('T')[0]}.json`);
    link.style.display = 'none';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const [copyStatus, setCopyStatus] = useState<'idle' | 'copied'>('idle');

  const handleCopyJson = async () => {
    const json = exportMedicines();
    try {
      await navigator.clipboard.writeText(json);
      setCopyStatus('copied');
      setTimeout(() => setCopyStatus('idle'), 2000);
    } catch {
      alert('Nie udało się skopiować. Spróbuj ponownie.');
    }
  };

  // Skeleton podczas ładowania
  if (!isLoaded) {
    return (
      <div className="animate-pulse space-y-4">
        <div className="h-10 w-48 rounded bg-gray-200 dark:bg-gray-700" />
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3].map(i => (
            <div key={i} className="h-64 rounded-xl bg-gray-200 dark:bg-gray-700" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Nagłówek strony */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Twoja apteczka
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            {medicines.length === 0
              ? 'Brak leków – zaimportuj swoją apteczkę'
              : `${medicines.length} leków w apteczce`
            }
          </p>
        </div>

        {/* Przyciski eksportu */}
        {medicines.length > 0 && (
          <div className="flex gap-2">
            <button
              onClick={handleExport}
              className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
              title="Pobierz plik JSON"
            >
              <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
              </svg>
              Pobierz
            </button>
            <button
              onClick={handleCopyJson}
              className={`flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium transition-colors ${copyStatus === 'copied'
                  ? 'bg-green-600 text-white'
                  : 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700'
                }`}
              title="Kopiuj JSON do schowka"
            >
              <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
              </svg>
              {copyStatus === 'copied' ? '✓ Skopiowano!' : 'Kopiuj JSON'}
            </button>
          </div>
        )}
      </div>

      {/* Główna zawartość */}
      <div className="grid gap-6 lg:grid-cols-[300px_1fr]">
        {/* Sidebar z filtrami */}
        {medicines.length > 0 && (
          <aside className="lg:sticky lg:top-20 lg:h-fit">
            <Filters filters={filters} onFiltersChange={setFilters} />
          </aside>
        )}

        {/* Lista leków */}
        <section className={medicines.length === 0 ? 'lg:col-span-2' : ''}>
          <MedicineList
            medicines={medicines}
            filters={filters}
            onDelete={handleDelete}
            onUpdateExpiry={handleUpdateExpiry}
          />
        </section>
      </div>
    </div>
  );
}
