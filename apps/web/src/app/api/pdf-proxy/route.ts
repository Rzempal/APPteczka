// src/app/api/pdf-proxy/route.ts
// Proxy dla PDF z zewnętrznych źródeł - omija blokady X-Frame-Options

import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
    const url = request.nextUrl.searchParams.get('url');

    if (!url) {
        return NextResponse.json({ error: 'Missing url parameter' }, { status: 400 });
    }

    // Whitelist - tylko dozwolone domeny
    const allowedDomains = ['rejestry.ezdrowie.gov.pl'];
    try {
        const parsedUrl = new URL(url);
        if (!allowedDomains.some(domain => parsedUrl.hostname.endsWith(domain))) {
            return NextResponse.json({ error: 'Domain not allowed' }, { status: 403 });
        }
    } catch {
        return NextResponse.json({ error: 'Invalid URL' }, { status: 400 });
    }

    try {
        const response = await fetch(url, {
            headers: {
                'Accept': 'application/pdf',
            },
        });

        if (!response.ok) {
            return NextResponse.json(
                { error: `Failed to fetch PDF: ${response.status}` },
                { status: response.status }
            );
        }

        const pdfBuffer = await response.arrayBuffer();

        return new NextResponse(pdfBuffer, {
            headers: {
                'Content-Type': 'application/pdf',
                'Content-Disposition': 'inline', // inline zamiast attachment
                'Cache-Control': 'public, max-age=3600', // Cache na 1h
            },
        });
    } catch (error) {
        console.error('PDF proxy error:', error);
        return NextResponse.json({ error: 'Failed to fetch PDF' }, { status: 500 });
    }
}
