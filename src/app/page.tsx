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
    // Dynamiczny import dla client-side only
    const { jsPDF } = await import('jspdf');
    const autoTable = (await import('jspdf-autotable')).default;

    // Pobierz font Roboto z CDN (obsługuje polskie znaki)
    const fontUrl = 'https://fonts.gstatic.com/s/roboto/v30/KFOmCnqEu92Fr1Me5Q.ttf';

    let doc: InstanceType<typeof jsPDF>;

    try {
      // Próbuj załadować font Roboto dla polskich znaków
      const response = await fetch(fontUrl);
      const fontBuffer = await response.arrayBuffer();
      const fontBase64 = btoa(String.fromCharCode(...new Uint8Array(fontBuffer)));

      doc = new jsPDF();
      doc.addFileToVFS('Roboto-Regular.ttf', fontBase64);
      doc.addFont('Roboto-Regular.ttf', 'Roboto', 'normal');
      doc.setFont('Roboto');
    } catch {
      // Fallback do domyślnego fonta (bez polskich znaków)
      doc = new jsPDF();
    }

    // Tytuł
    doc.setFontSize(18);
    doc.text('Moja Apteczka', 14, 20);

    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Wygenerowano: ${new Date().toLocaleDateString('pl-PL')}`, 14, 28);

    // Tabelka: Nazwa, Opis, Wskazania, Termin ważności
    const tableData = sortedMedicines.map(m => [
      m.nazwa || 'Nieznany',
      m.opis.length > 60 ? m.opis.substring(0, 57) + '...' : m.opis,
      m.wskazania.slice(0, 3).join(', '),
      m.terminWaznosci
        ? new Date(m.terminWaznosci).toLocaleDateString('pl-PL')
        : 'Brak'
    ]);

    autoTable(doc, {
      startY: 35,
      head: [['Nazwa', 'Opis', 'Wskazania', 'Termin ważności']],
      body: tableData,
      styles: {
        fontSize: 8,
        font: 'Roboto',
        cellPadding: 3,
      },
      headStyles: {
        fillColor: [16, 185, 129],
        font: 'Roboto',
        fontStyle: 'bold',
      },
      columnStyles: {
        0: { cellWidth: 35 },  // Nazwa
        1: { cellWidth: 55 },  // Opis
        2: { cellWidth: 50 },  // Wskazania
        3: { cellWidth: 25 },  // Termin
      },
      alternateRowStyles: {
        fillColor: [245, 245, 245],
      },
    });

    // Disclaimer
    const finalY = (doc as typeof doc & { lastAutoTable?: { finalY: number } }).lastAutoTable?.finalY || 100;
    doc.setFontSize(8);
    doc.setTextColor(150);
    doc.text('APPteczka - narzedzie informacyjne, nie porada medyczna.', 14, finalY + 10);

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
