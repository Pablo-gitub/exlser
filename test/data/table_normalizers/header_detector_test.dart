import 'package:flutter_test/flutter_test.dart';
import 'package:exel_category/data/adapters/table_normalizers/header_detector.dart';

void main() {
  group("HeaderDetector", () {

    test("should detect header when no empty rows exist", () {
      final rows = [
        ["name","age"],
        ["Alice","30"],
        ["Bob","40"]
      ];

      final result = HeaderDetector.detect(rows);

      expect(result.first, ["name","age"]);
      expect(result.length, 3);
    });

    test("should skip empty rows before header", () {
      final rows = [
        ["",""],
        ["",""],
        ["name","age"],
        ["Alice","30"]
      ];

      final result = HeaderDetector.detect(rows);

      expect(result.first, ["name","age"]);
      expect(result.length, 2);
    });

    test("should handle rows containing whitespace", () {
      final rows = [
        ["  "," "],
        ["",""],
        ["product","price"],
        ["book","10"]
      ];

      final result = HeaderDetector.detect(rows);

      expect(result.first, ["product","price"]);
    });

    test("should throw if file is completely empty", () {
      final rows = <List<String>>[];

      expect(
        () => HeaderDetector.detect(rows),
        throwsException,
      );
    });

    test("should throw if no header row exists", () {
      final rows = [
        ["",""],
        ["",""]
      ];

      expect(
        () => HeaderDetector.detect(rows),
        throwsException,
      );
    });

  });
}