'use client';

// src/app/page.tsx
// Strona główna – lista leków z filtrami, sortowaniem i eksportem PDF

import { useState, useEffect, useMemo } from 'react';
import type { Medicine, FilterState } from '@/lib/types';
import { getMedicines, deleteMedicine, updateMedicine } from '@/lib/storage';
import MedicineList from '@/components/MedicineList';
import Filters from '@/components/Filters';

type SortOption = 'nazwa' | 'dataDodania' | 'terminWaznosci';
type SortDirection = 'asc' | 'desc';

export default function HomePage() {
  const [medicines, setMedicines] = useState<Medicine[]>([]);
  const [filters, setFilters] = useState<FilterState>({
    tags: [],
    search: '',
    expiry: 'all'
  });
  const [isLoaded, setIsLoaded] = useState(false);
  const [sortBy, setSortBy] = useState<SortOption>('nazwa');
  const [sortDir, setSortDir] = useState<SortDirection>('asc');

  // Załaduj leki z localStorage przy starcie
  useEffect(() => {
    setMedicines(getMedicines());
    setIsLoaded(true);
  }, []);

  // Sortowanie
  const sortedMedicines = useMemo(() => {
    const sorted = [...medicines].sort((a, b) => {
      let comparison = 0;

      switch (sortBy) {
        case 'nazwa':
          const nameA = (a.nazwa || 'zzz').toLowerCase();
          const nameB = (b.nazwa || 'zzz').toLowerCase();
          comparison = nameA.localeCompare(nameB, 'pl');
          break;
        case 'dataDodania':
          comparison = new Date(a.dataDodania).getTime() - new Date(b.dataDodania).getTime();
          break;
        case 'terminWaznosci':
          const expiryA = a.terminWaznosci ? new Date(a.terminWaznosci).getTime() : Infinity;
          const expiryB = b.terminWaznosci ? new Date(b.terminWaznosci).getTime() : Infinity;
          comparison = expiryA - expiryB;
          break;
      }

      return sortDir === 'asc' ? comparison : -comparison;
    });

    return sorted;
  }, [medicines, sortBy, sortDir]);

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

  const handleExportPDF = async () => {
    // Dynamiczny import dla client-side only
    const { jsPDF } = await import('jspdf');
    const autoTable = (await import('jspdf-autotable')).default;

    const doc = new jsPDF();

    // Tytuł
    doc.setFontSize(18);
    doc.text('Moja Apteczka', 14, 20);

    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Wygenerowano: ${new Date().toLocaleDateString('pl-PL')}`, 14, 28);

    // Tabelka
    const tableData = sortedMedicines.map(m => [
      m.nazwa || 'Nieznany',
      m.terminWaznosci
        ? new Date(m.terminWaznosci).toLocaleDateString('pl-PL')
        : 'Brak',
      m.tagi.slice(0, 3).join(', ') || '-'
    ]);

    autoTable(doc, {
      startY: 35,
      head: [['Nazwa leku', 'Termin ważności', 'Tagi']],
      body: tableData,
      styles: { fontSize: 9 },
      headStyles: { fillColor: [59, 130, 246] },
    });

    // Disclaimer
    const finalY = (doc as typeof doc & { lastAutoTable?: { finalY: number } }).lastAutoTable?.finalY || 100;
    doc.setFontSize(8);
    doc.setTextColor(150);
    doc.text('APPteczka - narzędzie informacyjne, nie porada medyczna.', 14, finalY + 10);

    doc.save(`apteczka_${new Date().toISOString().split('T')[0]}.pdf`);
  };

  const handleSortChange = (option: SortOption) => {
    if (sortBy === option) {
      setSortDir(prev => prev === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(option);
      setSortDir('asc');
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
              ? 'Brak leków – dodaj leki w zakładce "Dodaj leki"'
              : `${medicines.length} leków w apteczce`
            }
          </p>
        </div>

        {/* Akcje */}
        {medicines.length > 0 && (
          <div className="flex flex-wrap gap-2">
            {/* Sortowanie */}
            <div className="flex items-center gap-1 rounded-lg border border-gray-300 bg-white px-2 py-1 dark:border-gray-600 dark:bg-gray-800">
              <span className="text-xs text-gray-500 dark:text-gray-400">Sortuj:</span>
              <button
                onClick={() => handleSortChange('nazwa')}
                className={`rounded px-2 py-1 text-xs font-medium ${sortBy === 'nazwa'
                    ? 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300'
                    : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400'
                  }`}
              >
                Nazwa {sortBy === 'nazwa' && (sortDir === 'asc' ? '↑' : '↓')}
              </button>
              <button
                onClick={() => handleSortChange('dataDodania')}
                className={`rounded px-2 py-1 text-xs font-medium ${sortBy === 'dataDodania'
                    ? 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300'
                    : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400'
                  }`}
              >
                Data {sortBy === 'dataDodania' && (sortDir === 'asc' ? '↑' : '↓')}
              </button>
              <button
                onClick={() => handleSortChange('terminWaznosci')}
                className={`rounded px-2 py-1 text-xs font-medium ${sortBy === 'terminWaznosci'
                    ? 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300'
                    : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400'
                  }`}
              >
                Termin {sortBy === 'terminWaznosci' && (sortDir === 'asc' ? '↑' : '↓')}
              </button>
            </div>

            {/* Eksport PDF */}
            <button
              onClick={handleExportPDF}
              className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300"
            >
              <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
              </svg>
              PDF
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
            medicines={sortedMedicines}
            filters={filters}
            onDelete={handleDelete}
            onUpdateExpiry={handleUpdateExpiry}
          />
        </section>
      </div>
    </div>
  );
}
