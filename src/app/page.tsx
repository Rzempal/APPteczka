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
    labels: [],
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

  const handleUpdateLabels = (id: string, labelIds: string[]) => {
    updateMedicine(id, { labels: labelIds });
    setMedicines(getMedicines());
  };

  const handleUpdateNote = (id: string, note: string | undefined) => {
    updateMedicine(id, { notatka: note });
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

    // Tytuł - czarno-biały
    doc.setFontSize(14);
    doc.setTextColor(0); // Czarny
    doc.text('Moja Apteczka', 14, 14);
    doc.setFontSize(8);
    doc.setTextColor(80); // Ciemnoszary
    doc.text(`${new Date().toLocaleDateString('pl-PL')}`, 60, 14);

    // Tabelka czarno-biała z kolumną Notatka
    const tableData = sortedMedicines.map(m => [
      removeDiacritics(m.nazwa || 'Nieznany'),
      removeDiacritics(m.wskazania.slice(0, 2).join(', ') || '-'),
      m.terminWaznosci ? new Date(m.terminWaznosci).toLocaleDateString('pl-PL') : '-',
      removeDiacritics(m.notatka || '-')
    ]);

    autoTable(doc, {
      startY: 20,
      head: [['Nazwa', 'Wskazania', 'Termin', 'Notatka']],
      body: tableData,
      styles: {
        fontSize: 7,
        cellPadding: 1.5,
        lineColor: [0, 0, 0], // Czarna linia
        lineWidth: 0.2,
        textColor: [0, 0, 0], // Czarny tekst
      },
      headStyles: {
        fillColor: [255, 255, 255], // Białe tło nagłówka
        textColor: [0, 0, 0], // Czarny tekst
        fontStyle: 'bold',
        cellPadding: 2,
        lineColor: [0, 0, 0],
        lineWidth: 0.3,
      },
      columnStyles: {
        0: { cellWidth: 35 },
        1: { cellWidth: 50 },
        2: { cellWidth: 20, halign: 'center' },
        3: { cellWidth: 'auto' },
      },
      margin: { left: 14, right: 14, top: 10 },
      alternateRowStyles: {
        fillColor: [255, 255, 255], // Białe - brak kolorów
      },
    });

    // Disclaimer - czarno-biały
    const finalY = (doc as typeof doc & { lastAutoTable?: { finalY: number } }).lastAutoTable?.finalY || 100;
    doc.setFontSize(6);
    doc.setTextColor(80);
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
      {/* Główna zawartość */}
      <div className="grid gap-6 lg:grid-cols-[300px_1fr]">
        {/* Sidebar z filtrami */}
        {medicines.length > 0 && (
          <aside className="lg:sticky lg:top-28 lg:h-fit">
            <Filters
              filters={filters}
              onFiltersChange={setFilters}
              onExportPDF={handleExportPDF}
            />
          </aside>
        )}

        {/* Lista leków */}
        <section className={medicines.length === 0 ? 'lg:col-span-2' : ''}>
          <MedicineList
            medicines={sortedMedicines}
            filters={filters}
            onDelete={handleDelete}
            onUpdateExpiry={handleUpdateExpiry}
            onUpdateLabels={handleUpdateLabels}
            onUpdateNote={handleUpdateNote}
            totalCount={medicines.length}
            sortBy={sortBy}
            sortDir={sortDir}
            onSortChange={handleSortChange}
          />
        </section>
      </div>
    </div>
  );
}
