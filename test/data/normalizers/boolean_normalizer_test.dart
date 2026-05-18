import 'package:exel_category/data/adapters/normalizers/boolean_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BooleanNormalizer', () {
    late BooleanNormalizer normalizer;

    setUp(() {
      normalizer = BooleanNormalizer();
    });

    test(
      'should parse true values correctly',
      () {
        expect(normalizer.tryNormalize("true"), true);
        expect(normalizer.tryNormalize("TRUE"), true);
        expect(normalizer.tryNormalize("True"), true);

        expect(normalizer.tryNormalize("1"), true);
        expect(normalizer.tryNormalize("yes"), true);
        expect(normalizer.tryNormalize("YES"), true);
      },
    );

    test(
      'should parse false values correctly',
      () {
        expect(normalizer.tryNormalize("false"), false);
        expect(normalizer.tryNormalize("FALSE"), false);

        expect(normalizer.tryNormalize("0"), false);
        expect(normalizer.tryNormalize("no"), false);
        expect(normalizer.tryNormalize("NO"), false);
      },
    );

    test(
      'should return null for non boolean values',
      () {
        expect(normalizer.tryNormalize("book"), null);
        expect(normalizer.tryNormalize("10"), null);
        expect(normalizer.tryNormalize("maybe"), null);
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
