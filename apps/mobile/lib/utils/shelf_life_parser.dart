// shelf_life_parser.dart
// Parser dla okresów ważności po otwarciu (natural language → dni)

import 'package:logging/logging.dart';
import '../services/app_logger.dart';

/// Wynik parsowania okresu ważności
class ParsedShelfLife {
  final int? days;
  final String? error;

  ParsedShelfLife.success(this.days) : error = null;
  ParsedShelfLife.error(this.error) : days = null;

  bool get isValid => days != null;
}

/// Parser dla okresów ważności w języku naturalnym
class ShelfLifeParser {
  static final Logger _log = AppLogger.getLogger('ShelfLifeParser');

  /// Parsuje okres ważności z natural language do dni
  ///
  /// Obsługuje formaty:
  /// - "6 miesięcy", "6 miesiące", "6 miesiac" → 180 dni (6 * 30)
  /// - "30 dni", "30 dzień" → 30 dni
  /// - "2 tygodnie", "2 tydzień" → 14 dni (2 * 7)
  /// - "1 rok", "2 lata" → 365 dni, 730 dni
  /// - "24 godziny", "24h" → 1 dzień
  ///
  /// Zwraca null jeśli nie udało się sparsować
  static ParsedShelfLife parse(String text) {
    if (text.isEmpty) {
      return ParsedShelfLife.error('Pusty tekst');
    }

    final normalized = text.toLowerCase().trim();
    _log.fine('Parsing shelf life: "$normalized"');

    // Regex patterns dla różnych formatów
    // Pattern 1: "[liczba] [jednostka]" np. "6 miesięcy", "30 dni"
    final patterns = [
      // Miesiące - wszystkie polskie odmiany (miesiąc, miesiące, miesięcy, miesiąca)
      RegExp(r'(\d+)\s*miesi[ąę]c(?:e|y|a|ów)?', caseSensitive: false),
      // Dni - wszystkie odmiany (dni, dzień, dnia, dniach)
      RegExp(r'(\d+)\s*(?:dni|dzień|dnia|dniach)', caseSensitive: false),
      // Tygodnie (różne formy)
      RegExp(
        r'(\d+)\s*(?:tygodni(?:e|ów)?|tydzień|tygodnia)',
        caseSensitive: false,
      ),
      // Lata (różne formy)
      RegExp(r'(\d+)\s*(?:lat(?:a)?|rok(?:u)?)', caseSensitive: false),
      // Godziny - wszystkie odmiany (godzin, godziny, godzinę, godzina, h)
      RegExp(r'(\d+)\s*(?:godzin(?:y|ę|a)?|h)', caseSensitive: false),
    ];

    // Próbuj dopasować miesiące
    var match = patterns[0].firstMatch(normalized);
    if (match != null) {
      final months = int.tryParse(match.group(1)!);
      if (months != null) {
        final days = months * 30;
        _log.info('Parsed as months: $months → $days days');
        return ParsedShelfLife.success(days);
      }
    }

    // Próbuj dopasować dni
    match = patterns[1].firstMatch(normalized);
    if (match != null) {
      final days = int.tryParse(match.group(1)!);
      if (days != null) {
        _log.info('Parsed as days: $days');
        return ParsedShelfLife.success(days);
      }
    }

    // Próbuj dopasować tygodnie
    match = patterns[2].firstMatch(normalized);
    if (match != null) {
      final weeks = int.tryParse(match.group(1)!);
      if (weeks != null) {
        final days = weeks * 7;
        _log.info('Parsed as weeks: $weeks → $days days');
        return ParsedShelfLife.success(days);
      }
    }

    // Próbuj dopasować lata
    match = patterns[3].firstMatch(normalized);
    if (match != null) {
      final years = int.tryParse(match.group(1)!);
      if (years != null) {
        final days = years * 365;
        _log.info('Parsed as years: $years → $days days');
        return ParsedShelfLife.success(days);
      }
    }

    // Próbuj dopasować godziny
    match = patterns[4].firstMatch(normalized);
    if (match != null) {
      final hours = int.tryParse(match.group(1)!);
      if (hours != null) {
        final days = (hours / 24).ceil(); // Zaokrąglij w górę do pełnych dni
        _log.info('Parsed as hours: $hours → $days days');
        return ParsedShelfLife.success(days);
      }
    }

    // Nie udało się sparsować
    _log.warning('Failed to parse shelf life: "$text"');
    return ParsedShelfLife.error(
      'Nie rozpoznano formatu okresu. Spróbuj np. "6 miesięcy", "30 dni".',
    );
  }

  /// Sprawdza czy podana data otwarcia + okres ważności przekroczyły termin
  ///
  /// [openedDate] - data otwarcia w formacie ISO8601
  /// [shelfLifeDays] - okres ważności w dniach
  ///
  /// Zwraca true jeśli produkt po terminie
  static bool isExpired(String openedDate, int shelfLifeDays) {
    try {
      final opened = DateTime.parse(openedDate);
      final expiryDate = opened.add(Duration(days: shelfLifeDays));
      final now = DateTime.now();
      return now.isAfter(expiryDate);
    } catch (e) {
      _log.severe('Error checking expiry: $e');
      return false; // W razie błędu zakładamy że nie wygasło
    }
  }

  /// Zwraca datę wygaśnięcia (data otwarcia + okres ważności)
  ///
  /// [openedDate] - data otwarcia w formacie ISO8601
  /// [shelfLifeDays] - okres ważności w dniach
  ///
  /// Zwraca datę wygaśnięcia lub null w razie błędu
  static DateTime? getExpiryDate(String openedDate, int shelfLifeDays) {
    try {
      final opened = DateTime.parse(openedDate);
      return opened.add(Duration(days: shelfLifeDays));
    } catch (e) {
      _log.severe('Error calculating expiry date: $e');
      return null;
    }
  }

  /// Formatuje datę wygaśnięcia do formatu DD.MM.YYYY
  static String? formatExpiryDate(String openedDate, int shelfLifeDays) {
    final expiryDate = getExpiryDate(openedDate, shelfLifeDays);
    if (expiryDate == null) return null;

    return '${expiryDate.day.toString().padLeft(2, '0')}.${expiryDate.month.toString().padLeft(2, '0')}.${expiryDate.year}';
  }
}
