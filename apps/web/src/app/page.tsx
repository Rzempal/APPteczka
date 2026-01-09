'use client';

// src/app/page.tsx v3.0.0
// Clean Mint Professional Redesign

import { useState, useEffect } from 'react';
import Link from 'next/link';

interface VersionData {
  version?: string;
  apkUrl?: string;
}

export default function LandingPage() {
  const [theme, setTheme] = useState<'light' | 'dark'>('light');
  const [versionData, setVersionData] = useState<VersionData>({});
  const [isLoading, setIsLoading] = useState(true);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const savedTheme = localStorage.getItem('theme') as 'light' | 'dark' | null;
    if (savedTheme) {
      setTheme(savedTheme);
    }
    // Default to light mode if no preference saved
  }, []);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }, [theme]);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

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
    <div className="landing-page min-h-screen flex flex-col">

      {/* Navbar */}
      <nav className={`navbar ${scrolled ? 'navbar-scrolled' : ''}`}>
        <div className="nav-container">
          <div className="logo">
            <svg className="logo-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
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
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
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
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
              </svg>
            )}
          </button>
        </div>
      </nav>

      <main className="main-content">

        {/* Hero Section */}
        <section className="hero">
          <div className="hero-container">
            <div className="hero-content">
              <h1 className="hero-title">
                Twoja domowa<br />
                <span className="text-accent">apteczka z AI</span>
              </h1>
              <p className="hero-description">
                Nie kop w pudle. Sprawdź w telefonie. Skanuj leki aparatem,
                śledź daty ważności i miej wszystko pod kontrolą.
              </p>

              <div className="hero-cta">
                <a
                  href={versionData.apkUrl?.replace('http://', 'https://') || 'https://michalrapala.app/releases/'}
                  className="btn btn-primary"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <svg viewBox="0 0 24 24" fill="currentColor">
                    <path d="M17.523 15.34c-.004-.013-.02-.022-.039-.022-.019 0-.035.009-.039.022-.242.932-.958 1.728-1.788 2.143l.252.441c.983-.48 1.804-1.441 2.078-2.562l-.464-.022zM3.738 10.5c0-.552.448-1 1-1V8.5c-1.105 0-2 .895-2 2h1zm1 0v7h-2v-7h2zm0 7c0 .552-.552 1-1 1v1c1.105 0 2-.895 2-1h-1zm14-7c0-1.105.895-2 2-2v1c-.552 0-1 .448-1 1h-1zm2-2v9h-1v-9h1zm0 9c0 1.105-.895 2-2 2v-1c.448 0 1-.448 1-1h1zM.375 2.125l2.458 4.264.867-.5L1.242 1.625l-.867.5zm16.125-.5l-2.6 4.508.867.5 2.6-4.508-.867-.5zM5.238 7.5h11.5v-1h-11.5v1zm0 0c-.552 0-1 .448-1 1h-1c0-1.657.895-3 2-3v2zm11.5 0v-2c1.105 0 2 1.343 2 3h-1c0-.552-.448-1-1-1zm0 12h-11.5v1h11.5v-1zm-11.5 0c-.552 0-1-.448-1-1h-1c0 1.657.895 3 2 3v-2zm11.5 0v2c1.105 0 2-1.343 2-3h-1c0 .552-.448 1-1 1zM7.738 12h2v-1h-2v1zm5 0h2v-1h-2v1z"/>
                  </svg>
                  <span>{isLoading ? 'Ładowanie...' : 'Pobierz APK'}</span>
                </a>
                <span className="hero-soon">Google Play wkrótce</span>
              </div>
            </div>

            <div className="hero-mockup">
              <div className="phone-frame">
                <div className="phone-notch"></div>
                <img
                  src="/screenshoots/screenshot_karton_z_lekami_apteczka.jpg"
                  alt="Aplikacja Karton z lekami"
                  className="phone-screen"
                />
              </div>
            </div>
          </div>
        </section>

        {/* Features Section */}
        <section className="features">
          <div className="section-container">
            <div className="section-header">
              <h2 className="section-title">Funkcje, które docenisz</h2>
              <p className="section-subtitle">
                Zaprojektowane, by oszczędzać Twój czas i dbać o bezpieczeństwo rodziny.
              </p>
            </div>

            <div className="features-grid">
              <div className="feature-card">
                <svg className="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                  <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" />
                  <circle cx="12" cy="13" r="4" />
                </svg>
                <h3 className="feature-title">AI Vision</h3>
                <p className="feature-text">
                  Zrób zdjęcie opakowania. Sztuczna inteligencja odczyta nazwę leku i datę ważności automatycznie.
                </p>
              </div>

              <div className="feature-card">
                <svg className="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                  <circle cx="12" cy="12" r="10" />
                  <polyline points="12 6 12 12 16 14" />
                </svg>
                <h3 className="feature-title">Alerty ważności</h3>
                <p className="feature-text">
                  Otrzymuj powiadomienia zanim lek straci ważność. Nigdy więcej przeterminowanych leków w apteczce.
                </p>
              </div>

              <div className="feature-card">
                <svg className="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                  <circle cx="11" cy="11" r="8" />
                  <line x1="21" y1="21" x2="16.65" y2="16.65" />
                </svg>
                <h3 className="feature-title">Szybkie szukanie</h3>
                <p className="feature-text">
                  Filtruj po nazwie, dacie ważności lub tagach. Znajdź potrzebny lek w sekundę.
                </p>
              </div>

              <div className="feature-card">
                <svg className="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                  <polyline points="14 2 14 8 20 8" />
                  <line x1="16" y1="13" x2="8" y2="13" />
                  <line x1="16" y1="17" x2="8" y2="17" />
                </svg>
                <h3 className="feature-title">Raporty PDF</h3>
                <p className="feature-text">
                  Generuj czytelne raporty z zawartością apteczki. Udostępnij lekarzowi lub domownikom.
                </p>
              </div>

              <div className="feature-card">
                <svg className="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                  <polyline points="17 8 12 3 7 8" />
                  <line x1="12" y1="3" x2="12" y2="15" />
                </svg>
                <h3 className="feature-title">Eksport i import</h3>
                <p className="feature-text">
                  Przenoś dane między urządzeniami. Twoja apteczka zawsze pod ręką, niezależnie od telefonu.
                </p>
              </div>

              <div className="feature-card">
                <svg className="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                  <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                </svg>
                <h3 className="feature-title">Prywatność</h3>
                <p className="feature-text">
                  Działamy offline-first. Twoje dane medyczne zostają na Twoim urządzeniu. Zero chmury.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Screenshots Section */}
        <section className="screenshots">
          <div className="section-container">
            <div className="section-header">
              <h2 className="section-title">Przejrzysty interfejs</h2>
              <p className="section-subtitle">
                Intuicyjny design, który nie wymaga instrukcji.
              </p>
            </div>

            <div className="screenshots-grid">
              <div className="screenshot-card">
                <img
                  src="/screenshoots/screenshot_karton_z_lekami_apteczka.jpg"
                  alt="Lista leków w apteczce"
                  loading="lazy"
                />
                <p className="screenshot-caption">Lista leków</p>
              </div>
              <div className="screenshot-card">
                <img
                  src="/screenshoots/screenshot_karton_z_lekami_dodaj_leki.jpg"
                  alt="Dodawanie nowego leku"
                  loading="lazy"
                />
                <p className="screenshot-caption">Dodawanie leku</p>
              </div>
              <div className="screenshot-card">
                <img
                  src="/screenshoots/screenshot_karton_z_lekami_lek.jpg"
                  alt="Szczegóły leku"
                  loading="lazy"
                />
                <p className="screenshot-caption">Szczegóły leku</p>
              </div>
            </div>
          </div>
        </section>

        {/* Disclaimer */}
        <section className="disclaimer">
          <div className="section-container">
            <div className="disclaimer-card">
              <svg className="disclaimer-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="12" cy="12" r="10" />
                <line x1="12" y1="8" x2="12" y2="12" />
                <line x1="12" y1="16" x2="12.01" y2="16" />
              </svg>
              <div className="disclaimer-content">
                <h4 className="disclaimer-title">Ważna informacja</h4>
                <p className="disclaimer-text">
                  Karton z lekami to narzędzie pomocnicze. Nie zastępuje porady lekarskiej ani farmaceutycznej.
                  Zawsze sprawdzaj ulotki i konsultuj się ze specjalistą.
                </p>
              </div>
            </div>
          </div>
        </section>

      </main>

      {/* Footer */}
      <footer className="footer">
        <div className="footer-container">
          <p className="footer-brand">Karton z lekami</p>
          <nav className="footer-nav">
            <Link href="/privacy">Polityka Prywatności</Link>
            <a href="mailto:michal.rapala@resztatokod.pl">Kontakt</a>
          </nav>
          <p className="footer-copyright">© 2026 ResztaToKod</p>
        </div>
      </footer>
    </div>
  );
}
