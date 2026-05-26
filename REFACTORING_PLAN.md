### **Refactoring Plan – Phase 1 & 2: Architectural History**

---

[Readme](README.md) · [Piano di Refattorizzazione](REFACTORING_PLAN.it.md)

---

# Overview

Exlser evolved in two distinct architectural phases:

**Phase 1** transformed a simple in-memory Excel filter into a Clean Architecture codebase.

**Phase 2** replaced all in-memory data handling with a relational persistence core built on Drift (SQLite).

Both phases are complete. This document records the decisions made, the constraints they addressed, and the technical debt that remains.

---

# Phase 1 (Completed)

**Goal:** introduce architectural discipline into a growing Flutter app.

Changes introduced:
- Clean Architecture layer separation (`core`, `domain`, `data`, `application`, `presentation`)
- Domain layer isolation (entities, repository interfaces, value objects)
- Use case layer for all business operations
- Repository abstraction (domain depends on interfaces, not implementations)
- Hybrid Riverpod/BLoC presentation layer
- Unit tests for domain logic

Limitations resolved by Phase 2:
- Data was still stored in memory — no persistence between sessions
- Filtering was not scalable beyond small datasets
- No typed schema inference
- No dataset management

---

# Phase 2 (Completed)

**Goal:** replace all in-memory data handling with a local relational persistence layer.

## Presentation State Management

Phase 2 solidified the split state-management strategy:

- **Riverpod** handles app-level dependency providers, routing, settings, lightweight ViewModels, and temporary UI workflows such as the import wizard.
- **BLoC** handles the dataset workspace, where interactions are event-driven and stateful: dataset loading, active sheet, filters, sorting, row fetching, refresh events, view mode, and analytics.

This keeps the import flow simple while giving the dataset workspace a stronger event/state model as it grows.

---

## 1️⃣ Drift Database Layer

```
core/database/
├── app_database.dart
├── connection/
├── tables/
├── daos/
```

Core tables introduced:
- `datasets` — dataset metadata (name, source file, created_at, ui_state)
- `dataset_tables` — sheet metadata (original name, SQL-safe name, row count)
- `dataset_columns` — column schema (original name, DB name, type, nullable, stats)
- `dataset_files` — file references (path, storage mode)

Each imported sheet also generates its own dynamic SQL table at runtime.

---

## 2️⃣ Schema Inference Engine

Process:
1. Read first N rows (200) from the imported file
2. Infer column type per column (TEXT, INTEGER, REAL, DATE, BOOLEAN)
3. Detect nullability
4. Present inferred schema to user for review and correction
5. On confirmation: create relational table and populate rows

Types supported: TEXT, INTEGER, REAL, DATE, BOOLEAN.

---

## 3️⃣ SQL-Based Filtering

Before Phase 2:
```
Filtering on List<Entity> in memory
```

After Phase 2:
```
SQL WHERE clause generation from typed FilterCondition objects
```

Benefits:
- Scalable to large datasets
- Type-correct numeric and date range filters
- 16+ operators, each mapped to a SQL fragment
- Filters serialised to JSON and persisted per sheet

---

## 4️⃣ Dataset Persistence

Each dataset session stores:
- Source file name and file reference
- UI state (filters, sort, hidden columns) as JSON per sheet
- Table and column metadata
- All data rows in dynamic SQL tables

Enables:
- Reopening previous sessions without re-importing
- Foundation for cross-dataset comparison
- Historical filter state restoration

---

## 5️⃣ Future Extensions

- Cross-sheet and multi-dataset aggregations (v0.5.0)
- Full statistical summaries and advanced analytics
- Regression and forecast models
- Multi-dataset diff engine

---

# Architectural Flow

```
File (CSV/XLSX)
  → Parser (SpreadsheetParser / ParserFactory)
  → Schema inference (PreparedImportResult)
  → User confirmation (ConfirmedImport)
  → CreateDatasetService (Drift: tables + columns + rows)
  → QueryRepository (SELECT / filter / sort / paginate)
  → BLoC workspace state
  → UI
```

---

# Branch Strategy

Both refactoring phases landed on `main`.
All current development happens on `main` or feature branches merged into `main`.

---

# Technical Debt

| Item | Status |
|---|---|
| CI triggers on every push (not only on tags) | Open — CI refactor planned |
| Formula evaluation in Excel cells not handled | Open |
| Web file references are temporary (no persistent path) | By design — WASM constraint |
| Multi-file batch import | Not yet implemented (v0.5.0+) |
| Settings screen mostly placeholder | Planned for v0.6.0 |

---

# End Goal

Not just a Flutter app.

A structured, extensible, locally-persistent data analysis tool — and a public demonstration of how Clean Architecture scales in a real Flutter project.
