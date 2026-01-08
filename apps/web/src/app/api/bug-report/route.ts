// src/app/api/bug-report/route.ts
// API Route do przyjmowania raportów błędów z aplikacji mobilnej

import { NextRequest, NextResponse } from 'next/server';

// =============================================================================
// KONFIGURACJA EMAIL - RESEND (domena resztatokod.pl zweryfikowana 2026-01-08)
// =============================================================================
const BUG_REPORT_EMAIL = process.env.BUG_REPORT_EMAIL || 'michal.rapala@resztatokod.pl';
const RESEND_API_KEY = process.env.RESEND_API_KEY;
const RESEND_FROM = process.env.RESEND_FROM || 'Karton <karton@resztatokod.pl>';

interface BugReportRequest {
    log?: string;
    text?: string;
    topic?: string;
    screenshot?: string; // base64
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
        const { log, text, topic, screenshot, appVersion, deviceInfo, errorMessage, category, channel, replyEmail } = body;

        // Walidacja - musi być coś do wysłania
        if (!log && !text && !screenshot) {
            return NextResponse.json(
                { error: 'Brak danych do wysłania', code: 'INVALID_REQUEST' },
                { status: 400 }
            );
        }

        // Przygotuj treść emaila
        const timestamp = new Date().toISOString();
        const htmlContent = `
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding: 20px; }
        .header { background: #1a1a2e; color: #4ade80; padding: 20px; border-radius: 8px; }
        .section { margin: 20px 0; padding: 15px; background: #f5f5f5; border-radius: 8px; }
        .label { font-weight: bold; color: #666; margin-bottom: 5px; }
        pre { background: #1a1a2e; color: #e2e8f0; padding: 15px; border-radius: 8px; overflow-x: auto; font-size: 12px; }
        .error { color: #ef4444; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Bug Report - Karton na leki</h1>
        <p>Otrzymano: ${timestamp}</p>
    </div>

    ${errorMessage ? `
    <div class="section">
        <div class="label">Błąd:</div>
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
        <p>${escapeHtml(text)}</p>
    </div>
    ` : ''}

    <div class="section">
        <div class="label">Informacje o urządzeniu:</div>
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

    ${screenshot ? '<p><em>Screenshot dołączony jako załącznik</em></p>' : ''}
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

        if (screenshot) {
            attachments.push({
                filename: `karton_screenshot_${timestamp.replace(/[:.]/g, '-')}.png`,
                content: screenshot, // już jest base64
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
                subject: `[Karton] - [${getCategoryLabel(category)}]: ${topic || (errorMessage ? errorMessage.substring(0, 50) : 'Raport użytkownika')}`,
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

