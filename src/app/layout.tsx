import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import Link from "next/link";

const inter = Inter({
  subsets: ["latin", "latin-ext"],
  variable: "--font-inter",
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
      <body className={`${inter.variable} font-sans antialiased bg-gray-50 dark:bg-gray-900`}>
        {/* Nagłówek */}
        <header className="sticky top-0 z-50 border-b border-gray-200 bg-white/80 backdrop-blur-sm dark:border-gray-800 dark:bg-gray-900/80">
          <nav className="mx-auto max-w-7xl px-4 py-3 sm:px-6">
            {/* Logo + Mobile menu */}
            <div className="flex items-center justify-between">
              <Link href="/" className="flex items-center gap-2">
                <span className="text-2xl">💊</span>
                <span className="text-xl font-bold text-gray-900 dark:text-white">APPteczka</span>
              </Link>

              {/* Desktop navigation */}
              <div className="hidden sm:flex items-center gap-1">
                {navItems.map(item => (
                  <Link
                    key={item.href}
                    href={item.href}
                    className="flex items-center gap-1.5 rounded-lg px-3 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 hover:text-gray-900 dark:text-gray-400 dark:hover:bg-gray-800 dark:hover:text-white"
                  >
                    <span>{item.icon}</span>
                    <span>{item.label}</span>
                  </Link>
                ))}
              </div>
            </div>

            {/* Mobile navigation */}
            <div className="flex sm:hidden items-center gap-1 mt-3 overflow-x-auto pb-1 -mx-4 px-4">
              {navItems.map(item => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="flex items-center gap-1 whitespace-nowrap rounded-lg px-3 py-1.5 text-xs font-medium text-gray-600 bg-gray-100 hover:bg-gray-200 dark:text-gray-400 dark:bg-gray-800 dark:hover:bg-gray-700"
                >
                  <span>{item.icon}</span>
                  <span>{item.label}</span>
                </Link>
              ))}
            </div>
          </nav>
        </header>

        {/* Treść */}
        <main className="mx-auto max-w-7xl px-4 py-6 sm:px-6">
          {children}
        </main>

        {/* Stopka z disclaimerem */}
        <footer className="border-t border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900">
          <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6">
            <div className="rounded-lg bg-yellow-50 p-4 text-center dark:bg-yellow-900/20">
              <p className="text-sm text-yellow-800 dark:text-yellow-200">
                <strong>⚠️ Ważne:</strong> APPteczka to narzędzie informacyjne, NIE porada medyczna.
                Zawsze konsultuj się z lekarzem lub farmaceutą przed zastosowaniem leku.
              </p>
            </div>
            <p className="mt-4 text-center text-xs text-gray-500 dark:text-gray-400">
              APPteczka © {new Date().getFullYear()} • Dane przechowywane lokalnie w przeglądarce
            </p>
          </div>
        </footer>
      </body>
    </html>
  );
}
