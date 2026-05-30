import 'package:flutter_test/flutter_test.dart';
import 'package:exlser/data/adapters/normalizers/date_normalizer.dart';

void main() {
  group('DateNormalizer', () {
    late DateNormalizer normalizer;

    setUp(() {
      normalizer = DateNormalizer();
    });

    // ── ISO formats ──────────────────────────────────────────────────────────

    test('parses ISO date (YYYY-MM-DD)', () {
      final r = normalizer.tryNormalize('2024-01-14');
      expect(r, isNotNull);
      expect(r!.year, 2024);
      expect(r.month, 1);
      expect(r.day, 14);
    });

    test('parses ISO datetime (YYYY-MM-DD HH:mm:ss)', () {
      final r = normalizer.tryNormalize('2024-01-14 10:30:00');
      expect(r, isNotNull);
      expect(r!.year, 2024);
      expect(r.month, 1);
      expect(r.day, 14);
    });

    test('parses ISO datetime with T separator', () {
      final r = normalizer.tryNormalize('2024-06-15T08:00:00');
      expect(r, isNotNull);
      expect(r!.year, 2024);
      expect(r.month, 6);
      expect(r.day, 15);
    });

    // ── Slash-separated ───────────────────────────────────────────────────────

    test('parses DD/MM/YYYY (European slash format)', () {
      final r = normalizer.tryNormalize('14/01/2024');
      expect(r, isNotNull);
      expect(r!.day, 14);
      expect(r.month, 1);
      expect(r.year, 2024);
    });

    test('parses DD/MM/YYYY from a real spreadsheet export', () {
      expect(normalizer.tryNormalize('15/10/2017')?.year, 2017);
      expect(normalizer.tryNormalize('15/10/2017')?.month, 10);
      expect(normalizer.tryNormalize('15/10/2017')?.day, 15);
      expect(normalizer.tryNormalize('16/08/2016')?.month, 8);
      expect(normalizer.tryNormalize('21/05/2015')?.month, 5);
    });

    test('parses YYYY/MM/DD (year-first slash format)', () {
      final r = normalizer.tryNormalize('2024/01/14');
      expect(r, isNotNull);
      expect(r!.year, 2024);
      expect(r.month, 1);
      expect(r.day, 14);
    });

    // ── Dot-separated ─────────────────────────────────────────────────────────

    test('parses DD.MM.YYYY (European dot format)', () {
      final r = normalizer.tryNormalize('14.01.2024');
      expect(r, isNotNull);
      expect(r!.day, 14);
      expect(r.month, 1);
      expect(r.year, 2024);
    });

    test('parses YYYY.MM.DD (year-first dot format)', () {
      final r = normalizer.tryNormalize('2024.01.14');
      expect(r, isNotNull);
      expect(r!.year, 2024);
      expect(r.month, 1);
      expect(r.day, 14);
    });

    test('does not confuse a 2-part float (3.14) with a date', () {
      expect(normalizer.tryNormalize('3.14'), isNull);
    });

    // ── Hyphen-separated non-ISO ───────────────────────────────────────────────

    test('parses DD-MM-YYYY (non-ISO hyphen format)', () {
      final r = normalizer.tryNormalize('14-01-2024');
      expect(r, isNotNull);
      expect(r!.day, 14);
      expect(r.month, 1);
      expect(r.year, 2024);
    });

    // ── Invalid / null cases ──────────────────────────────────────────────────

    test('returns null for non-date strings', () {
      expect(normalizer.tryNormalize('book'), isNull);
      expect(normalizer.tryNormalize('123abc'), isNull);
      expect(normalizer.tryNormalize('price'), isNull);
    });

    test('returns null for empty or blank values', () {
      expect(normalizer.tryNormalize(''), isNull);
      expect(normalizer.tryNormalize(' '), isNull);
    });

    test('returns null for out-of-range date parts', () {
      expect(normalizer.tryNormalize('99/99/2024'), isNull);
      expect(normalizer.tryNormalize('14/13/2024'), isNull);
    });
  });
}
