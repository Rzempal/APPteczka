// src/app/privacy/page.tsx v1.0.0
// Privacy Policy Page

import Link from 'next/link';
import { Metadata } from 'next';

export const metadata: Metadata = {
    title: 'Polityka Prywatności - Karton z lekami',
    description: 'Polityka prywatności aplikacji Karton z lekami. Twoja prywatność jest dla nas najważniejsza.',
};

export default function PrivacyPage() {
    return (
        <div className="landing-page">
            {/* Navbar */}
            <nav className="navbar">
                <div className="container nav-content">
                    <Link href="/" className="logo">
                        <span className="logo-icon">📦</span>
                        Karton z lekami
                    </Link>
                </div>
            </nav>

            {/* Content */}
            <main className="privacy-content">
                <div className="container">
                    <article className="privacy-article neu-card">
                        <h1>Polityka Prywatności</h1>
                        <p className="last-update">Ostatnia aktualizacja: 2026-01-07</p>

                        <p className="intro">
                            Twoja prywatność jest dla nas najważniejsza. Aplikacja "Karton z lekami" została zaprojektowana zgodnie z zasadą <strong>Privacy by Default</strong> i <strong>Offline First</strong>.
                        </p>

                        <section>
                            <h2>1. Gromadzenie i Przechowywanie Danych</h2>

                            <h3>Działanie Offline</h3>
                            <p>
                                Aplikacja działa w trybie <strong>offline</strong>. Wszystkie dane dotyczące Twojej apteczki (lista leków, daty ważności, notatki) są przechowywane wyłącznie w <strong>pamięci wewnętrznej Twojego urządzenia</strong>.
                            </p>

                            <h3>Brak Kont Użytkowników</h3>
                            <p>
                                Aplikacja nie posiada systemu kont, logowania ani rejestracji. Nie gromadzimy, nie przechowujemy ani nie przetwarzamy Twoich danych osobowych (takich jak imię, nazwisko, adres e-mail, czy dane o stanie zdrowia) na żadnych zewnętrznych serwerach.
                            </p>
                        </section>

                        <section>
                            <h2>2. Uprawnienia i Dostęp do Funkcji Urządzenia</h2>

                            <h3>Aparat i Galeria (Camera & Storage)</h3>
                            <p>
                                Aplikacja wymaga dostępu do aparatu i galerii wyłącznie w celu umożliwienia skorzystania z funkcji <strong>Skaner Leków (AI OCR)</strong>.
                            </p>
                            <ul>
                                <li>Zdjęcia opakowań leków są wykonywane tylko na Twoje wyraźne żądanie.</li>
                                <li>Zdjęcia te nie są trwale przechowywane przez Aplikację ani udostępniane publicznie.</li>
                            </ul>
                        </section>

                        <section>
                            <h2>3. Przetwarzanie Danych przez Usługi Zewnętrzne (AI)</h2>
                            <p>
                                W przypadku skorzystania z funkcji Skanera AI (rozpoznawanie leków ze zdjęcia), Aplikacja korzysta z zewnętrznego interfejsu API (Google Gemini), udostępnianego przez backend pośredniczący (proxy).
                            </p>
                            <ul>
                                <li><strong>Co jest wysyłane:</strong> Wyłącznie zdjęcie opakowania leku, które wykonałeś w danym momencie.</li>
                                <li><strong>Cel:</strong> Odczytanie tekstu (nazwy leku, dawki, postaci) ze zdjęcia.</li>
                                <li><strong>Przechowywanie:</strong> Zdjęcia są przetwarzane w sposób <strong>lotny (ephemeral)</strong>. Nie są one zapisywane na serwerach dewelopera ani wykorzystywane do trenowania modeli AI w sposób identyfikujący użytkownika.</li>
                                <li><strong>Dostawca AI:</strong> Usługa oparta jest na technologii Google Vertex AI / Gemini.</li>
                            </ul>
                        </section>

                        <section>
                            <h2>4. Analityka i Śledzenie</h2>
                            <p>
                                Aplikacja <strong>NIE</strong> zawiera żadnych narzędzi analitycznych, trackerów reklamowych ani systemów śledzenia zachowań użytkowników (np. Google Analytics, Firebase Analytics, Facebook Pixel).
                            </p>
                        </section>

                        <section>
                            <h2>5. Linki Zewnętrzne (Wesprzyj Projekt)</h2>
                            <p>
                                W Aplikacji znajduje się link "Wesprzyj projekt i postaw nam kawę" (BuyCoffee). Kliknięcie w ten link otwiera systemową przeglądarkę internetową.
                            </p>
                            <ul>
                                <li>Wszelkie transakcje odbywają się poza Aplikacją, bezpośrednio na stronie operatora płatności.</li>
                                <li>Aplikacja nie ma dostępu do Twoich danych płatniczych.</li>
                            </ul>
                        </section>

                        <section>
                            <h2>6. Usuwanie Danych</h2>
                            <p>
                                Ponieważ wszystkie dane znajdują się na Twoim urządzeniu, masz nad nimi pełną kontrolę.
                            </p>
                            <ul>
                                <li><strong>Usunięcie pojedynczego leku:</strong> Użyj ikony kosza w aplikacji.</li>
                                <li><strong>Całkowite usunięcie danych:</strong> Odinstalowanie aplikacji lub wyczyszczenie jej danych w ustawieniach systemu Android spowoduje trwałe usunięcie wszystkich wprowadzonych informacji.</li>
                            </ul>
                        </section>

                        <section>
                            <h2>7. Kontakt</h2>
                            <p>
                                W razie pytań dotyczących prywatności, prosimy o kontakt pod adresem e-mail: <a href="mailto:michal.rapala@resztatokod.pl">michal.rapala@resztatokod.pl</a>
                            </p>
                        </section>

                        <div className="back-link">
                            <Link href="/" className="btn btn-secondary">
                                ← Powrót do strony głównej
                            </Link>
                        </div>
                    </article>
                </div>
            </main>

            {/* Footer */}
            <footer className="footer">
                <div className="container footer-content">
                    <p className="footer-copyright">
                        © 2026 ResztaToKod. Wszystkie prawa zastrzeżone.
                    </p>
                </div>
            </footer>
        </div>
    );
}
