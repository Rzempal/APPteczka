// src/app/api/gemini-name-lookup/route.ts
// API Route do rozpoznawania leków po nazwie przez Gemini API

import { NextRequest, NextResponse } from 'next/server';
import { lookupMedicineByName, isGeminiError } from '@/lib/gemini';

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
        const { name } = body;

        // Walidacja: czy jest nazwa
        if (!name || typeof name !== 'string') {
            return NextResponse.json(
                { error: 'Brak nazwy leku w żądaniu', code: 'INVALID_INPUT' },
                { status: 400, headers: corsHeaders }
            );
        }

        // Walidacja: minimalna długość
        const trimmedName = name.trim();
        if (trimmedName.length < 2) {
            return NextResponse.json(
                { error: 'Nazwa leku jest za krótka (minimum 2 znaki)', code: 'INVALID_INPUT' },
                { status: 400, headers: corsHeaders }
            );
        }

        // Wywołaj Gemini API
        const result = await lookupMedicineByName(trimmedName);

        if (isGeminiError(result)) {
            const statusCode = result.code === 'API_KEY_MISSING' ? 500
                : result.code === 'RATE_LIMIT' ? 429
                    : 400;

            return NextResponse.json(result, { status: statusCode, headers: corsHeaders });
        }

        return NextResponse.json(result, { headers: corsHeaders });

    } catch (error) {
        console.error('Gemini Name Lookup API error:', error);
        return NextResponse.json(
            { error: 'Wewnętrzny błąd serwera', code: 'API_ERROR' },
            { status: 500, headers: corsHeaders }
        );
    }
}
