### **Refactoring Plan – Phase 2: Data-Driven Architecture (English Draft)**

---

[Readme](README.md)

[Piano di Refattorizzazione](REFACTORING_PLAN.it.md)

---

# Overview

ExcelCategory is transitioning from:

> In-memory Excel filtering utility

to:

> Persistent, relational, data-driven processing engine.

The first refactoring introduced Clean Architecture.
The second refactoring introduces a persistent relational core using Drift (SQLite).

---

# Phase 1 (Completed)

- Clean Architecture foundation
- Domain layer isolation
- Repository abstraction
- UseCase layer
- BLoC-based presentation
- Unit tests for domain logic

Limitations:
- Data still stored in memory
- Filtering not scalable for large datasets
- No dataset persistence
- No typed schema inference

---

# Phase 2 (In Progress)

## 🎯 Objective

Transform ExcelCategory into a data-persistent analytical tool.

---

## 1️⃣ Introduce Drift Database Layer

```

core/database/
├── app_database.dart
├── connection/
├── tables/
├── daos/

```

### New Core Tables

- datasets
- dataset_tables
- dataset_columns
- dynamic sheet tables

---

## 2️⃣ Schema Inference Engine

- Read first N rows (e.g. 200)
- Infer column types
- Ask user confirmation
- Create relational table
- Populate data

Supported types:
- TEXT
- INTEGER
- REAL
- DATE
- BOOLEAN

---

## 3️⃣ Replace In-Memory Filtering

Old:
```

List<ExcelDataEntity> filtering

```

New:
```

SQL WHERE clause filtering

```

Benefits:
- Massive performance improvement
- Proper numeric/date range filters
- Scalable to large datasets

---

## 4️⃣ Dataset Persistence

Each dataset session will store:

- Source file name
- File hash
- UI state
- Table metadata
- Column metadata

Allows:
- Reopening previous sessions
- Cross-dataset comparison
- Historical analysis

---

## 5️⃣ Future Extensions

- Aggregations (GROUP BY)
- Statistics engine
- Regression models (TensorFlow Lite)
- Rust-based compute modules
- Multi-dataset diff engine

---

# Architectural Direction

The system will evolve into:

Excel → Schema Mapper → Drift Database → Query Engine → UI

---

# Long-Term Vision

ExcelCategory becomes:

- Lightweight BI tool
- Local data analytics platform
- Architectural showcase project

---

# Branch Strategy

Current branch:
```

refactor/architectural_refactoring

```


---

# Technical Debt To Address

- CI triggers on every push
- Release strategy refinement
- Formula evaluation handling
- Typed UI filters

---

# End Goal

Not just a Flutter app.

A serious, structured, extensible data tool.
