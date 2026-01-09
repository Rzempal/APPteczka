'use client';

// src/app/page.tsx v2.0.0 
// Landing Page - Karton z lekami
// Design: Organic/Biomorphic with Mint Palette

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
    <div className="landing-page organic">
      {/* Animated Blob Background */}
      <div className="blob-bg" aria-hidden="true">
        <div className="blob blob-1"></div>
        <div className="blob blob-2"></div>
        <div className="blob blob-3"></div>
      </div>

      {/* Navbar */}
      <nav className="navbar">
        <div className="container nav-content">
          <div className="logo">
            <svg className="logo-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
              <polyline points="3.27 6.96 12 12.01 20.73 6.96" />
              <line x1="12" y1="22.08" x2="12" y2="12" />
            </svg>
            Karton z lekami
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

      {/* Hero Section */}
      <section className="hero">
        <div className="container hero-content">
          <div className="hero-card organic-card">
            {/* Animated Box Icon */}
            <div className="app-icon">
              <div className="hero-stage">
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
                    <g className="anim-items" id="anim-tube">
                      <g transform="translate(45, 55) rotate(45)">
                        <rect x="-8" y="25" width="16" height="8" fill="var(--item-cap)" rx="1" />
                        <path className="fill-tube" d="M-10 25 L10 25 L8 -15 L-8 -15 Z" />
                        <path className="fill-tube-dark" d="M-10 25 L0 25 L0 -15 L-8 -15 Z" />
                        <path className="fill-tube" d="M-8 -15 L8 -15 L10 -20 L-10 -20 Z" />
                      </g>
                    </g>
                    <g className="anim-items" id="anim-box">
                      <g transform="translate(155, 65) rotate(-25)">
                        <path className="fill-box-side" d="M-12 -18 L-20 -24 L-20 12 L-12 18 Z" />
                        <path className="fill-box" d="M-12 -18 L12 -18 L12 18 L-12 18 Z" />
                        <path fill="#ffffff" d="M-12 -18 L12 -18 L4 -24 L-20 -24 Z" />
                        <rect x="-6" y="-6" width="12" height="12" fill="var(--color-accent)" rx="1" opacity="0.9" />
                      </g>
                    </g>
                    <g className="anim-items" id="anim-blister">
                      <g transform="translate(75, 15) rotate(-20)">
                        <rect x="-18" y="-24" width="36" height="48" rx="4" className="fill-blister" />
                        <rect x="-16" y="-22" width="32" height="44" fill="none" stroke="rgba(255,255,255,0.4)" strokeWidth="1" rx="3" />
                        <g fill="var(--item-blister-pill)">
                          <circle cx="-9" cy="-12" r="5" /><circle cx="-9" cy="0" r="5" /><circle cx="-9" cy="12" r="5" />
                          <circle cx="9" cy="-12" r="5" /><circle cx="9" cy="0" r="5" /><circle cx="9" cy="12" r="5" />
                        </g>
                      </g>
                    </g>
                    <path d="M12 68 L98 108 L98 186 L12 146 Z" className="fill-left" />
                    <path d="M188 68 L188 146 L102 186 L102 108 Z" className="fill-right" />
                    <g className="anim-lid">
                      <path d="M100 24 L186 64 L100 104 L14 64 Z" className="fill-top" />
                      <path className="fill-tape-light" d="M 35 73.8 L 65 87.7 L 151 47.7 L 121 33.8 Z" />
                      <path className="fill-tape-dark" d="M 35 73.8 L 65 87.7 L 65 92.7 L 35 78.7 Z" />
                      <path className="fill-tape-dark" d="M 35 78.7 L 65 92.7 L 65 140 L 35 125 Z" />
                      <g transform="translate(145, 127) skewY(-25)">
                        <rect x="-25" y="-8" width="50" height="16" className="fill-tape-light" rx="1" />
                        <rect x="-8" y="-25" width="16" height="50" className="fill-tape-light" rx="1" />
                      </g>
                    </g>
                  </g>
                </svg>
              </div>
            </div>

            <h1 className="hero-title">Karton z lekami</h1>
            <p className="hero-subtitle">
              Nie kop w pudle. Sprawdź w telefonie.
            </p>

            <div className="buttons-container">
              <a
                href={versionData.apkUrl?.replace('http://', 'https://') || 'https://michalrapala.app/releases/'}
                className="btn btn-primary"
                target="_blank"
                rel="noopener noreferrer"
              >
                <svg className="icon android-icon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path d="M18.4395 5.5586c-.675 1.1664-1.352 2.3318-2.0274 3.498-.0366-.0155-.0742-.0286-.1113-.043-1.8249-.6957-3.484-.8-4.42-.787-1.8551.0185-3.3544.4643-4.2597.8203-.084-.1494-1.7526-3.021-2.0215-3.4864a1.1451 1.1451 0 0 0-.1406-.1914c-.3312-.364-.9054-.4859-1.379-.203-.475.282-.7136.9361-.3886 1.5019 1.9466 3.3696-.0966-.2158 1.9473 3.3593.0172.031-.4946.2642-1.3926 1.0177C2.8987 12.176.452 14.772 0 18.9902h24c-.119-1.1108-.3686-2.099-.7461-3.0683-.7438-1.9118-1.8435-3.2928-2.7402-4.1836a12.1048 12.1048 0 0 0-2.1309-1.6875c.6594-1.122 1.312-2.2559 1.9649-3.3848.2077-.3615.1886-.7956-.0079-1.1191a1.1001 1.1001 0 0 0-.8515-.5332c-.5225-.0536-.9392.3128-1.0488.5449zm-.0391 8.461c.3944.5926.324 1.3306-.1563 1.6503-.4799.3197-1.188.0985-1.582-.4941-.3944-.5927-.324-1.3307.1563-1.6504.4727-.315 1.1812-.1086 1.582.4941zM7.207 13.5273c.4803.3197.5506 1.0577.1563 1.6504-.394.5926-1.1038.8138-1.584.4941-.48-.3197-.5503-1.0577-.1563-1.6504.4008-.6021 1.1087-.8106 1.584-.4941z" fill="currentColor" />
                </svg>
                <span>
                  {isLoading ? 'Ładuję...' :
                    versionData.version ? `Zainstaluj na telefonie (v${versionData.version})` :
                      'Zainstaluj na telefonie'}
                </span>
              </a>

              <div className="btn btn-secondary btn-disabled">
                <svg className="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M3 3l18 9-18 9V3z" />
                </svg>
                <span>Wkrótce w Google Play</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="features">
        <div className="container">
          <div className="features-card organic-card">
            <h2 className="features-title">Funkcje aplikacji</h2>
            <div className="features-grid">
              <div className="feature-item">
                <svg className="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" />
                  <circle cx="12" cy="13" r="4" />
                </svg>
                <span className="feature-text">Dodaj lek ze zdjęcia (AI Vision)</span>
              </div>
              <div className="feature-item">
                <svg className="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z" />
                </svg>
                <span className="feature-text">Import leków z pliku</span>
              </div>
              <div className="feature-item">
                <svg className="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <circle cx="11" cy="11" r="8" />
                  <line x1="21" y1="21" x2="16.65" y2="16.65" />
                </svg>
                <span className="feature-text">Wygodne filtrowanie i wyszukiwanie</span>
              </div>
              <div className="feature-item">
                <svg className="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <circle cx="12" cy="12" r="10" />
                  <polyline points="12 6 12 12 16 14" />
                </svg>
                <span className="feature-text">Alerty terminów ważności</span>
              </div>
              <div className="feature-item">
                <svg className="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                  <polyline points="14 2 14 8 20 8" />
                  <line x1="16" y1="13" x2="8" y2="13" />
                  <line x1="16" y1="17" x2="8" y2="17" />
                </svg>
                <span className="feature-text">Eksport do PDF</span>
              </div>
              <div className="feature-item">
                <svg className="feature-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                  <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                </svg>
                <span className="feature-text">100% prywatność – dane na urządzeniu</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Screenshots Section */}
      <section className="screenshots">
        <div className="container">
          <h2 className="section-title">Zrzuty ekranu</h2>
          <div className="screenshots-grid">
            <div className="screenshot-item organic-card">
              <img
                src="/screenshoots/screenshot_karton_z_lekami_apteczka.jpg"
                alt="Ekran główny - lista leków"
                loading="lazy"
              />
            </div>
            <div className="screenshot-item organic-card">
              <img
                src="/screenshoots/screenshot_karton_z_lekami_dodaj_leki.jpg"
                alt="Dodawanie leków"
                loading="lazy"
              />
            </div>
            <div className="screenshot-item organic-card">
              <img
                src="/screenshoots/screenshot_karton_z_lekami_lek.jpg"
                alt="Szczegóły leku"
                loading="lazy"
              />
            </div>
          </div>
        </div>
      </section>

      {/* Disclaimer Section */}
      <section className="disclaimer">
        <div className="container">
          <div className="disclaimer-card">
            <div className="disclaimer-title">
              <svg className="disclaimer-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
                <line x1="12" y1="9" x2="12" y2="13" />
                <line x1="12" y1="17" x2="12.01" y2="17" />
              </svg>
              Ważna informacja
            </div>
            <p className="disclaimer-text">
              Karton z lekami to narzędzie informacyjne (wyszukiwarka w ulotkach), NIE porada medyczna.
              Aplikacja NIE weryfikuje interakcji międzylekowych. W przypadku wątpliwości zawsze skonsultuj się z
              lekarzem lub farmaceutą.
            </p>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="footer">
        <div className="container footer-content">
          <p className="footer-brand">Karton z lekami</p>
          <nav className="footer-nav">
            <Link href="/privacy">Polityka Prywatności</Link>
            <a href="mailto:michal.rapala@resztatokod.pl">Kontakt</a>
          </nav>
          <p className="footer-copyright">
            © 2026 ResztaToKod. Wszystkie prawa zastrzeżone.
          </p>
        </div>
      </footer>
    </div>
  );
}
