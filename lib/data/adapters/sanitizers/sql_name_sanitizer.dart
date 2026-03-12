/// Utility responsible for converting arbitrary column names
/// into SQL-safe identifiers.
///
/// This sanitizer ensures that column names:
///
/// - are lowercase
/// - contain only letters, numbers and underscores
/// - do not start or end with underscores
/// - do not contain consecutive underscores
/// - do not collide with SQL reserved keywords
///
/// Example transformations:
///
/// "Product Name"   -> "product_name"
/// "Price (€)"      -> "price"
/// "Customer ID"    -> "customer_id"
/// "select"         -> "select_column"
///
class SqlNameSanitizer {

  /// List of common SQL reserved keywords.
  static const _reservedWords = {
    "select",
    "from",
    "where",
    "order",
    "group",
    "by",
    "insert",
    "update",
    "delete",
    "table",
    "join",
    "and",
    "or",
    "not",
    "null",
    "create",
    "drop"
  };

  /// Converts an arbitrary string into a SQL-safe identifier.
  static String sanitize(String input) {

    var name = input.toLowerCase();

    /// Replace spaces with underscores
    name = name.replaceAll(RegExp(r"\s+"), "_");

    /// Remove characters that are not letters, numbers or underscore
    name = name.replaceAll(RegExp(r"[^a-z0-9_]"), "");

    /// Collapse multiple underscores
    name = name.replaceAll(RegExp(r"_+"), "_");

    /// Trim underscores from start and end
    name = name.replaceAll(RegExp(r"^_+|_+$"), "");

    /// Fallback if empty
    if (name.isEmpty) {
      name = "column";
    }

    /// Avoid SQL reserved keywords
    if (_reservedWords.contains(name)) {
      name = "${name}_column";
    }

    return name;
  }

}