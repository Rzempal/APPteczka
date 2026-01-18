// src/app/api/gemini-shelf-life/route.ts
// API Route do analizy terminu ważności po otwarciu przez Gemini API

import { NextRequest, NextResponse } from 'next/server';
import { analyzeShelfLife, isGeminiError } from '@/lib/gemini';

// CORS headers dla cross-origin requests (mobile app)
const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
};

// Handler dla preflight OPTIONS request
export async function OPTIONS() {
    return new NextResponse(null, { status: 204, headers: corsHeaders });
}

export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const { pdfUrl, pdfBase64 } = body;

        // Walidacja: musi być PDF URL lub base64
        if (!pdfUrl && !pdfBase64) {
            return NextResponse.json(
                { error: 'Brak URL ulotki lub danych PDF w żądaniu', code: 'INVALID_INPUT' },
                { status: 400, headers: corsHeaders }
            );
        }

        let base64Data: string;

        // Jeśli podano URL, pobierz PDF
        if (pdfUrl) {
            try {
                const pdfResponse = await fetch(pdfUrl, {
                    headers: {
                        'Accept': 'application/pdf',
                    },
                });

                if (!pdfResponse.ok) {
                    return NextResponse.json(
                        { error: 'Nie udało się pobrać ulotki PDF', code: 'PDF_FETCH_ERROR' },
                        { status: 400, headers: corsHeaders }
                    );
                }

                const pdfBuffer = await pdfResponse.arrayBuffer();
                base64Data = Buffer.from(pdfBuffer).toString('base64');
            } catch (fetchError) {
                console.error('PDF fetch error:', fetchError);
                return NextResponse.json(
                    { error: 'Błąd podczas pobierania ulotki', code: 'PDF_FETCH_ERROR' },
                    { status: 400, headers: corsHeaders }
                );
            }
        } else {
            base64Data = pdfBase64;
        }

        // Wywołaj Gemini API
        const result = await analyzeShelfLife(base64Data);

        if (isGeminiError(result)) {
            const statusCode = result.code === 'API_KEY_MISSING' ? 500
                : result.code === 'RATE_LIMIT' ? 429
                    : 400;

            return NextResponse.json(result, { status: statusCode, headers: corsHeaders });
        }

        return NextResponse.json(result, { headers: corsHeaders });

    } catch (error) {
        console.error('Gemini Shelf Life API error:', error);
        return NextResponse.json(
            { error: 'Wewnętrzny błąd serwera', code: 'API_ERROR' },
            { status: 500, headers: corsHeaders }
        );
    }
}
