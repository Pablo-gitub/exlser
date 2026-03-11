import 'package:flutter_test/flutter_test.dart';
import 'package:exel_category/data/adapters/normalizers/number_normalizer.dart';

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

  });
}