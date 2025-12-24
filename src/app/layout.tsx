import type { Metadata } from "next";
import { DM_Sans } from "next/font/google";
import "./globals.css";
import { Header } from "@/components/Header";

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

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="pl">
      <body className={`${dmSans.variable} font-sans antialiased`} style={{ background: 'var(--color-bg)', color: 'var(--color-text)' }}>
        {/* Nagłówek - Animated */}
        <Header />

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
