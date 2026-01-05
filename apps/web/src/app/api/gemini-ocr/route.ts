// src/app/api/gemini-ocr/route.ts
// API Route do rozpoznawania leków ze zdjęć przez Gemini API

import { NextRequest, NextResponse } from 'next/server';
import { recognizeMedicinesFromImage, isGeminiError } from '@/lib/gemini';

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

// Maksymalny rozmiar obrazu: 4MB
const MAX_IMAGE_SIZE = 4 * 1024 * 1024;

// Dozwolone typy MIME
const ALLOWED_MIME_TYPES = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif'
];

export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const { image, mimeType } = body;

        // Walidacja: czy jest obraz
        if (!image || typeof image !== 'string') {
            return NextResponse.json(
                { error: 'Brak obrazu w żądaniu', code: 'INVALID_IMAGE' },
                { status: 400, headers: corsHeaders }
            );
        }

        // Walidacja: typ MIME
        if (!mimeType || !ALLOWED_MIME_TYPES.includes(mimeType)) {
            return NextResponse.json(
                { error: 'Nieprawidłowy format obrazu. Dozwolone: JPEG, PNG, WebP, GIF', code: 'INVALID_IMAGE' },
                { status: 400, headers: corsHeaders }
            );
        }

        // Walidacja: rozmiar (przybliżony - base64 jest ~33% większy)
        const estimatedSize = (image.length * 3) / 4;
        if (estimatedSize > MAX_IMAGE_SIZE) {
            return NextResponse.json(
                { error: 'Obraz jest za duży. Maksymalny rozmiar: 4MB', code: 'INVALID_IMAGE' },
                { status: 400, headers: corsHeaders }
            );
        }

        // Wywołaj Gemini API
        const result = await recognizeMedicinesFromImage(image, mimeType);

        if (isGeminiError(result)) {
            const statusCode = result.code === 'API_KEY_MISSING' ? 500
                : result.code === 'RATE_LIMIT' ? 429
                    : 400;

            return NextResponse.json(result, { status: statusCode, headers: corsHeaders });
        }

        return NextResponse.json(result, { headers: corsHeaders });

    } catch (error) {
        console.error('Gemini OCR API error:', error);
        return NextResponse.json(
            { error: 'Wewnętrzny błąd serwera', code: 'API_ERROR' },
            { status: 500, headers: corsHeaders }
        );
    }
}
