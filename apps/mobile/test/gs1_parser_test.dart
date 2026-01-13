// gs1_parser_test.dart - Unit testy dla parsera GS1 Data Matrix
import 'package:flutter_test/flutter_test.dart';
import 'package:karton_z_lekami/utils/gs1_parser.dart';

void main() {
  group('Gs1Parser', () {
    group('parse()', () {
      test('parses GS1 with parentheses format', () {
        // Format z nawiasami (jak na zrzucie ekranu uzytkownika)
        const raw =
            '(01)05909990798346(17)280131(10)PAA24010A(21)36653543802628';
        final result = Gs1Parser.parse(raw);

        expect(result, isNotNull);
        expect(result!.isValid, isTrue);
        expect(result.ean, equals('5909990798346')); // EAN-13 (bez wiodacego 0)
        expect(result.gtin14, equals('05909990798346'));
        expect(result.expiryDate, equals('2028-01-31'));
        expect(result.batch, equals('PAA24010A'));
        expect(result.serial, equals('36653543802628'));
      });

      test('parses raw GS1 without parentheses', () {
        // Format surowy (jak z logow uzytkownika)
        const raw = '01059099907983461728013110PAA24010A2136653543802628';
        final result = Gs1Parser.parse(raw);

        expect(result, isNotNull);
        expect(result!.isValid, isTrue);
        expect(result.ean, equals('5909990798346'));
        expect(result.expiryDate, equals('2028-01-31'));
        expect(result.batch, equals('PAA24010A'));
        expect(result.serial, equals('36653543802628'));
      });

      test('parses GS1 with GS separator', () {
        // Format z separatorem ASCII 29
        const raw = '0105909990798346\u001D17280131\u001D10PAA24010A';
        final result = Gs1Parser.parse(raw);

        expect(result, isNotNull);
        expect(result!.ean, equals('5909990798346'));
        expect(result.expiryDate, equals('2028-01-31'));
        expect(result.batch, equals('PAA24010A'));
      });

      test('parses GS1 with only GTIN (no expiry)', () {
        const raw = '0105909990798346';
        final result = Gs1Parser.parse(raw);

        expect(result, isNotNull);
        expect(result!.isValid, isTrue);
        expect(result.ean, equals('5909990798346'));
        expect(result.hasExpiryDate, isFalse);
      });

      test('handles day 00 as end of month', () {
        // DD=00 oznacza ostatni dzien miesiaca (standard GS1)
        const raw = '(01)05909990798346(17)280200'; // luty 2028
        final result = Gs1Parser.parse(raw);

        expect(result, isNotNull);
        expect(
          result!.expiryDate,
          equals('2028-02-29'),
        ); // 2028 jest rokiem przestepnym
      });

      test('returns null for regular EAN-13', () {
        const ean = '5909990798346';
        final result = Gs1Parser.parse(ean);

        // Nie zaczyna sie od AI 01, wiec nie jest to GS1
        expect(result, isNull);
      });

      test('returns null for empty string', () {
        expect(Gs1Parser.parse(''), isNull);
      });

      test('returns null for invalid GTIN length', () {
        const raw = '01123456789'; // Za krotki GTIN
        final result = Gs1Parser.parse(raw);

        expect(result, isNull);
      });
    });

    group('mightBeGs1()', () {
      test('returns true for GS1 with parentheses', () {
        expect(Gs1Parser.mightBeGs1('(01)05909990798346'), isTrue);
      });

      test('returns true for raw GS1', () {
        expect(Gs1Parser.mightBeGs1('0105909990798346'), isTrue);
      });

      test('returns false for short strings', () {
        expect(Gs1Parser.mightBeGs1('5909990798346'), isFalse);
      });
    });
  });
}
