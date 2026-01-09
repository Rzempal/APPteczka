'use client';

// src/app/page.tsx v2.1.0 
// Premium Organic Refactor

import { useState, useEffect } from 'react';
import Link from 'next/link';

interface VersionData {
  version?: string;
  apkUrl?: string;
}

export default function LandingPage() {
  const [theme, setTheme] = useState<'light' | 'dark'>('dark');
  const [versionData, setVersionData] = useState<VersionData>({});
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    const savedTheme = localStorage.getItem('theme') as 'light' | 'dark' | null;
    setTheme(savedTheme || (prefersDark ? 'dark' : 'light'));
  }, []);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }, [theme]);

  useEffect(() => {
    const fetchVersion = async () => {
      try {
        const response = await fetch('https://michalrapala.app/releases/version.json?t=' + Date.now());
        if (response.ok) {
          const data = await response.json();
          setVersionData(data);
        }
      } catch (error) {
        console.warn('Could not fetch version:', error);
      } finally {
        setIsLoading(false);
      }
    };
    fetchVersion();
  }, []);

  const toggleTheme = () => {
    setTheme(prev => prev === 'dark' ? 'light' : 'dark');
  };

  return (
    <div className="landing-page organic min-h-screen flex flex-col relative text-slate-900 dark:text-slate-100 font-sans">

      {/* Background Atmosphere */}
      <div className="blob-bg" aria-hidden="true">
        <div className="blob blob-1"></div>
        <div className="blob blob-2"></div>
        <div className="blob blob-3"></div>
      </div>

      {/* Navbar - Anchored Top */}
      <nav className="navbar">
        <div className="nav-content">
          <div className="logo flex items-center gap-3 text-xl font-bold tracking-tight">
            <svg className="w-8 h-8 text-emerald-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
              <polyline points="3.27 6.96 12 12.01 20.73 6.96" />
              <line x1="12" y1="22.08" x2="12" y2="12" />
            </svg>
            <span>Karton z lekami</span>
          </div>
          <button
            className="theme-toggle"
            onClick={toggleTheme}
            aria-label="Przełącz motyw"
          >
            {theme === 'dark' ? (
              <svg className="w-5 h-5 text-slate-400 hover:text-white transition-colors" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="12" cy="12" r="5" />
                <line x1="12" y1="1" x2="12" y2="3" />
                <line x1="12" y1="21" x2="12" y2="23" />
                <line x1="4.22" y1="4.22" x2="5.64" y2="5.64" />
                <line x1="18.36" y1="18.36" x2="19.78" y2="19.78" />
                <line x1="1" y1="12" x2="3" y2="12" />
                <line x1="21" y1="12" x2="23" y2="12" />
                <line x1="4.22" y1="19.78" x2="5.64" y2="18.36" />
                <line x1="18.36" y1="5.64" x2="19.78" y2="4.22" />
              </svg>
            ) : (
              <svg className="w-5 h-5 text-slate-600 hover:text-slate-900 transition-colors" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
              </svg>
            )}
          </button>
        </div>
      </nav>

      <main className="flex-grow pt-32 pb-16">

        {/* Hero Section */}
        <section className="container mx-auto px-4 mb-24 max-w-5xl">
          <div className="hero-card organic-card p-12 md:p-16 flex flex-col md:flex-row items-center gap-12 text-center md:text-left">

            {/* Left: Content */}
            <div className="flex-1 space-y-8">
              <h1 className="hero-title text-4xl md:text-5xl lg:text-6xl font-bold leading-tight">
                Twoja domowa <br />
                <span className="text-emerald-500">apteczka z AI</span>
              </h1>
              <p className="hero-subtitle text-lg md:text-xl text-slate-600 dark:text-slate-300 max-w-md mx-auto md:mx-0 leading-relaxed">
                Nie kop w pudle. Sprawdź w telefonie. Skanuj leki, sprawdzaj daty ważności i dbaj o bezpieczeństwo.
              </p>

              <div className="flex flex-col sm:flex-row gap-4 justify-center md:justify-start">
                <a
                  href={versionData.apkUrl?.replace('http://', 'https://') || 'https://michalrapala.app/releases/'}
                  className="btn btn-primary flex items-center justify-center gap-3"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M17.523 15.3414C17.5188 15.3283 17.5023 15.3188 17.4836 15.3188C17.4646 15.3188 17.4484 15.3282 17.4445 15.3413C17.203 16.2731 16.4868 17.0694 15.6565 17.4842L15.9084 17.925C16.8911 17.4447 17.7126 16.4839 17.9868 15.3621L17.523 15.3414Z" opacity="0.4" />
                    <path d="M3.73801 10.5C3.73801 9.94772 4.18572 9.5 4.73801 9.5V8.5C3.63344 8.5 2.73801 9.39543 2.73801 10.5H3.73801ZM4.73801 10.5V17.5H2.73801V10.5H4.73801ZM4.73801 17.5C4.73801 18.0523 4.18572 18.5 3.73801 18.5V19.5C4.84257 19.5 5.73801 18.6046 5.73801 17.5H4.73801ZM18.738 10.5C18.738 9.39543 19.6334 8.5 20.738 8.5V9.5C20.1857 9.5 19.738 9.94772 19.738 10.5H18.738ZM20.738 8.5V17.5H19.738V10.5H20.738ZM20.738 17.5C20.738 18.6046 19.8426 19.5 18.738 19.5V18.5C19.1857 18.5 19.6334 18.0523 19.6334 17.5H20.738ZM0.375 2.125L2.83333 6.38889L3.7 5.88889L1.24167 1.625L0.375 2.125ZM16.5 1.625L13.9 6.13333L14.7667 6.63333L17.3667 2.125L16.5 1.625ZM5.23801 7.5H16.738V6.5H5.23801V7.5ZM5.23801 7.5C4.68572 7.5 4.23801 7.94772 4.23801 8.5H3.23801C3.23801 6.84315 4.13344 5.5 5.23801 5.5V7.5ZM16.738 7.5V5.5C17.8426 5.5 18.738 6.84315 18.738 8.5H17.738C17.738 7.94772 17.2903 7.5 16.738 7.5ZM16.738 19.5H5.23801V20.5H16.738V19.5ZM5.23801 19.5C4.68572 19.5 4.23801 19.0523 4.23801 18.5H3.23801C3.23801 20.1569 4.13344 21.5 5.23801 21.5V19.5ZM16.738 19.5V21.5C17.8426 21.5 18.738 20.1569 18.738 18.5H17.738C17.738 19.0523 17.2903 19.5 16.738 19.5ZM7.73801 12H9.73801V11H7.73801V12ZM12.738 12H14.738V11H12.738V12Z" fill="currentColor" />
                  </svg>
                  <span>{isLoading ? 'Ładowanie...' : 'Pobierz APK'}</span>
                </a>

                <div className="btn bg-slate-100 dark:bg-slate-800 text-slate-400 cursor-not-allowed flex items-center justify-center gap-3">
                  <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M3 3l18 9-18 9V3z" />
                  </svg>
                  <span>Wkrótce w Play</span>
                </div>
              </div>
            </div>

            {/* Right: Illustration */}
            <div className="flex-1 w-full max-w-sm mx-auto md:max-w-none flex justify-center">
              <div className="relative w-64 h-64 md:w-80 md:h-80">
                {/* SVG Illustration Placeholder - Keeps original animation */}
                <div className="hero-stage transform scale-125">
                  <svg viewBox="0 0 200 200">
                    <g className="anim-box-shake" transform="translate(10, 15) scale(0.9)">
                      <g className="anim-flaps">
                        <path className="fill-flap" d="M14 64 L100 34 L85 5 L5 30 Z" opacity="0.9" />
                        <path className="fill-flap" d="M186 64 L100 34 L115 5 L195 30 Z" opacity="0.9" />
                        <path className="fill-inner" d="M100 108 L186 64 L100 34 L14 64 Z" />
                      </g>
                      <g className="anim-items" id="anim-bottle">
                        <g transform="translate(100, 45) rotate(5)">
                          <rect x="-12" y="0" width="24" height="42" rx="4" className="fill-bottle" />
                          <rect x="-12" y="0" width="8" height="42" rx="4" className="fill-bottle-dark" />
                          <rect x="-14" y="-8" width="28" height="8" fill="var(--item-cap)" rx="2" />
                          <rect x="-8" y="10" width="16" height="20" fill="rgba(255,255,255,0.9)" rx="2" />
                        </g>
                      </g>
                      <g className="anim-lid">
                        <path d="M100 24 L186 64 L100 104 L14 64 Z" className="fill-top" />
                        <path className="fill-tape-light" d="M 35 73.8 L 65 87.7 L 151 47.7 L 121 33.8 Z" />
                      </g>
                    </g>
                  </svg>
                </div>
              </div>
            </div>

          </div>
        </section>

        {/* Features Section - Disiplined Grid */}
        <section className="container mx-auto px-4 mb-32 max-w-6xl">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">Funkcje, które docenisz</h2>
            <p className="text-slate-600 dark:text-slate-400 max-w-2xl mx-auto">
              Zaprojektowany, by oszczędzać Twój czas i dbać o zdrowie Twojej rodziny.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 md:gap-8">
            {/* Feature 1 */}
            <div className="feature-item organic-card">
              <div className="feature-icon">
                <svg className="w-8 h-8" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" />
                  <circle cx="12" cy="13" r="4" />
                </svg>
              </div>
              <div>
                <h3 className="text-lg font-bold mb-2">AI Vision</h3>
                <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
                  Zrób zdjęcie opakowania, a sztuczna inteligencja odczyta nazwę i datę ważności.
                </p>
              </div>
            </div>

            {/* Feature 2 */}
            <div className="feature-item organic-card">
              <div className="feature-icon">
                <svg className="w-8 h-8" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z" />
                </svg>
              </div>
              <div>
                <h3 className="text-lg font-bold mb-2">Eksport i Import</h3>
                <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
                  Łatwo przenoś dane między urządzeniami lub udostępniaj listę leków lekarzowi.
                </p>
              </div>
            </div>

            {/* Feature 3 */}
            <div className="feature-item organic-card">
              <div className="feature-icon">
                <svg className="w-8 h-8" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <circle cx="11" cy="11" r="8" />
                  <line x1="21" y1="21" x2="16.65" y2="16.65" />
                </svg>
              </div>
              <div>
                <h3 className="text-lg font-bold mb-2">Szybkie Szukanie</h3>
                <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
                  Filtruj po nazwie, dacie ważności lub tagach. Znajdź lek w sekundę.
                </p>
              </div>
            </div>

            {/* Feature 4 */}
            <div className="feature-item organic-card">
              <div className="feature-icon">
                <svg className="w-8 h-8" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <circle cx="12" cy="12" r="10" />
                  <polyline points="12 6 12 12 16 14" />
                </svg>
              </div>
              <div>
                <h3 className="text-lg font-bold mb-2">Alerty Ważności</h3>
                <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
                  Otrzymuj powiadomienia o kończących się terminach ważności leków.
                </p>
              </div>
            </div>

            {/* Feature 5 */}
            <div className="feature-item organic-card">
              <div className="feature-icon">
                <svg className="w-8 h-8" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                  <polyline points="14 2 14 8 20 8" />
                </svg>
              </div>
              <div>
                <h3 className="text-lg font-bold mb-2">Raporty PDF</h3>
                <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
                  Generuj czytelne raporty PDF z zawartością apteczki dla domowników.
                </p>
              </div>
            </div>

            {/* Feature 6 */}
            <div className="feature-item organic-card">
              <div className="feature-icon">
                <svg className="w-8 h-8" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                  <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                </svg>
              </div>
              <div>
                <h3 className="text-lg font-bold mb-2">Prywatność</h3>
                <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
                  Działamy offline-first. Twoje dane medyczne zostają na Twoim urządzeniu.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Screenshots Section */}
        <section className="container mx-auto px-4 mb-24 max-w-6xl">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">Przejrzysty interfejs</h2>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="screenshot-item organic-card">
              <img
                src="/screenshoots/screenshot_karton_z_lekami_apteczka.jpg"
                alt="Lista leków"
                className="w-full h-auto block"
                loading="lazy"
              />
            </div>
            <div className="screenshot-item organic-card mt-0 md:mt-12">
              <img
                src="/screenshoots/screenshot_karton_z_lekami_dodaj_leki.jpg"
                alt="Skanowanie leków"
                className="w-full h-auto block"
                loading="lazy"
              />
            </div>
            <div className="screenshot-item organic-card">
              <img
                src="/screenshoots/screenshot_karton_z_lekami_lek.jpg"
                alt="Szczegóły leku"
                className="w-full h-auto block"
                loading="lazy"
              />
            </div>
          </div>
        </section>

        {/* Disclaimer */}
        <section className="container mx-auto px-4 max-w-3xl">
          <div className="bg-amber-50 dark:bg-amber-900/10 border border-amber-200 dark:border-amber-900/30 rounded-2xl p-6 flex gap-4 items-start">
            <svg className="w-6 h-6 text-amber-500 flex-shrink-0 mt-1" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
              <line x1="12" y1="9" x2="12" y2="13" />
              <line x1="12" y1="17" x2="12.01" y2="17" />
            </svg>
            <div>
              <h4 className="font-bold text-amber-700 dark:text-amber-500 mb-1">Ważna informacja</h4>
              <p className="text-sm text-amber-800/80 dark:text-amber-400/80 leading-relaxed">
                Karton z lekami to narzędzie pomocnicze. Nie zastępuje porady lekarskiej ani farmaceutycznej.
                Zawsze sprawdzaj ulotki i konsultuj się ze specjalistą.
              </p>
            </div>
          </div>
        </section>

      </main>

      {/* Footer */}
      <footer className="footer py-12 border-t border-slate-200 dark:border-slate-800">
        <div className="container mx-auto px-4 flex flex-col md:flex-row justify-between items-center gap-6">
          <p className="font-bold text-lg">Karton z lekami</p>
          <div className="flex gap-8 text-sm text-slate-600 dark:text-slate-400">
            <Link href="/privacy" className="hover:text-emerald-500 transition-colors">Polityka Prywatności</Link>
            <a href="mailto:michal.rapala@resztatokod.pl" className="hover:text-emerald-500 transition-colors">Kontakt</a>
          </div>
          <p className="text-sm text-slate-500">© 2026 ResztaToKod</p>
        </div>
      </footer>
    </div>
  );
}
