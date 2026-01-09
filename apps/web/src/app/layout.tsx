import type { Metadata } from "next";
import { DM_Sans, Fraunces, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const dmSans = DM_Sans({
  subsets: ["latin", "latin-ext"],
  variable: "--font-dm-sans",
  weight: ["400", "500", "600", "700"],
});

const fraunces = Fraunces({
  subsets: ["latin", "latin-ext"],
  variable: "--font-fraunces",
});

const jetbrainsMono = JetBrains_Mono({
  subsets: ["latin", "latin-ext"],
  variable: "--font-mono",
  weight: ["400", "700"],
});

export const metadata: Metadata = {
  title: "Karton z lekami – Domowa apteczka z AI",
  description: "Nie kop w pudle. Sprawdź w telefonie. Aplikacja do zarządzania domową apteczką. Skanuj leki AI, śledź terminy ważności, eksportuj do PDF. 100% offline.",
  keywords: ["apteczka", "leki", "zdrowie", "AI", "zarządzanie lekami", "karton z lekami", "domowa apteczka"],
  authors: [{ name: "ResztaToKod" }],
  icons: {
    icon: "/favicon.png",
  },
  openGraph: {
    title: "Karton z lekami – Domowa apteczka z AI",
    description: "Nie kop w pudle. Sprawdź w telefonie.",
    type: "website",
    locale: "pl_PL",
    url: "https://kartonzlekami.resztatokod.pl",
  },
  twitter: {
    card: "summary_large_image",
    title: "Karton z lekami – Domowa apteczka z AI",
    description: "Nie kop w pudle. Sprawdź w telefonie.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="pl" suppressHydrationWarning>
      <body className={`${dmSans.variable} ${fraunces.variable} ${jetbrainsMono.variable} font-sans antialiased`} style={{ background: 'var(--color-bg)', color: 'var(--color-text)' }}>
        {children}
      </body>
    </html>
  );
}
