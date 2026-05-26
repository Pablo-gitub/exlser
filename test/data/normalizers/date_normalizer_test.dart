import 'package:flutter_test/flutter_test.dart';
import 'package:exlser/data/adapters/normalizers/date_normalizer.dart';

void main() {
  group('DateNormalizer', () {
    late DateNormalizer normalizer;

    setUp(() {
      normalizer = DateNormalizer();
    });

    test(
      'should parse ISO date format',
      () {
        final result = normalizer.tryNormalize("2024-01-14");

        expect(result, isA<DateTime>());
        expect(result!.year, 2024);
        expect(result.month, 1);
        expect(result.day, 14);
      },
    );

    test(
      'should parse ISO datetime format',
      () {
        final result = normalizer.tryNormalize("2024-01-14 10:30:00");

        expect(result, isA<DateTime>());
        expect(result!.year, 2024);
        expect(result.month, 1);
        expect(result.day, 14);
      },
    );

    test(
      'should parse european date format (dd/MM/yyyy)',
      () {
        final result = normalizer.tryNormalize("14/01/2024");

        expect(result, isA<DateTime>());
        expect(result!.day, 14);
        expect(result.month, 1);
        expect(result.year, 2024);
      },
    );

    test(
      'should parse alternative european dates',
      () {
        expect(normalizer.tryNormalize("01/12/2024"), isA<DateTime>());
        expect(normalizer.tryNormalize("31/05/2025"), isA<DateTime>());
      },
    );

    test(
      'should return null for non date values',
      () {
        expect(normalizer.tryNormalize("book"), null);
        expect(normalizer.tryNormalize("123abc"), null);
        expect(normalizer.tryNormalize("price"), null);
      },
    );

    test(
      'should return null for empty values',
      () {
        expect(normalizer.tryNormalize(""), null);
        expect(normalizer.tryNormalize(" "), null);
      },
    );
  });
}
