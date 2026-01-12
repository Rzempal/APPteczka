# 🤖 Integracja Gemini API – Przewodnik Reużywalności

Ten dokument opisuje architekturę i implementację integracji z Gemini API użytą w projekcie **APPteczka**, z myślą o jej łatwym przeniesieniu do innych systemów (Flutter, Web, Python).

## 🏗️ Architektura: Model Proxy (Vercel)

Zamiast bezpośredniego łączenia aplikacji klienckiej (np. Flutter) z API Google, stosujemy **Backend Proxy**.

**Zalety:**

- 🛡️ **Bezpieczeństwo:** Klucz API (`GEMINI_API_KEY`) nigdy nie wycieka do kodu klienta.
- 🎯 **Centralizacja Promptów:** Zmiana zachowania AI nie wymaga aktualizacji aplikacji w sklepie.
- 🚦 **Kontrola:** Możliwość łatwego dodania Rate Limitingu lub filtrowania treści.

---

## 📝 Prompt Engineering (Po Polsku)

Kluczem do sukcesu jest wymuszenie strukturalnego formatu JSON oraz obsługa "niepewności".

### 1. Rozpoznawanie ze zdjęcia (OCR)

Poniższy prompt instruuje AI, jak wyciągać dane z obrazu, traktując kod EAN jako priorytet.

```markdown
# Prompt – Rozpoznawanie produktów ze zdjęcia

## Rola
Jesteś asystentem pomagającym użytkownikowi katalogować produkty (np. leki).

## Zadanie (Priorytetyzacja)
1. **Kod kreskowy (EAN) to "kotwica pewności".** Jeśli EAN jest widoczny, ZAWSZE zwróć rekord.
2. Jeśli widzisz kod, ale nie możesz odczytać nazwy, ustaw `"nazwa": null`.
3. Format wyjścia: WYŁĄCZNIE poprawny JSON.

```json
{
  "produkty": [
    {
      "nazwa": "string | null",
      "ean": "string | null",
      "opis": "string (krótki opis)",
      "tagi": ["tag1", "tag2"]
    }
  ]
}
```

---

## 🌐 Backend (Next.js / TypeScript)

Implementacja serwerowa obsługująca komunikację z `v1beta/models/gemini-1.5-flash:generateContent`.

### Metoda pomocnicza: Wyodrębnianie JSON

Gemini często otacza wynik blokami markdown. Użyj tej logiki, aby uniknąć błędów parsowania:

```typescript
function extractJson(text: string) {
    let jsonString = text.trim();
    // Szukaj bloku ```json ... ``` LUB bezpośrednio { ... }
    const match = jsonString.match(/```json\s*([\s\S]*?)\s*```/) || 
                  jsonString.match(/\{[\s\S]*\}/);
    
    if (match) {
        return JSON.parse(match[1] || match[0]);
    }
    throw new Error("Nie znaleziono poprawnego JSON w odpowiedzi");
}
```

---

## 📱 Mobile (Flutter / Dart) - Continuous Scanning

Przy "skanowaniu ciągłym" (np. wiele kodów kreskowych jeden po drugim) stosujemy model **Batch processing**.

### Logika Przetwarzania Wsadowego

Zamiast wysyłać zapytanie po każdym produkcie, zbieramy listę (np. kody EAN) i przetwarzamy je równolegle na końcu.

```dart
Future<void> processBatch(List<String> items) async {
  // Mapujemy listę na listę Future'ów (równoległe zapytania)
  final futures = items.map((item) => geminiService.lookup(item)).toList();
  
  // Czekamy na wszystkie wyniki (np. 5 zapytań naraz)
  final results = await Future.wait(futures);
  
  // Filtrujemy błędy i zapisujemy sukcesy
  saveResults(results.whereType<Success>().toList());
}
```

---

## 🐍 Implementacja w Pythonie

Jeśli chcesz użyć tej samej logiki w Pythonie (np. backend FastAPI):

```python
import google.generativeai as genai
import os

genai.configure(api_key=os.environ["GEMINI_API_KEY"])
model = genai.GenerativeModel('gemini-1.5-flash')

def lookup_product(name: str):
    prompt = f"Rozpoznaj produkt: {name}. Odpowiedz TYLKO w formacie JSON."
    response = model.generate_content(prompt)
    
    # Pythonowa obsługa JSON z odpowiedzi
    try:
        data = response.text
        # Tutaj wykonaj analogiczne czyszczenie tekstu jak w TS
        print(f"Dane produktu: {data}")
    except Exception as e:
        print(f"Błąd: {e}")
```

---

## 💡 Best Practices (Dobre Praktyki)

1. **Temperature = 0.1**: Dla zadań ekstrakcji danych (JSON) zawsze ustawiaj niską temperaturę. Zmniejsza to ryzyko "halucynacji" i zmian w strukturze pola.
2. **Flash vs Pro**: Do OCR i prostych lookupów model `gemini-1.5-flash` jest znacznie szybszy i tańszy/posiada większe limity darmowe niż `1.5-pro`.
3. **Mime-Types**: Przy wysyłaniu obrazów zawsze jawnie określaj `mimeType` (image/jpeg, image/png), aby skrócić czas procesowania po stronie Google.
4. **Rate Limiting**: Darmowy tier Gemini ma limity (np. 15 zapytań na minutę). Warto zaimplementować prosty kolejkator w aplikacji.
