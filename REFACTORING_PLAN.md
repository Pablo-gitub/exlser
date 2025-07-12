### **REFACTORING\_PLAN.md (English Draft)**

[Readme](README.md)

[Piano di Refattorizzazione](REFACTORING_PLAN.it.md)
# Refactoring Plan for Excel Category Application

This document outlines the refactoring plan for the Flutter application "Excel Category," aiming to transform the current architecture (MVC + basic Riverpod) into a more robust, maintainable, and scalable solution, based on **Clean Architecture**, **MVVM (Model-View-ViewModel)**, **SOLID principles**, and the adoption of **Test-Driven Development (TDD)**.

## 1\. Current State and Motivation for Refactoring

The current application is functional and allows reading, filtering, and exporting data from Excel files. However, like many initial projects, the architecture presents some limitations:

  * **High Coupling:** Components from different layers (e.g., UI, Controller, Provider) are tightly interconnected, making it difficult to modify or replace one component without significantly impacting others.
  * **Difficulty in Testability:** Business logic is intertwined with framework details (Flutter, Riverpod) and I/O operations, making it challenging to write isolated and reliable unit tests. The current lack of a test suite poses a significant risk for future modifications.
  * **Violations of SOLID Principles:** Violations of the Single Responsibility Principle (SRP) and the Dependency Inversion Principle (DIP) are present, leading to classes with too many responsibilities and dependencies on concrete implementations rather than abstractions.
  * **Excel Formula Reading Issue:** The current Excel parsing library does not evaluate formulas, resulting in empty values. Refactoring will allow isolating and resolving this issue cleanly.

The refactoring is motivated by the desire to enhance the application's **maintainability**, **scalability**, **testability**, and **robustness**, transforming it into an example of high-quality software development.

## 2\. Target Architecture: Clean Architecture (MVVM with Flutter BLoC and Flutter Riverpod)

The adopted architecture will follow the principles of Clean Architecture, dividing the application into well-defined layers:

```
lib/
├── main.dart
├── core/                   // Cross-cutting and shared elements (Errors, Base Use Cases, Utilities)
├── di_container.dart       // Dependency Injection configuration with Riverpod
└── features/               // Autonomous modules/features
    └── excel_processing/   // Our specific feature (Excel Processing)
        ├── data/           // Concrete Repository and Data Source implementations
        │   ├── datasources/
        │   └── repositories/
        ├── domain/         // The core of pure business logic (Entities, Repository Interfaces, Use Cases)
        │   ├── entities/
        │   ├── repositories/
        │   └── usecases/
        └── presentation/   // UI and state management (BLoC, Pages, Widgets)
            ├── bloc/       // <-- Here we will use Flutter BLoC
            ├── pages/
            └── widgets/
```

### Principles and Patterns Applied:

  * **Clean Architecture:**

      * **Framework Independence:** The Domain Layer will be completely agnostic to Flutter or any external libraries.
      * **Testability:** Each layer will have clear responsibilities, facilitating isolated unit tests.
      * **Separation of Concerns:** Each layer addresses a single "concern."
      * **Unidirectional Dependency:** Outer layers depend on inner layers, never the other way around.

  * **MVVM (Model-View-ViewModel) in the Presentation Layer:**

      * **View (`pages/`, `widgets/`):** Flutter widgets responsible for displaying and interacting with the user. They observe the `ViewModel` (represented by **BLoCs**) and dispatch events.
      * **ViewModel (`bloc/excel_bloc.dart`):** The **BLoCs** will act as ViewModels, exposing UI state and managing presentation logic, orchestrating calls to `Use Cases` from the Domain Layer.

  * **SOLID Principles:**

      * **Single Responsibility Principle (SRP):** Each class/module will have only one reason to change. Examples: `ExcelDataEntity` solely for data representation; `ReadExcelFileUseCase` solely for reading the file; `ExcelLocalDatasource` solely for direct interaction with the Excel library.
      * **Open/Closed Principle (OCP):** Entities and modules will be open for extension but closed for modification. For example, adding a new export type should not modify existing `Use Cases`, but rather extend `FileExportRepository` with a new implementation.
      * **Liskov Substitution Principle (LSP):** Objects of a superclass can be replaced with objects of subclasses without altering the correctness of the program. (Less evident in this refactoring, but a guiding principle).
      * **Interface Segregation Principle (ISP):** Clients will not be forced to depend on interfaces they do not use. Domain Layer repositories will have precise interfaces for the operations they require.
      * **Dependency Inversion Principle (DIP):** High-level modules (e.g., `Use Cases`) will not depend on low-level modules (e.g., concrete repository implementations), but on abstractions (interfaces). **Dependency Injection (with Flutter Riverpod)** will be used to "invert" this dependency.

  * **Design Patterns:**

      * **Builder:** Could be considered for constructing complex objects (`ExcelDataEntity` from raw data, if parsing logic becomes complex).
      * **Adapter:** Essential in the **Data Layer**. The `package:excel` library (or a new library) will serve as the "adaptee." The `ExcelLocalDatasource` will be the adapter that converts library-specific data into the `ExcelDataEntity` format of the Domain Layer.
      * **Strategy:** Filtering and pivoting logic could be implemented as different "strategies" that implement a common interface, allowing for runtime algorithm changes. This will be managed within `Use Cases` or by helper classes called by `Use Cases`.
      * **Observer (Implicit with Flutter BLoC and Flutter Riverpod):** **BLoCs** act as observable subjects (Stream of states), and `Views` are the observers that react to state changes. **Flutter Riverpod** itself implements the Observer pattern for dependency management and UI reactivity.
      * **State:** The State pattern will be naturally integrated into the **BLoC**, where each state (`ExcelState`) represents a different UI state (e.g., `Loading`, `Loaded`, `Filtered`, `Error`).

  * **Test-Driven Development (TDD):**

      * **Test-First Approach:** For every new feature or critical business logic refactoring, failing tests will be written first, then the code to make them pass, and finally the refactoring.
      * **Test Levels:**
          * **Unit Tests:** For `Entities`, `Use Cases` (Domain Layer), `Datasources` and `Repository Implementations` (Data Layer), **BLoCs** (Presentation Layer).
          * **Widget Tests:** For UI components that consume **BLoCs**.
          * **Integration Tests (Optional for this project):** For end-to-end scenarios involving multiple layers.

## 3\. Phased Migration Plan (Bottom-Up)

Refactoring will be performed incrementally on the `feature/clean-architecture-excel` branch to minimize risks and allow for visible progress.

1.  **Domain Layer - Entities (Core Business Objects):**

      * Define `ExcelDataEntity` (`excel_data_entity.dart`) as a pure representation of an Excel row.
      * Define `ExcelFilterEntity` (`excel_filter_entity.dart`) as a pure representation of the filter criteria's state.
      * *Conceptually replaces:* `lib/model/excel_element.dart` and the "data" part of `lib/model/filters.dart`.

2.  **Core Layer - Error Handling and Base Use Case:**

      * Define generic `Failure` and `Exception` classes (`core/errors/`).
      * Define a base `UseCase` (`core/usecases/`) to standardize use case calls.

3.  **Domain Layer - Repository Interfaces (Contracts):**

      * Define `ExcelRepository` (`excel_repository.dart`) with abstract methods for Excel data operations (reading, filtering, pivoting).
      * Define `FileExportRepository` (`file_export_repository.dart`) with abstract methods for file export operations.

4.  **Domain Layer - Use Cases (Pure Business Logic):**

      * Implement `ReadExcelFileUseCase` (uses `ExcelRepository`).
      * Implement `ApplyFiltersUseCase` (uses `ExcelFilterEntity` and `ExcelDataEntity`).
      * Implement `GetFilteredDataUseCase`.
      * Implement `ExportToExcelUseCase` and `ExportToPdfUseCase` (use `FileExportRepository`).
      * *Conceptually replaces:* The business logic part of `FileController.processExcelFile`, the logic of `Filters`, and the export logic of `ExcelExportController`.

5.  **Data Layer - Data Sources (External Interaction):**

      * Implement `ExcelLocalDatasource` (`excel_local_datasource.dart`). **This is where the Excel formula issue will be addressed**, by exploring alternative libraries or specific solutions to obtain calculated values. This datasource will handle the "physical" file reading and conversion into formats consumable by the Repository.
      * Implement `FileHandlerDatasource` (`file_handler_datasource.dart`) for handling file saving/sharing across different platforms.
      * *Conceptually replaces:* The I/O part of `FileController` and the `FileSaver`/`Share` handling in `ExcelExportController`.

6.  **Data Layer - Repository Implementations (Bridge between Data and Domain):**

      * Implement `ExcelRepositoryImpl` (`excel_repository_impl.dart`) which will use `ExcelLocalDatasource`. This class will be responsible for mapping `Exception` (from the Datasource) into `Failure` (for the Domain Layer).
      * Implement `FileExportRepositoryImpl` (`file_export_repository_impl.dart`) which will use `FileHandlerDatasource`.

7.  **Dependency Injection (Flutter Riverpod - di\_container.dart):**

      * Configure all **Flutter Riverpod** `Provider`s to inject the dependencies of `Use Cases` with their respective `Repository` implementations, and `Repository` with `Datasources`.

8.  **Presentation Layer - BLoC (ViewModel):**

      * Define `ExcelBloc` (`excel_bloc.dart`), its `ExcelEvent` (`excel_event.dart`), and its `ExcelState` (`excel_state.dart`) using the **flutter\_bloc** package. This BLoC will be the ViewModel that the UI observes. It will receive events from the UI and orchestrate calls to `Use Cases`.
      * *Conceptually replaces:* `ElementsProvider`, `FiltersProvider`, `ColumnTitlesProvider`.

9.  **Presentation Layer - Pages and Widgets (UI):**

      * Redesign `lib/features/excel_processing/presentation/pages/excel_home_page.dart` and `excel_details_page.dart` to consume `ExcelBloc`'s state and dispatch events.
      * Adapt existing widgets (`ColumnFilterCard`, `RowFilters`, `DetailsElement`, `InsertFile`) and move them to `lib/features/excel_processing/presentation/widgets/`, making them interact with the new `ExcelBloc`.
      * *Directly replaces:* `view/home_page.dart`, `view/filter_details.dart`, and the widgets in `view/home_page_widgets` and `view/filter_details_widgets`.

10. **Integration and Final Cleanup:**

      * Update `main.dart` to use the new pages.
      * Gradually remove old folders (`lib/model`, `lib/control`, `lib/provider`, `lib/view`) once all their content has been migrated and verified.
      * Ensure all tests pass.
