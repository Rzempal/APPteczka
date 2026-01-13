// src/app/api/bug-report/route.ts
// API Route do przyjmowania raportów błędów z aplikacji mobilnej

import { NextRequest, NextResponse } from 'next/server';

// =============================================================================
// KONFIGURACJA EMAIL - RESEND (domena resztatokod.pl zweryfikowana 2026-01-08)
// =============================================================================
const BUG_REPORT_EMAIL = process.env.BUG_REPORT_EMAIL || 'feedback@resztatokod.pl';
const RESEND_API_KEY = process.env.RESEND_API_KEY;
const RESEND_FROM = process.env.RESEND_FROM || 'Karton <karton@resztatokod.pl>';

interface BugReportRequest {
    log?: string;
    text?: string;
    topic?: string;
    screenshot?: string; // base64 (backward compatibility)
    screenshots?: string[]; // base64 array
    appVersion?: string;
    deviceInfo?: string;
    errorMessage?: string;
    category?: string;
    channel?: string;
    replyEmail?: string;
}

export async function POST(request: NextRequest) {
    try {
        // Sprawdź API key
        if (!RESEND_API_KEY) {
            console.error('Missing RESEND_API_KEY');
            return NextResponse.json(
                { error: 'Serwis raportowania niedostępny', code: 'CONFIG_ERROR' },
                { status: 500 }
            );
        }

        const body: BugReportRequest = await request.json();
        const { log, text, topic, screenshot, screenshots, appVersion, deviceInfo, errorMessage, category, channel, replyEmail } = body;

        // Walidacja - musi być coś do wysłania
        if (!log && !text && !screenshot) {
            return NextResponse.json(
                { error: 'Brak danych do wysłania', code: 'INVALID_REQUEST' },
                { status: 400 }
            );
        }

        // Przygotuj temat maila
        const subject = `[Karton] - [${getCategoryLabel(category)}]: ${topic || (errorMessage ? errorMessage.substring(0, 50) : 'Raport użytkownika')}`;

        // Przygotuj treść emaila
        const timestamp = new Date().toISOString();
        const htmlContent = `
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding: 20px; color: #333; }
        .header { background: #1a1a2e; color: #4ade80; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .section { margin: 20px 0; padding: 15px; background: #f5f5f5; border-radius: 8px; border-left: 4px solid #ddd; }
        .label { font-weight: bold; color: #666; margin-bottom: 5px; text-transform: uppercase; font-size: 11px; letter-spacing: 0.05em; }
        pre { background: #1a1a2e; color: #e2e8f0; padding: 15px; border-radius: 8px; overflow-x: auto; font-size: 12px; line-height: 1.5; }
        .error { color: #ef4444; font-weight: bold; }
        .ai-prompt { background: #f0f7ff; border: 2px dashed #0070f3; padding: 20px; border-radius: 8px; margin-top: 40px; }
        .copy-hint { font-size: 12px; color: #0070f3; font-weight: bold; margin-bottom: 10px; }
    </style>
</head>
<body>
    <div class="header">
        <h1 style="margin:0; font-size: 24px;">${escapeHtml(subject)}</h1>
        <p style="margin: 10px 0 0 0; opacity: 0.7; font-size: 13px;">Otrzymano: ${timestamp}</p>
    </div>

    ${errorMessage ? `
    <div class="section" style="border-left-color: #ef4444;">
        <div class="label">Błąd systemowy:</div>
        <p class="error">${escapeHtml(errorMessage)}</p>
    </div>
    ` : ''}

    ${topic ? `
    <div class="section">
        <div class="label">Temat:</div>
        <p><strong>${escapeHtml(topic)}</strong></p>
    </div>
    ` : ''}

    ${text ? `
    <div class="section">
        <div class="label">Opis użytkownika:</div>
        <p style="white-space: pre-wrap;">${escapeHtml(text)}</p>
    </div>
    ` : ''}

    <div class="section">
        <div class="label">Informacje o systemie:</div>
        <p><strong>Wersja aplikacji:</strong> ${appVersion || 'Nieznana'}</p>
        <p><strong>Urządzenie:</strong> ${deviceInfo || 'Nieznane'}</p>
        <p><strong>Kategoria:</strong> ${category || 'Nieznana'}</p>
        <p><strong>Kanał:</strong> ${channel || 'production'}</p>
        ${replyEmail ? `<p><strong>Odpowiedz do:</strong> <a href="mailto:${escapeHtml(replyEmail)}">${escapeHtml(replyEmail)}</a></p>` : ''}
    </div>

    ${log ? `
    <div class="section">
        <div class="label">Logi aplikacji:</div>
        <pre>${escapeHtml(log)}</pre>
    </div>
    ` : ''}

    ${(screenshot || (screenshots && screenshots.length > 0)) ? `
    <div class="section">
        <div class="label">Załączniki wizualne:</div>
        <p style="color: #666; font-style: italic;">📷 ${screenshot ? '1 screenshot' : ''}${(screenshot && screenshots && screenshots.length > 0) ? ' + ' : ''}${screenshots ? `${screenshots.length} zdjęć` : ''} dołączone jako załączniki</p>
    </div>
    ` : ''}

    <div class="ai-prompt">
        <div class="copy-hint">PROMPT DLA CLAUDE/GEMINI (Szybkie rozwiązanie):</div>
        <pre id="ai-copy-content">--- AI SOLVER PROMPT ---
Zanalizuj poniższy raport z aplikacji "Karton" i zaproponuj rozwiązanie/implementację:

KONTEKST:
- Kategoria: ${category || 'Błąd'}
- Temat: ${topic || 'Brak'}
- Błąd: ${errorMessage || 'Brak'}
- Opis użytkownika: ${text || 'Brak'}
- Urządzenie: ${deviceInfo || 'Nieznane'}
- Wersja: ${appVersion || 'Nieznane'}

DANE TECHNICZNE (LOGI):
${log ? log : 'Brak logów.'}</pre>
    </div>
</body>
</html>
        `;

        // Przygotuj załączniki
        const attachments: { filename: string; content: string }[] = [];

        if (log) {
            attachments.push({
                filename: `karton_log_${timestamp.replace(/[:.]/g, '-')}.txt`,
                content: Buffer.from(log).toString('base64'),
            });
        }

        // Backward compatibility for single 'screenshot'
        if (screenshot) {
            attachments.push({
                filename: `karton_screenshot_${timestamp.replace(/[:.]/g, '-')}.png`,
                content: screenshot, // już jest base64
            });
        }

        // Multiple screenshots
        if (screenshots && screenshots.length > 0) {
            screenshots.forEach((s, index) => {
                attachments.push({
                    filename: `karton_photo_${index + 1}_${timestamp.replace(/[:.]/g, '-')}.png`,
                    content: s,
                });
            });
        }

        // Wyślij przez Resend
        const resendResponse = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${RESEND_API_KEY}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                from: RESEND_FROM,
                to: [BUG_REPORT_EMAIL],
                subject: subject,
                html: htmlContent,
                attachments: attachments.length > 0 ? attachments : undefined,
            }),
        });

        if (!resendResponse.ok) {
            const errorData = await resendResponse.json().catch(() => ({}));
            console.error('Resend API error:', JSON.stringify(errorData));
            console.error('Resend status:', resendResponse.status);
            console.error('Send config:', { from: RESEND_FROM, to: BUG_REPORT_EMAIL });

            const errorMessage = errorData?.message || errorData?.error || 'Nieznany błąd Resend';
            return NextResponse.json(
                { error: `Błąd wysyłki: ${errorMessage}`, code: 'SEND_ERROR', details: errorData },
                { status: 500 }
            );
        }

        return NextResponse.json({ success: true });

    } catch (error) {
        console.error('Bug report API error:', error);
        return NextResponse.json(
            { error: 'Wewnętrzny błąd serwera', code: 'API_ERROR' },
            { status: 500 }
        );
    }
}

function escapeHtml(text: string): string {
    return text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;')
        .replace(/\n/g, '<br>');
}

function getCategoryLabel(category?: string): string {
    switch (category) {
        case 'bug': return 'Bug';
        case 'suggestion': return 'Sugestia';
        case 'question': return 'Pytanie';
        default: return 'Bug';
    }
}

