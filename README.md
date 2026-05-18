# ExlSer

[Refactoring Plan](REFACTORING_PLAN.md)

ExlSer is a cross-platform CSV and Excel dataset workspace built with Flutter.

Originally designed as a simple Excel filtering utility, the project is now evolving into a structured, scalable data-processing engine with local relational persistence and a Clean Architecture foundation.

The goal is to transform it from a basic filtering app into a robust, extensible data analysis tool.

---

## 🚀 Vision

ExlSer is transitioning toward:

- Clean Architecture (Domain-driven structure)
- Local relational persistence using Drift (SQLite)
- Schema inference from Excel sheets
- Scalable filtering engine
- Multi-dataset management
- Future AI/analytics extensibility

This project serves both as:
- A production-ready tool
- A public architectural showcase

---

## 🌍 Supported Platforms

- Android
- iOS
- macOS
- Windows
- Linux
- Web (SQLite WASM)

---

## 🏗 Architecture

The project follows Clean Architecture principles:

```

lib/
├── core/
│   ├── database/        # Drift database layer
│   ├── errors/
│   └── usecases/
├── features/
│   └── excel/
│       ├── data/
│       ├── domain/
│       └── presentation/

```

### Layers

- **Domain** → Pure business logic (Entities, Repositories, UseCases)
- **Application** → Import and dataset orchestration services
- **Data** → Drift database, datasources, repository implementations
- **Presentation** → UI, Riverpod providers/ViewModels, and BLoC workspace state
- **Core** → Shared infrastructure

### State Management

The presentation layer uses a hybrid state-management strategy:

- **Riverpod** is used for dependency wiring, lightweight UI ViewModels, routing, settings, and temporary workflow state such as the import wizard.
- **BLoC** is reserved for the dataset workspace, where state is event-driven and expected to grow: loaded dataset, active sheet, filters, sorting, rows, refresh events, view mode, and future analytics interactions.

In short:

```text
Riverpod = UI orchestration and temporary state
BLoC = dataset interaction engine and event-driven workspace state
```

Current import-flow providers live under:

```text
lib/presentation/providers/
```

### Analytics Direction

Future analytics will follow a guided auto-BI approach. After schema
confirmation, the dataset workspace will inspect column types and suggest an
initial chart automatically:

- `date` + numeric columns -> line or area chart.
- `text` + numeric columns -> pie/donut for small category sets, bar/column for
  larger category sets.
- two numeric columns -> scatter plot.
- boolean columns -> true/false distribution.

The chart panel will expose dropdown controls for alternative columns,
aggregations, chart type, grouping, sorting, and top-N limits. More advanced
regression and forecast views are planned after the first basic charting
release.

---

## 🧠 Current Refactoring Status

The project is under active architectural refactoring on:

```

refactor/architectural_refactoring

```

Major ongoing upgrade:
- Migration from in-memory filtering to relational persistence
- Introduction of dataset/session management
- Typed schema inference

---

## 🛠 Development

### Requirements

- Flutter SDK compatible with Dart `^3.5.3`
- A configured Flutter target platform for the build you want to verify
- Xcode for iOS/macOS builds
- Android Studio or Android SDK tooling for Android builds

### Install dependencies
```bash
flutter pub get
```

### Generate Drift files

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run the app

```bash
flutter run
```

Useful targets:

```bash
flutter run -d chrome
flutter run -d macos
```

### Analyze

```bash
flutter analyze
```

---

## 🧪 Testing

Run the full test suite:

```bash
flutter test
```

Run focused checks:

```bash
flutter test test/application/service/import_create_open_smoke_test.dart
flutter test test/presentation/views/home/home_import_widget_test.dart
```

---

## 📦 Build

Web preview build:

```bash
flutter build web --release
```

macOS preview build:

```bash
flutter build macos --release
```

Android preview build:

```bash
flutter build apk --release
```

The first public preview target is `v0.1.0`.

---

## v0.1.0 Preview Scope

The first publishable preview focuses on the local import workflow:

- select a CSV or XLSX file
- inspect inferred sheets and columns
- correct column types before persistence
- create a local dataset
- see created datasets in the Works list
- open a dataset in a read-only workspace
- read imported rows in a table
- delete a dataset together with schema, rows, and file reference

Not included in `v0.1.0`:

- filtering and sorting
- export
- analytics and automatic charts
- cross-sheet or multi-dataset analysis

Those features are tracked in [ROADMAP.md](ROADMAP.md).

---

## 📦 CI/CD

Current GitHub Actions:

* Desktop builds
* Mobile builds
* Release artifacts

⚠️ CI will be refactored to trigger releases only on tagged versions.

---

## 🔮 Roadmap

* [ ] Complete Drift integration
* [ ] Replace in-memory filtering with SQL filtering
* [ ] Dataset persistence system
* [ ] Typed filter UI (date ranges, numeric ranges)
* [ ] Multi-dataset comparison
* [ ] Statistical summaries
* [ ] Future ML-based analytics module

---

## 🎯 Purpose

This project demonstrates:

* Clean Architecture in Flutter
* Multi-platform SQLite integration
* Test-Driven Development
* CI/CD setup for Flutter
* Real-world architectural evolution

---

## 📄 License

Open-source project.
