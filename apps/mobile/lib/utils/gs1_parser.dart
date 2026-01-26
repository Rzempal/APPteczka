// gs1_parser.dart v1.0.0 - Parser kodow GS1 Data Matrix
// Wyciaga GTIN, date waznosci, serie i numer seryjny z kodow 2D

/// Sparsowane dane z kodu GS1 Data Matrix
class Gs1Data {
  /// GTIN (14 cyfr) przekonwertowany na EAN-13
  final String? ean;

  /// Data waznosci w formacie YYYY-MM-DD (z AI 17)
  final String? expiryDate;

  /// Numer serii (AI 10)
  final String? batch;

  /// Numer seryjny (AI 21)
  final String? serial;

  /// Oryginalny GTIN-14 przed konwersja
  final String? gtin14;

  const Gs1Data({
    this.ean,
    this.expiryDate,
    this.batch,
    this.serial,
    this.gtin14,
  });

  /// Czy dane zawieraja przynajmniej EAN
  bool get isValid => ean != null && ean!.isNotEmpty;

  /// Czy dane zawieraja date waznosci
  bool get hasExpiryDate => expiryDate != null && expiryDate!.isNotEmpty;

  @override
  String toString() =>
      'Gs1Data(ean: $ean, expiryDate: $expiryDate, batch: $batch, serial: $serial)';
}

/// Parser kodow GS1 Data Matrix (standard farmaceutyczny)
///
/// Obsluguje formaty:
/// - Z nawiasami: `(01)05909990798346(17)280131(10)PAA24010A(21)36653543802628`
/// - Surowe: `01059099907983461728013110PAA24010A2136653543802628`
/// - Z separatorem GS: `0105909990798346\u001D17280131\u001D10PAA24010A`
class Gs1Parser {
  // Stale dlugosci dla AI o stalej dlugosci
  static const Map<String, int> _fixedLengthAIs = {
    '01': 14, // GTIN
    '17': 6, // Data waznosci YYMMDD
  };

  // AI o zmiennej dlugosci (max 20 znakow, konczy sie separatorem lub nastepnym AI)
  static const Set<String> _variableLengthAIs = {'10', '21'};

  // Wszystkie obslugiwane AI
  static const Set<String> _knownAIs = {'01', '10', '17', '21'};

  /// Parsuje surowy ciag z kodu GS1 Data Matrix
  /// Zwraca null jesli ciag nie jest prawidlowym kodem GS1
  static Gs1Data? parse(String rawValue) {
    if (rawValue.isEmpty) return null;

    // Usun nawiasy jesli obecne (format czytelny dla czlowieka)
    String normalized = _removeParentheses(rawValue);

    // Parsuj AI sekwencyjnie
    final Map<String, String> parsed = {};
    int pos = 0;

    while (pos < normalized.length) {
      // Pomin separator GS
      if (normalized[pos] == '\u001D' || normalized[pos] == ' ') {
        pos++;
        continue;
      }

      // Sprobuj dopasowac znany AI (2 znaki)
      if (pos + 2 > normalized.length) break;
      final ai = normalized.substring(pos, pos + 2);

      if (!_knownAIs.contains(ai)) {
        // Nieznany AI - przerywamy parsowanie
        break;
      }

      pos += 2; // Przeskocz AI

      if (_fixedLengthAIs.containsKey(ai)) {
        // AI o stalej dlugosci
        final len = _fixedLengthAIs[ai]!;
        if (pos + len > normalized.length) break;
        parsed[ai] = normalized.substring(pos, pos + len);
        pos += len;
      } else if (_variableLengthAIs.contains(ai)) {
        // AI o zmiennej dlugosci - szukaj separatora lub nastepnego AI
        final endPos = _findVariableFieldEnd(normalized, pos);
        parsed[ai] = normalized.substring(pos, endPos);
        pos = endPos;
      }
    }

    // Sprawdz czy mamy przynajmniej GTIN
    final gtin14 = parsed['01'];
    if (gtin14 == null || gtin14.length != 14) return null;

    // Konwertuj GTIN-14 na EAN-13 (usun wiodace zero jesli zaczyna sie od 0)
    String ean13;
    if (gtin14.startsWith('0')) {
      ean13 = gtin14.substring(1); // 13 cyfr
    } else {
      // GTIN-14 nie zaczyna sie od 0 - potencjalnie inny format
      // Probujemy wziac ostatnie 13 cyfr
      ean13 = gtin14.substring(1);
    }

    // Parsuj date waznosci (YYMMDD -> YYYY-MM-DD)
    String? expiryDate;
    final rawDate = parsed['17'];
    if (rawDate != null && rawDate.length == 6) {
      expiryDate = _parseExpiryDate(rawDate);
    }

    return Gs1Data(
      ean: ean13,
      gtin14: gtin14,
      expiryDate: expiryDate,
      batch: parsed['10'],
      serial: parsed['21'],
    );
  }

  /// Usuwa nawiasy z formatu czytelnego: (01)123... -> 01123...
  static String _removeParentheses(String input) {
    return input.replaceAll(RegExp(r'[()]'), '');
  }

  /// Znajduje koniec pola o zmiennej dlugosci
  static int _findVariableFieldEnd(String data, int start) {
    for (int i = start; i < data.length; i++) {
      // Separator GS
      if (data[i] == '\u001D' || data[i] == ' ') {
        return i;
      }
      // Sprawdz czy nastepne 2 znaki to znany AI z poprawnym formatem
      if (i + 2 <= data.length) {
        final potentialAi = data.substring(i, i + 2);
        if (_knownAIs.contains(potentialAi)) {
          // Dla AI o stalej dlugosci (01, 17) - musi byc dosc cyfr za nimi
          if (_fixedLengthAIs.containsKey(potentialAi)) {
            final requiredLen = _fixedLengthAIs[potentialAi]!;
            if (i + 2 + requiredLen <= data.length) {
              final afterAi = data.substring(i + 2, i + 2 + requiredLen);
              // Dla 01 i 17 wszystkie znaki musza byc cyframi
              if (RegExp(r'^\d+$').hasMatch(afterAi)) {
                return i;
              }
            }
          } else {
            // Dla AI o zmiennej dlugosci (10, 21) - akceptuj jesli poprzedni znak byl cyfra
            // a nastepny po AI nie jest czescia poprzedniej wartosci
            // Heurystyka: jesli poprzedni znak to litera lub koniec batch, to nowy AI
            if (i > start) {
              final prevChar = data[i - 1];
              // Jesli batch konczy sie litera a nagle mamy cyfry - to prawdopodobnie nowy AI
              if (RegExp(r'[A-Za-z]').hasMatch(prevChar)) {
                return i;
              }
            }
          }
        }
      }
    }
    return data.length;
  }

  /// Parsuje date YYMMDD na YYYY-MM-DD
  static String? _parseExpiryDate(String yymmdd) {
    if (yymmdd.length != 6) return null;

    final yy = int.tryParse(yymmdd.substring(0, 2));
    final mm = int.tryParse(yymmdd.substring(2, 4));
    final dd = int.tryParse(yymmdd.substring(4, 6));

    if (yy == null || mm == null || dd == null) return null;
    if (mm < 1 || mm > 12) return null;

    // Rok: 00-69 -> 2000-2069, 70-99 -> 1970-1999
    final year = yy < 70 ? 2000 + yy : 1900 + yy;

    // Dzien 00 oznacza koniec miesiaca (standard GS1)
    final day = dd == 0 ? _lastDayOfMonth(year, mm) : dd;

    return '$year-${mm.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  /// Zwraca ostatni dzien miesiaca
  static int _lastDayOfMonth(int year, int month) {
    // Przejscie do nastepnego miesiaca i cofniecie o 1 dzien
    final nextMonth = DateTime(year, month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  /// Sprawdza czy ciag moze byc kodem GS1 (heurystyka)
  static bool mightBeGs1(String value) {
    if (value.length < 16) return false; // Min: AI(2) + GTIN(14)

    // Sprawdz czy zaczyna sie od (01) lub 01
    if (value.startsWith('(01)') || value.startsWith('01')) {
      return true;
    }

    // Sprawdz czy zawiera separator GS
    if (value.contains('\u001D')) {
      return true;
    }

    return false;
  }
}
