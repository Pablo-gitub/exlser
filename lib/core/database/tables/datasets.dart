import 'package:drift/drift.dart';

/// Represents a logical work session created by importing an Excel file.
/// A dataset can contain one or more sheet tables.
class Datasets extends Table {
  /// Primary key (auto increment)
  IntColumn get id => integer().autoIncrement()();

  /// Human readable name (e.g. "Import 2026-03-04 - Suppliers")
  TextColumn get name => text()();

  /// Original file name imported by the user
  TextColumn get sourceFileName => text()();

  /// Optional file hash (useful to detect re-import of same file)
  TextColumn get sourceFileHash => text().nullable()();

  /// Unix timestamp (milliseconds) when the dataset was created
  IntColumn get createdAt => integer()();

  /// Unix timestamp (milliseconds) when last opened
  IntColumn get lastOpenedAt => integer().nullable()();

  /// Serialized UI state (filters, sorting, visible columns, etc.)
  TextColumn get uiStateJson => text().nullable()();
}