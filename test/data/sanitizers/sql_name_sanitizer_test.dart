import 'package:flutter_test/flutter_test.dart';
import 'package:exlser/data/adapters/sanitizers/sql_name_sanitizer.dart';

void main() {
  group("SqlNameSanitizer", () {
    test("should convert name to lowercase", () {
      final result = SqlNameSanitizer.sanitize("ProductName");
      expect(result, "productname");
    });

    test("should replace spaces with underscores", () {
      final result = SqlNameSanitizer.sanitize("Product Name");
      expect(result, "product_name");
    });

    test("should remove special characters", () {
      final result = SqlNameSanitizer.sanitize("Price (€)");
      expect(result, "price");
    });

    test("should collapse multiple underscores", () {
      final result = SqlNameSanitizer.sanitize("Product   Name");
      expect(result, "product_name");
    });

    test("should trim underscores from start and end", () {
      final result = SqlNameSanitizer.sanitize("  Product Name  ");
      expect(result, "product_name");
    });

    test("should handle reserved SQL keywords", () {
      final result = SqlNameSanitizer.sanitize("select");
      expect(result, "select_column");
    });

    test("should handle another SQL keyword", () {
      final result = SqlNameSanitizer.sanitize("order");
      expect(result, "order_column");
    });

    test("should return fallback name if result is empty", () {
      final result = SqlNameSanitizer.sanitize("!!!");
      expect(result, "column");
    });

    test("should handle mixed cases correctly", () {
      final result = SqlNameSanitizer.sanitize("Customer ID");
      expect(result, "customer_id");
    });

    test("should preserve numbers", () {
      final result = SqlNameSanitizer.sanitize("Column 1");
      expect(result, "column_1");
    });
  });
}
