// ean_validator.dart v0.001 EAN/GTIN barcode validation (Modulo 10)

/// Walidator kodow kreskowych EAN/GTIN
/// Obsluguje: EAN-13, EAN-8, UPC-A (12 cyfr -> normalizacja do EAN-13)
class EanValidator {
  /// Sprawdza czy kod EAN jest poprawny (walidacja Modulo 10)
  /// Zwraca true jesli kod ma poprawna dlugosc i sume kontrolna
  static bool isValid(String? ean) {
    if (ean == null || ean.isEmpty) return false;

    // Usun spacje i inne znaki
    final cleaned = ean.replaceAll(RegExp(r'[^0-9]'), '');

    // Sprawdz dlugosc (EAN-8, UPC-A/EAN-12, EAN-13, GTIN-14)
    if (![8, 12, 13, 14].contains(cleaned.length)) {
      return false;
    }

    // Walidacja sumy kontrolnej Modulo 10
    return _validateChecksum(cleaned);
  }

  /// Normalizuje kod EAN do formatu EAN-13
  /// UPC-A (12 cyfr) -> EAN-13 (dodaje wiodace zero)
  /// Zwraca null jesli kod jest niepoprawny
  static String? normalize(String? ean) {
    if (ean == null || ean.isEmpty) return null;

    final cleaned = ean.replaceAll(RegExp(r'[^0-9]'), '');

    // UPC-A (12 cyfr) -> EAN-13
    if (cleaned.length == 12) {
      final normalized = '0$cleaned';
      return _validateChecksum(normalized) ? normalized : null;
    }

    // EAN-13, EAN-8
    if (cleaned.length == 13 || cleaned.length == 8) {
      return _validateChecksum(cleaned) ? cleaned : null;
    }

    return null;
  }

  /// Walidacja sumy kontrolnej algorytmem Modulo 10
  /// https://en.wikipedia.org/wiki/International_Article_Number#Check_digit
  static bool _validateChecksum(String code) {
    if (code.isEmpty) return false;

    int sum = 0;
    final length = code.length;

    for (int i = 0; i < length - 1; i++) {
      final digit = int.tryParse(code[i]);
      if (digit == null) return false;

      // Dla EAN-13: pozycje nieparzyste (od 0) * 1, parzyste * 3
      // Dla EAN-8: pozycje nieparzyste * 3, parzyste * 1
      final isOddPosition = (length - 1 - i) % 2 == 1;
      sum += digit * (isOddPosition ? 1 : 3);
    }

    final checkDigit = int.tryParse(code[length - 1]);
    if (checkDigit == null) return false;

    final calculatedCheck = (10 - (sum % 10)) % 10;
    return checkDigit == calculatedCheck;
  }

  /// Sprawdza czy kod zaczyna sie od 590 (polskie produkty farmaceutyczne)
  static bool isPolishPharmaceutical(String? ean) {
    final normalized = normalize(ean);
    return normalized != null && normalized.startsWith('590');
  }
}
