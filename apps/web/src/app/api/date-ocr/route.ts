// src/app/api/date-ocr/route.ts
// API Route do rozpoznawania daty ważności ze zdjęcia przez Gemini API

import { NextRequest, NextResponse } from 'next/server';
import { recognizeDateFromImage, isDateError } from '@/lib/date-ocr';

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
                { status: 400 }
            );
        }

        // Walidacja: typ MIME
        if (!mimeType || !ALLOWED_MIME_TYPES.includes(mimeType)) {
            return NextResponse.json(
                { error: 'Nieprawidłowy format obrazu. Dozwolone: JPEG, PNG, WebP, GIF', code: 'INVALID_IMAGE' },
                { status: 400 }
            );
        }

        // Walidacja: rozmiar (przybliżony - base64 jest ~33% większy)
        const estimatedSize = (image.length * 3) / 4;
        if (estimatedSize > MAX_IMAGE_SIZE) {
            return NextResponse.json(
                { error: 'Obraz jest za duży. Maksymalny rozmiar: 4MB', code: 'INVALID_IMAGE' },
                { status: 400 }
            );
        }

        // Wywołaj Gemini API
        const result = await recognizeDateFromImage(image, mimeType);

        if (isDateError(result)) {
            const statusCode = result.code === 'API_KEY_MISSING' ? 500
                : result.code === 'RATE_LIMIT' ? 429
                    : 400;

            return NextResponse.json(result, { status: statusCode });
        }

        return NextResponse.json(result);

    } catch (error) {
        console.error('Date OCR API error:', error);
        return NextResponse.json(
            { error: 'Wewnętrzny błąd serwera', code: 'API_ERROR' },
            { status: 500 }
        );
    }
}
