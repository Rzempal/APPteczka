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
          <nav className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3 sm:px-6">
            <Link href="/" className="flex items-center gap-2">
              <span className="text-2xl">💊</span>
              <span className="text-xl font-bold text-gray-900 dark:text-white">APPteczka</span>
            </Link>

            <div className="flex items-center gap-4">
              <Link
                href="/"
                className="text-sm font-medium text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white"
              >
                Apteczka
              </Link>
              <Link
                href="/import"
                className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
              >
                + Import
              </Link>
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
