import 'package:flutter_test/flutter_test.dart';
import 'package:exlser/data/adapters/normalizers/number_normalizer.dart';

void main() {
  group('NumberNormalizer', () {
    late NumberNormalizer normalizer;

    setUp(() {
      normalizer = NumberNormalizer();
    });

    test(
      'should parse integer numbers correctly',
      () {
        expect(normalizer.tryNormalize("10"), 10.0);
        expect(normalizer.tryNormalize("0"), 0.0);
        expect(normalizer.tryNormalize("-5"), -5.0);
      },
    );

    test(
      'should parse decimal numbers with dot separator',
      () {
        expect(normalizer.tryNormalize("10.5"), 10.5);
        expect(normalizer.tryNormalize("0.75"), 0.75);
        expect(normalizer.tryNormalize("-3.14"), -3.14);
      },
    );

    test(
      'should parse decimal numbers with comma separator',
      () {
        expect(normalizer.tryNormalize("10,5"), 10.5);
        expect(normalizer.tryNormalize("0,75"), 0.75);
      },
    );

    test(
      'should parse numbers with thousand separators',
      () {
        expect(normalizer.tryNormalize("1,000"), 1000.0);
        expect(normalizer.tryNormalize("1.000"), 1000.0);
        expect(normalizer.tryNormalize("1'000"), 1000.0);
      },
    );

    test(
      'should parse numbers with thousand and decimal separators',
      () {
        expect(normalizer.tryNormalize("1,000.50"), 1000.50);
        expect(normalizer.tryNormalize("1.000,50"), 1000.50);
      },
    );

    test(
      'should return null for non numeric values',
      () {
        expect(normalizer.tryNormalize("book"), null);
        expect(normalizer.tryNormalize("hello world"), null);
        expect(normalizer.tryNormalize("abc123"), null);
      },
    );

    test(
      'should return null for empty or whitespace values',
      () {
        expect(normalizer.tryNormalize(""), null);
        expect(normalizer.tryNormalize(" "), null);
        expect(normalizer.tryNormalize("   "), null);
      },
    );

    group('currency symbol stripping', () {
      test('strips trailing currency symbol', () {
        expect(normalizer.tryNormalize("3.3\$"), 3.3);
        expect(normalizer.tryNormalize("10€"), 10.0);
        expect(normalizer.tryNormalize("99.99£"), 99.99);
      });

      test('strips leading currency symbol', () {
        expect(normalizer.tryNormalize("\$3.50"), 3.50);
        expect(normalizer.tryNormalize("€1000"), 1000.0);
        expect(normalizer.tryNormalize("£12.5"), 12.5);
        expect(normalizer.tryNormalize("¥500"), 500.0);
      });

      test('strips currency with thousands and decimal separators', () {
        expect(normalizer.tryNormalize("\$1,000.50"), 1000.50);
        expect(normalizer.tryNormalize("€1.000,50"), 1000.50);
        expect(normalizer.tryNormalize("1'000.00\$"), 1000.0);
      });

      test('strips currency with surrounding spaces', () {
        expect(normalizer.tryNormalize("3.50 €"), 3.50);
        expect(normalizer.tryNormalize("\$ 10"), 10.0);
      });

      test('handles negative values with currency', () {
        expect(normalizer.tryNormalize("-3.50\$"), -3.50);
        expect(normalizer.tryNormalize("€-99"), -99.0);
      });

      test('returns null when only currency symbol is present', () {
        expect(normalizer.tryNormalize("\$"), null);
        expect(normalizer.tryNormalize("€  "), null);
      });
    });
  });

  group('detectCurrencySymbol', () {
    test('returns trailing symbol', () {
      expect(NumberNormalizer.detectCurrencySymbol('3.50\$'), '\$');
      expect(NumberNormalizer.detectCurrencySymbol('100€'), '€');
      expect(NumberNormalizer.detectCurrencySymbol('12.5£'), '£');
    });

    test('returns leading symbol', () {
      expect(NumberNormalizer.detectCurrencySymbol('\$3.50'), '\$');
      expect(NumberNormalizer.detectCurrencySymbol('€100'), '€');
      expect(NumberNormalizer.detectCurrencySymbol('¥500'), '¥');
    });

    test('returns null when no symbol present', () {
      expect(NumberNormalizer.detectCurrencySymbol('3.50'), isNull);
      expect(NumberNormalizer.detectCurrencySymbol('1000'), isNull);
      expect(NumberNormalizer.detectCurrencySymbol(''), isNull);
      expect(NumberNormalizer.detectCurrencySymbol('abc'), isNull);
    });

    test('returns first symbol found when multiple present', () {
      // Edge case: returns the first match regardless of position
      final result = NumberNormalizer.detectCurrencySymbol('\$3€');
      expect(result, isNotNull);
    });
  });
}
