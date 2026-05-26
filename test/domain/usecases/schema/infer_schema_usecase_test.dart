import 'package:exlser/data/adapters/normalizers/boolean_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exlser/domain/usecases/schema/infer_schema_usecase.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/data/adapters/normalizers/number_normalizer.dart';
import 'package:exlser/data/adapters/normalizers/date_normalizer.dart';

void main() {
  late InferSchemaUseCase useCase;

  setUp(() {
    useCase = InferSchemaUseCase(
      numberNormalizer: NumberNormalizer(),
      dateNormalizer: DateNormalizer(),
      booleanNormalizer: BooleanNormalizer(),
    );
  });

  group("InferSchemaUseCase", () {
    test("should infer TEXT column", () {
      final rows = [
        ["name"],
        ["Alice"],
        ["Bob"],
        ["Charlie"]
      ];

      final result = useCase(rows, 1);

      expect(result.length, 1);
      expect(result.first.inferredType, ColumnType.text);
    });

    test("should infer INTEGER column", () {
      final rows = [
        ["quantity"],
        ["10"],
        ["5"],
        ["100"]
      ];

      final result = useCase(rows, 1);

      expect(result.first.inferredType, ColumnType.integer);
    });

    test("should infer REAL column", () {
      final rows = [
        ["price"],
        ["10.5"],
        ["3,25"],
        ["0.2"]
      ];

      final result = useCase(rows, 1);

      expect(result.first.inferredType, ColumnType.real);
    });

    test("should infer BOOLEAN column", () {
      final rows = [
        ["active"],
        ["true"],
        ["false"],
        ["TRUE"]
      ];

      final result = useCase(rows, 1);

      expect(result.first.inferredType, ColumnType.boolean);
    });

    test("should infer DATE column", () {
      final rows = [
        ["date"],
        ["2024-01-01"],
        ["2024-02-03"],
        ["2025-05-12"]
      ];

      final result = useCase(rows, 1);

      expect(result.first.inferredType, ColumnType.date);
    });

    test("should detect nullable columns", () {
      final rows = [
        ["price"],
        ["10"],
        [""],
        ["5"]
      ];

      final result = useCase(rows, 1);

      expect(result.first.nullable, true);
    });

    test("should fallback to TEXT when mixed types are found", () {
      final rows = [
        ["mixed"],
        ["10"],
        ["hello"],
        ["3.5"]
      ];

      final result = useCase(rows, 1);

      expect(result.first.inferredType, ColumnType.text);
    });

    test("should infer multiple columns correctly", () {
      final rows = [
        ["product", "price", "quantity", "date"],
        ["book", "10", "20", "2024-01-14"],
        ["pen", "2.23", "40", "2024-02-03"]
      ];

      final result = useCase(rows, 1);

      expect(result.length, 4);
      expect(result[0].inferredType, ColumnType.text);
      expect(result[1].inferredType, ColumnType.real);
      expect(result[2].inferredType, ColumnType.integer);
      expect(result[3].inferredType, ColumnType.date);
    });

    test("should sanitize column names", () {
      final rows = [
        ["Product Name"],
        ["book"],
        ["pen"]
      ];

      final result = useCase(rows, 1);

      expect(result.first.dbName, "product_name");
    });

    test("should rename 'Id' column to avoid conflict with primary key", () {
      final rows = [
        ["Id"],
        ["1"],
        ["2"],
      ];

      final result = useCase(rows, 1);

      expect(result.first.dbName, isNot("id"));
    });

    test("should deduplicate identical column headers", () {
      final rows = [
        ["value", "value", "value"],
        ["a", "b", "c"],
      ];

      final result = useCase(rows, 1);

      final dbNames = result.map((c) => c.dbName).toList();
      expect(dbNames.toSet().length, 3);
    });

    test("should handle empty column headers without crashing", () {
      final rows = [
        ["", "name", ""],
        ["1", "Alice", "x"],
      ];

      final result = useCase(rows, 1);

      expect(result.length, 3);
      final dbNames = result.map((c) => c.dbName).toList();
      expect(dbNames.toSet().length, 3);
    });
  });
}
