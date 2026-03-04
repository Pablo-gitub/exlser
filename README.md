# ExcelCategory

[Refactoring Plan](REFACTORING_PLAN.md)

ExcelCategory is a cross-platform data processing tool built with Flutter.

Originally designed as a simple Excel filtering utility, the project is now evolving into a structured, scalable data-processing engine with local relational persistence and a Clean Architecture foundation.

The goal is to transform it from a basic filtering app into a robust, extensible data analysis tool.

---

## 🚀 Vision

ExcelCategory is transitioning toward:

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
- **Data** → Drift database, datasources, repository implementations
- **Presentation** → BLoC / UI
- **Core** → Shared infrastructure

---

## 🧠 Current Refactoring Status

The project is under active architectural refactoring on:

```

refactor/architectural_refactoring

````

Major ongoing upgrade:
- Migration from in-memory filtering to relational persistence
- Introduction of dataset/session management
- Typed schema inference

---

## 🛠 Development

### Install dependencies
```bash
flutter pub get
````

### Generate Drift files

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run the app

```bash
flutter run
```

---

## 🧪 Testing

Domain layer is fully unit-tested.

```bash
flutter test
```

Future additions:

* DAO tests
* Integration tests
* Widget tests

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

