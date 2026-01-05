// src/app/api/gemini-ocr-dual/route.ts
// API Route do rozpoznawania leku + daty ważności z 2 zdjęć przez Gemini API

import { NextRequest, NextResponse } from 'next/server';
import { recognizeMedicineWithDateFromImages, isDualOCRError } from '@/lib/dual-ocr';

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

function validateImage(image: unknown, mimeType: unknown, fieldName: string): string | null {
    if (!image || typeof image !== 'string') {
        return `Brak obrazu ${fieldName} w żądaniu`;
    }
    if (!mimeType || !ALLOWED_MIME_TYPES.includes(mimeType as string)) {
        return `Nieprawidłowy format obrazu ${fieldName}. Dozwolone: JPEG, PNG, WebP, GIF`;
    }
    const estimatedSize = (image.length * 3) / 4;
    if (estimatedSize > MAX_IMAGE_SIZE) {
        return `Obraz ${fieldName} jest za duży. Maksymalny rozmiar: 4MB`;
    }
    return null;
}

export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const { frontImage, frontMimeType, dateImage, dateMimeType } = body;

        // Walidacja: zdjęcie frontu
        const frontError = validateImage(frontImage, frontMimeType, 'frontu');
        if (frontError) {
            return NextResponse.json(
                { error: frontError, code: 'INVALID_IMAGE' },
                { status: 400, headers: corsHeaders }
            );
        }

        // Walidacja: zdjęcie daty
        const dateError = validateImage(dateImage, dateMimeType, 'daty');
        if (dateError) {
            return NextResponse.json(
                { error: dateError, code: 'INVALID_IMAGE' },
                { status: 400, headers: corsHeaders }
            );
        }

        // Wywołaj Gemini API z oboma zdjęciami
        const result = await recognizeMedicineWithDateFromImages(
            frontImage,
            frontMimeType,
            dateImage,
            dateMimeType
        );

        if (isDualOCRError(result)) {
            const statusCode = result.code === 'API_KEY_MISSING' ? 500
                : result.code === 'RATE_LIMIT' ? 429
                    : 400;

            return NextResponse.json(result, { status: statusCode, headers: corsHeaders });
        }

        return NextResponse.json(result, { headers: corsHeaders });

    } catch (error) {
        console.error('Dual OCR API error:', error);
        return NextResponse.json(
            { error: 'Wewnętrzny błąd serwera', code: 'API_ERROR' },
            { status: 500, headers: corsHeaders }
        );
    }
}
