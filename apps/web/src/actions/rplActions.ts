'use server';

// src/actions/rplActions.ts
// Server Action do wyszukiwania leków w Rejestrze Produktów Leczniczych

/**
 * Wynik wyszukiwania w RPL
 */
export interface RplSearchResult {
    id: number;
    nazwa: string;
    moc: string;
    postac: string;
    ulotkaUrl: string;
}

/**
 * Wyszukuje leki w Rejestrze Produktów Leczniczych
 * @param query - Nazwa leku do wyszukania (min. 3 znaki)
 * @returns Lista pasujących leków z linkami do ulotek
 */
export async function searchMedicineInRpl(query: string): Promise<RplSearchResult[]> {
    if (!query || query.trim().length < 3) {
        return [];
    }

    const endpoint = `https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/search/public?name=${encodeURIComponent(query.trim())}&size=10&page=0`;

    try {
        const response = await fetch(endpoint, {
            headers: {
                'Accept': 'application/json'
            },
            next: { revalidate: 3600 } // Cache na 1 godzinę
        });

        if (!response.ok) {
            console.error('RPL API Error:', response.status, response.statusText);
            return [];
        }

        const data = await response.json();

        // Mapowanie odpowiedzi API na nasz format
        // API zwraca: { content: [{ id, medicinalProductName, medicinalProductPower, pharmaceuticalFormName }] }
        if (!data.content || !Array.isArray(data.content)) {
            return [];
        }

        return data.content.map((item: {
            id: number;
            medicinalProductName: string;
            medicinalProductPower: string;
            pharmaceuticalFormName: string;
        }) => ({
            id: item.id,
            nazwa: item.medicinalProductName,
            moc: item.medicinalProductPower || '',
            postac: item.pharmaceuticalFormName || '',
            ulotkaUrl: `https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/${item.id}/leaflet`
        }));

    } catch (error) {
        console.error('RPL Search Error:', error);
        return [];
    }
}
