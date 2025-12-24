'use client';

// src/app/page.tsx
// Strona główna – lista leków z filtrami, sortowaniem i eksportem PDF
// Neumorphism Style

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
    const { jsPDF } = await import('jspdf');
    const autoTable = (await import('jspdf-autotable')).default;

    const doc = new jsPDF();

    // Funkcja do zamiany polskich znaków
    const removeDiacritics = (text: string): string => {
      const map: Record<string, string> = {
        'ą': 'a', 'ć': 'c', 'ę': 'e', 'ł': 'l', 'ń': 'n',
        'ó': 'o', 'ś': 's', 'ź': 'z', 'ż': 'z',
        'Ą': 'A', 'Ć': 'C', 'Ę': 'E', 'Ł': 'L', 'Ń': 'N',
        'Ó': 'O', 'Ś': 'S', 'Ź': 'Z', 'Ż': 'Z'
      };
      return text.replace(/[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]/g, char => map[char] || char);
    };

    // Tytuł - kompaktowy
    doc.setFontSize(14);
    doc.setTextColor(16, 185, 129);
    doc.text('Moja Apteczka', 14, 14);
    doc.setFontSize(8);
    doc.setTextColor(120);
    doc.text(`${new Date().toLocaleDateString('pl-PL')}`, 60, 14);

    // Tabelka kompaktowa
    const tableData = sortedMedicines.map(m => [
      removeDiacritics(m.nazwa || 'Nieznany'),
      removeDiacritics(m.wskazania.slice(0, 2).join(', ') || '-'),
      m.terminWaznosci ? new Date(m.terminWaznosci).toLocaleDateString('pl-PL') : '-'
    ]);

    autoTable(doc, {
      startY: 20,
      head: [['Nazwa', 'Wskazania', 'Termin']],
      body: tableData,
      styles: {
        fontSize: 7,
        cellPadding: 1.5,
        lineColor: [220, 220, 220],
        lineWidth: 0.1,
      },
      headStyles: {
        fillColor: [16, 185, 129],
        textColor: 255,
        fontStyle: 'bold',
        cellPadding: 2,
      },
      columnStyles: {
        0: { cellWidth: 45 },
        1: { cellWidth: 'auto' },
        2: { cellWidth: 22, halign: 'center' },
      },
      margin: { left: 14, right: 14, top: 10 },
    });

    // Disclaimer - kompaktowy
    const finalY = (doc as typeof doc & { lastAutoTable?: { finalY: number } }).lastAutoTable?.finalY || 100;
    doc.setFontSize(6);
    doc.setTextColor(160);
    doc.text('APPteczka - narzedzie informacyjne, nie porada medyczna.', 14, finalY + 5);

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
      <div className="space-y-6">
        <div className="neu-skeleton h-12 w-48" />
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3].map(i => (
            <div key={i} className="neu-skeleton h-64" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Nagłówek strony */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between animate-fadeInUp">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: 'var(--color-text)' }}>
            💊 Twoja apteczka
          </h1>
          <p className="text-sm" style={{ color: 'var(--color-text-muted)' }}>
            {medicines.length === 0
              ? 'Brak leków – dodaj leki w zakładce "Dodaj leki"'
              : `${medicines.length} leków w apteczce`
            }
          </p>
        </div>

        {/* Akcje */}
        {medicines.length > 0 && (
          <div className="flex flex-wrap gap-3 animate-fadeInUp" style={{ animationDelay: '0.2s' }}>
            {/* Sortowanie */}
            <div className="neu-flat-sm flex items-center gap-1 px-3 py-2">
              <span className="text-xs" style={{ color: 'var(--color-text-muted)' }}>Sortuj:</span>
              {[
                { key: 'nazwa', label: 'Nazwa' },
                { key: 'dataDodania', label: 'Data' },
                { key: 'terminWaznosci', label: 'Termin' },
              ].map((opt) => (
                <button
                  key={opt.key}
                  onClick={() => handleSortChange(opt.key as SortOption)}
                  className={`neu-tag text-xs ${sortBy === opt.key ? 'active' : ''}`}
                >
                  {opt.label} {sortBy === opt.key && (sortDir === 'asc' ? '↑' : '↓')}
                </button>
              ))}
            </div>

            {/* Eksport PDF */}
            <button
              onClick={handleExportPDF}
              className="neu-btn neu-btn-secondary text-sm"
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
          <aside className="lg:sticky lg:top-28 lg:h-fit">
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
