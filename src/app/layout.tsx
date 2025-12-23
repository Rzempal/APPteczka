import type { Metadata } from "next";
import { DM_Sans } from "next/font/google";
import "./globals.css";
import Link from "next/link";

const dmSans = DM_Sans({
  subsets: ["latin", "latin-ext"],
  variable: "--font-dm-sans",
  weight: ["400", "500", "600", "700"],
});

export const metadata: Metadata = {
  title: "APPteczka – Zarządzaj domową apteczką",
  description: "Aplikacja do zarządzania domową apteczką z integracją AI. Kataloguj leki, śledź terminy ważności, filtruj po objawach.",
  keywords: ["apteczka", "leki", "zdrowie", "AI", "zarządzanie lekami"],
};

const navItems = [
  { href: "/", label: "Apteczka", icon: "💊" },
  { href: "/dodaj", label: "Dodaj leki", icon: "➕" },
  { href: "/konsultacja", label: "Konsultacja AI", icon: "🩺" },
  { href: "/backup", label: "Kopia zapasowa", icon: "💾" },
];

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="pl">
      <body className={`${dmSans.variable} font-sans antialiased`} style={{ background: 'var(--color-bg)', color: 'var(--color-text)' }}>
        {/* Nagłówek - Neumorphic */}
        <header className="sticky top-0 z-50">
          <nav className="mx-auto max-w-7xl px-4 py-4 sm:px-6">
            {/* Logo + Desktop navigation */}
            <div className="neu-flat p-4 flex items-center justify-between animate-fadeInUp">
              <Link href="/" className="flex items-center gap-2 group">
                <span className="text-2xl group-hover:scale-110 transition-transform">💊</span>
                <span className="text-xl font-bold" style={{ color: 'var(--color-accent)' }}>APPteczka</span>
              </Link>

              {/* Desktop navigation */}
              <div className="hidden sm:flex items-center gap-2">
                {navItems.map((item, index) => (
                  <Link
                    key={item.href}
                    href={item.href}
                    className="neu-tag stagger-1"
                    style={{ animationDelay: `${0.1 + index * 0.1}s` }}
                  >
                    <span>{item.icon}</span>
                    <span className="ml-1">{item.label}</span>
                  </Link>
                ))}
              </div>
            </div>

            {/* Mobile navigation */}
            <div className="flex sm:hidden items-center gap-2 mt-3 overflow-x-auto pb-2 -mx-4 px-4">
              {navItems.map((item, index) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="neu-tag whitespace-nowrap animate-fadeInUp"
                  style={{ animationDelay: `${0.2 + index * 0.1}s` }}
                >
                  <span>{item.icon}</span>
                  <span className="ml-1">{item.label}</span>
                </Link>
              ))}
            </div>
          </nav>
        </header>

        {/* Treść */}
        <main className="mx-auto max-w-7xl px-4 py-6 sm:px-6">
          {children}
        </main>

        {/* Stopka - Neumorphic */}
        <footer className="pb-6 pt-12">
          <div className="mx-auto max-w-7xl px-4 sm:px-6">
            {/* Disclaimer */}
            <div className="neu-flat p-6 animate-fadeInUp" style={{ animationDelay: '0.3s' }}>
              <div className="flex items-start gap-3">
                <span className="text-2xl">⚠️</span>
                <div>
                  <p className="font-semibold" style={{ color: 'var(--color-warning)' }}>
                    Ważne
                  </p>
                  <p className="text-sm mt-1" style={{ color: 'var(--color-text-muted)' }}>
                    APPteczka to narzędzie informacyjne, NIE porada medyczna.
                    Zawsze konsultuj się z lekarzem lub farmaceutą przed zastosowaniem leku.
                  </p>
                </div>
              </div>
            </div>

            {/* Copyright */}
            <p className="mt-6 text-center text-xs" style={{ color: 'var(--color-text-muted)' }}>
              APPteczka © {new Date().getFullYear()} • Dane przechowywane lokalnie w przeglądarce
            </p>
          </div>
        </footer>
      </body>
    </html>
  );
}
