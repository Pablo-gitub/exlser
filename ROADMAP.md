# ExlSer / ExcelCategory Roadmap

This document is the working roadmap for the project. It defines what is already complete, what must be done next, and which completion checkpoint each group of work unlocks.

Milestones are written as arrival points: the required work comes first, then the release/publication checkpoint appears after the checklist that makes it possible.

Checklist legend:

- [x] Done
- [ ] To do
- [ ] Do not start a step until the previous step in the same section is implemented and tested

## Architecture Rules

The app follows a layered architecture:

```text
core
domain
data
application
presentation
```

Dependency direction:

```text
presentation -> application/domain
application  -> domain
data         -> domain
core         -> shared infrastructure
```

State management:

```text
Riverpod = dependency wiring, routing, settings, lightweight ViewModels,
           temporary UI state, and the import wizard.

BLoC     = dataset workspace: opened dataset, active sheet, filters,
           sorting, rows, refresh events, view mode, and analytics.
```

Product rule:

```text
A persistent dataset is created only after the final wizard confirmation.
Before confirmation, the user must be able to review the file, sheets,
column names, and column types.
```

## Current Status

The project is past the low-level import foundation. The next major work is UI wiring for the real import flow.

### Completed Foundation

- [x] Clean Architecture structure is in place.
- [x] `core`, `domain`, `data`, `application`, and `presentation` layers exist.
- [x] Drift is integrated as the local database layer.
- [x] Core database tables exist: datasets, dataset_tables, dataset_columns, dataset_files.
- [x] Drift DAOs are implemented and tested.
- [x] Generated Drift files are up to date.
- [x] Database, repository, use case, parser, service, and provider tests exist.

### Completed Import Core

- [x] CSV parser implemented.
- [x] Excel parser implemented.
- [x] `SpreadsheetParser` supports both file paths and in-memory bytes.
- [x] `ParserFactory` implemented.
- [x] `ImportFile` DTO implemented for path-based and bytes-based inputs.
- [x] `PreparedSheet` DTO implemented.
- [x] `PreparedImportResult` DTO implemented.
- [x] `ConfirmedImport` and `ConfirmedImportSheet` DTOs implemented.
- [x] `CreatedDatasetResult` DTO implemented.
- [x] `ImportException` implemented with error codes.
- [x] `ImportDataService.prepareImport` uses `ImportFile`.
- [x] `ImportDataService` prepares sheets, inferred schema, and preview data.
- [x] `CreateDatasetService` uses the user-confirmed schema.
- [x] `CreateDatasetService` creates dataset metadata, dataset tables, columns, dynamic SQL tables, and rows.
- [x] `CreateDatasetService` returns the real created dataset result.

### Completed File Source Handling

- [x] `SourceFileReference` implemented.
- [x] `DatasetFile` entity implemented.
- [x] `DatasetFileRepository` and Drift implementation completed.
- [x] `SaveUploadedFileUseCase` implemented.
- [x] `FileDatasource` supports path references, bytes references, and path copy.
- [x] Native platforms can copy imported files into app-local storage.
- [x] Web falls back to temporary file references.
- [x] Dataset deletion also deletes schema metadata and file references.

### Completed Repository and Use Case Work

- [x] `DatasetsRepositoryImpl` completed.
- [x] `SchemaRepositoryImpl` completed for metadata and dynamic SQL tables.
- [x] `QueryRepositoryImpl` implemented for row fetching, filtered queries, distinct values, aggregates, raw queries, and batch inserts.
- [x] Dataset use cases implemented: create, list, delete, register file.
- [x] Schema use cases implemented: infer schema, create table, register columns, build dynamic table, insert rows.
- [x] `FetchRowsUseCase` implemented.

### Completed Dependency Wiring

- [x] Riverpod providers for database and datasources.
- [x] Riverpod providers for repositories.
- [x] Riverpod providers for use cases.
- [x] Riverpod providers for application services.
- [x] Provider integration test with an in-memory database.
- [x] Latest known full test run: `flutter test` passing with 202 tests.
- [x] Latest known analyzer state: no blocking errors, 6 known informational warnings.

### Existing UI Skeleton

- [x] Home view skeleton exists.
- [x] File picker and drop area exist.
- [x] `HomeViewModel` tracks selected file path/bytes.
- [x] Import dialog skeleton exists.
- [x] General import step exists.
- [x] Column type step placeholder exists.
- [x] Confirmation step placeholder exists.
- [x] Base router exists.
- [x] Dataset list skeleton exists.
- [x] Dataset view skeleton exists.
- [x] Dataset BLoC placeholder exists.

Current checkpoint:

```text
Import core foundation is mostly ready.
The app is not publishable yet because the real UI flow is not wired.
```

## Path to the First Publishable Preview

Goal: a real user can import a CSV/XLSX file, confirm the schema, create a persistent dataset, reopen it, view rows, and delete it safely.

Filtering, export, analytics, and cross-dataset features are not required for the first publishable preview.

### 1. Wire Home to the Import Wizard

Goal: the selected file from the Home screen reaches the real import wizard as an `ImportFile`.

- [x] Use the existing Riverpod Home/Dialog providers for handoff state.
- [x] Convert the Home file selection into `ImportFile`.
- [x] Support path-based files on desktop/mobile.
- [x] Support bytes-based files on web/dropzone.
- [x] Pass `ImportFile` into the import dialog.
- [x] Keep dataset creation disabled at this stage.

Definition of done:

- [x] The dialog receives the real selected file.
- [x] The flow works for path input and bytes input.
- [x] The Home selection can still be cleared.
- [x] ViewModel or widget tests cover the basic file handoff.

### 2. Run `prepareImport` from the Wizard

Goal: the wizard parses the selected file and stores a temporary prepared result.

- [ ] Inject `ImportDataService` through Riverpod.
- [ ] Execute `ImportDataService.prepareImport` from the dialog flow.
- [ ] Store `PreparedImportResult` in temporary dialog state.
- [ ] Show loading state while parsing/inference is running.
- [ ] Show import errors using `ImportException.code`.
- [ ] Do not persist anything yet.

Definition of done:

- [ ] The wizard can parse a real selected CSV/XLSX file.
- [ ] The prepared result contains sheets, columns, row counts, and inferred types.
- [ ] Parser/schema errors are visible in the UI.
- [ ] Tests cover success and failure states.

### 3. Add Column Type Confirmation

Goal: the user can review and correct the schema before dataset creation.

- [ ] Show detected sheets.
- [ ] Show original column names.
- [ ] Show normalized database column names.
- [ ] Show inferred column types.
- [ ] Allow manual type override: text, integer, real, boolean, date.
- [ ] Validate that every column has a selected type.
- [ ] Keep `PreparedImportResult` immutable.
- [ ] Store user modifications in dialog/ViewModel state.
- [ ] Build `ConfirmedImport` from the prepared result plus user choices.

Definition of done:

- [ ] The user can correct column types before creation.
- [ ] Corrected types are passed to `CreateDatasetService`.
- [ ] Tests cover Prepared -> Confirmed conversion.

### 4. Add Final Confirmation and Dataset Creation

Goal: the dataset is created only after the user confirms the wizard.

- [ ] Show final summary: dataset name, source file, storage mode, sheet count, column count, row count.
- [ ] Call `SaveUploadedFileUseCase` using the selected `saveLocally` option.
- [ ] Call `CreateDatasetService.createDataset` only when the user clicks Finish/Create Dataset.
- [ ] Use the real `CreatedDatasetResult.datasetId`.
- [ ] Close the dialog after success.
- [ ] Clear the selected file in Home after success.
- [ ] Navigate to `DatasetView` with the real dataset id.
- [ ] Remove temporary navigation to `/datasets/1`.

Definition of done:

- [ ] The UI creates a dataset end-to-end.
- [ ] The source file reference is registered.
- [ ] Navigation uses the real dataset id.
- [ ] Tests cover the confirmation flow.

### 5. Add i18n and User-Facing Import Errors

Goal: all visible import wizard messages are localized and understandable.

- [ ] Map `ImportException.code` values to localized messages.
- [ ] Move all visible import wizard strings to i18n/string manager.
- [ ] Show clear messages for unsupported file, empty file, parser failure, schema failure, and missing file data.
- [ ] Add retry/cancel behavior for failed preparation.

Definition of done:

- [ ] No hardcoded user-facing strings remain in the wizard.
- [ ] Technical errors are translated into user-readable messages.

### 6. Implement Dataset List

Goal: created datasets are visible and manageable.

- [ ] Connect `DatasetsListViewModel` or a Riverpod provider to `GetDatasetsUseCase`.
- [ ] Show an empty state when no datasets exist.
- [ ] Show created datasets.
- [ ] Display dataset name.
- [ ] Display creation date.
- [ ] Display last opened date when available.
- [ ] Display source file information when available.
- [ ] Open a selected dataset.
- [ ] Delete a selected dataset with user confirmation.
- [ ] Use `DeleteDatasetUseCase` for deletion.

Definition of done:

- [ ] Created datasets appear in the list.
- [ ] Open works with a real dataset id.
- [ ] Delete removes dataset, schema, rows, and file reference.
- [ ] ViewModel or widget tests cover list/open/delete.

### 7. Implement the Read-Only Dataset Workspace with BLoC

Goal: a created dataset can be opened and read.

- [ ] Add `flutter_bloc` when the real dataset workspace implementation starts.
- [ ] Replace placeholder `DatasetBloc` with a concrete implementation.
- [ ] Implement minimum events: load dataset, change sheet, refresh rows, change view mode.
- [ ] Implement minimum states: initial, loading, loaded, empty, error.
- [ ] Load dataset metadata.
- [ ] Load dataset tables/sheets from the schema repository.
- [ ] Load columns for the active sheet.
- [ ] Load initial rows with `FetchRowsUseCase`.
- [ ] Mark dataset as opened by updating `lastOpenedAt`.
- [ ] Connect `DatasetView` to the BLoC.

Definition of done:

- [ ] Opening a dataset shows sheet metadata, columns, and rows.
- [ ] Changing sheet reloads columns and rows.
- [ ] Loading, empty, and error states are visible.
- [ ] BLoC tests cover the main states and events.

### 8. Implement the Basic Data Table

Goal: imported rows are readable in the UI.

- [ ] Implement the real `DatasetTableView`.
- [ ] Support vertical scrolling.
- [ ] Support horizontal scrolling.
- [ ] Show column headers.
- [ ] Show rows loaded from the database.
- [ ] Handle null and empty cell values.
- [ ] Add a reasonable initial row limit or pagination.

Definition of done:

- [ ] The imported dataset is readable as a table.
- [ ] The UI remains usable with many columns.

### 9. Prepare the First Public Preview

Goal: prepare the first public build.

- [ ] Decide whether to fix or explicitly accept the 6 known analyzer info warnings.
- [ ] Add widget tests for Home/upload/import dialog.
- [ ] Add a smoke test for import -> create -> open dataset.
- [ ] Verify build on web.
- [ ] Verify build on at least one native platform.
- [ ] Verify app name, splash screen, icons, and assets.
- [ ] Verify database persistence after app restart.
- [ ] Update README with run/test/build instructions.
- [ ] Set app version for v0.1.0.
- [ ] Add initial changelog/release notes.

### Milestone Reached: v0.1.0 - First Publishable Preview

The first publishable preview is reached only when all work in the previous section is complete.

Publish criteria:

- [ ] A user can select a CSV or XLSX file.
- [ ] A user can process the selected file through the import wizard.
- [ ] A user can review detected sheets and columns.
- [ ] A user can correct inferred column types.
- [ ] A user can confirm the import.
- [ ] A user can create a persistent dataset.
- [ ] A user can see the created dataset in the dataset list.
- [ ] A user can open the dataset.
- [ ] A user can view imported rows in a table.
- [ ] A user can delete a dataset safely.
- [ ] `flutter test` passes.
- [ ] `flutter analyze` has no blocking issues.
- [ ] A release build can be produced for the chosen first target platform.
- [ ] The README explains what the preview can and cannot do.

## Path to Filtering and Sorting

Goal: make dataset browsing useful beyond read-only viewing.

- [ ] Define UI/domain filter models for text, number, date, and boolean values.
- [ ] Complete `ApplyFiltersUseCase`.
- [ ] Complete `GetDistinctValuesUseCase`.
- [ ] Wire `QueryRepositoryImpl.queryWithFilter`.
- [ ] Wire `QueryRepositoryImpl.queryWithFilterAndOrder`.
- [ ] Extend Dataset BLoC with update filter, clear filter, and sort column events.
- [ ] Implement `FilterTextWidget`.
- [ ] Implement `FilterNumericWidget`.
- [ ] Implement `FilterDateWidget`.
- [ ] Add boolean filter UI.
- [ ] Persist workspace UI state in `uiStateJson`.
- [ ] Restore filters, active sheet, and view mode when reopening a dataset.
- [ ] Add tests for composed SQL filters.
- [ ] Add BLoC tests for filtering and sorting.

### Milestone Reached: v0.2.0 - Filtering and Sorting

Publish criteria:

- [ ] The user can filter text, numbers, dates, and booleans.
- [ ] The user can sort by column.
- [ ] Workspace state is restored when reopening a dataset.

## Path to Export

Goal: export dataset data or filtered results.

- [ ] Decide export scope: full dataset, current sheet, or filtered results.
- [ ] Complete `ExportCsvUseCase`.
- [ ] Complete `ExportExcelUseCase`.
- [ ] Complete `ExportPdfUseCase`.
- [ ] Decide whether `ExportSqlUseCase` belongs in this release.
- [ ] Implement `ExportDataService`.
- [ ] Add export dialog from DatasetView.
- [ ] Integrate `file_saver` and/or share flow.
- [ ] Handle web/native differences.
- [ ] Add export use case tests.
- [ ] Add export service tests.

### Milestone Reached: v0.3.0 - Export

Publish criteria:

- [ ] The user can export at least CSV and Excel.
- [ ] Export respects the selected sheet and active filters if that scope is selected.

## Path to Basic Analytics

Goal: provide useful summaries and charts.

- [ ] Complete `AggregateColumnUseCase`.
- [ ] Implement `AnalysisService`.
- [ ] Wire aggregations to `QueryRepositoryImpl.aggregate`.
- [ ] Add basic statistics for numeric columns.
- [ ] Add distributions for categorical columns.
- [ ] Connect `DistributionChart`.
- [ ] Connect `PieChart`.
- [ ] Connect `LineChart`.
- [ ] Add analytics section to DatasetView.
- [ ] Respect active filters in analytics queries.

### Milestone Reached: v0.4.0 - Basic Analytics

Publish criteria:

- [ ] The user can see basic aggregations and charts for the opened dataset.

## Path to Cross-Sheet and Multi-Dataset Analysis

Goal: analyze relationships across sheets and datasets.

- [ ] Define cross-sheet operation models.
- [ ] Load metadata for multiple sheets.
- [ ] Detect compatible columns.
- [ ] Implement simple merge/union.
- [ ] Evaluate join support.
- [ ] Implement `MultiDatasetAnalyticsViewModel`.
- [ ] Implement UI for selecting sheets/datasets.
- [ ] Add tests for cross-sheet operations.

### Milestone Reached: v0.5.0 - Cross-Sheet and Multi-Dataset Analysis

Publish criteria:

- [ ] The user can compare or combine at least two sheets/datasets.

## Path to UX, Settings, and Polish

Goal: improve the user experience across platforms.

- [ ] Implement real settings.
- [ ] Persist language selection.
- [ ] Persist theme selection.
- [ ] Add useful first-run onboarding.
- [ ] Improve empty states.
- [ ] Improve loading states.
- [ ] Improve error states with actions.
- [ ] Improve responsive layout on mobile, desktop, and web.
- [ ] Improve basic accessibility.
- [ ] Refine i18n copy.

### Milestone Reached: v0.6.0 - UX, Settings, and Polish

Publish criteria:

- [ ] The experience feels coherent on mobile, desktop, and web.
- [ ] Main flows do not expose placeholders.

## Path to Stable Public Release

Goal: harden the app for real use.

- [ ] Add versioned Drift migrations.
- [ ] Define database backup/restore strategy.
- [ ] Handle large files and memory limits.
- [ ] Add progressive import or chunking where needed.
- [ ] Add performance tests on realistic datasets.
- [ ] Update CI for test/build/release workflows.
- [ ] Produce release builds for target platforms.
- [ ] Add privacy notes for local data.
- [ ] Add user documentation.
- [ ] Add complete changelog and release notes.

### Milestone Reached: v1.0.0 - Stable Public Release

Publish criteria:

- [ ] The app is stable for real-world use.
- [ ] Releases are reproducible.
- [ ] User and developer documentation are complete enough for public users.

## Legacy Migration

Legacy code should be removed only after the equivalent new flow is complete:

- [ ] `features/excel/*`
- [ ] old model/control/provider/view folders if still present.
- [ ] legacy export use cases once replaced by the new domain/application export flow.
- [ ] placeholder widgets no longer used by real screens.

Removal rule:

```text
Do not remove legacy code if it breaks a flow that has not been replaced yet.
Every removal should have a test or a manual verification of the equivalent flow.
```

## Future Ideas

These are not part of the first publishable release:

- [ ] BI dashboard.
- [ ] Saved import templates.
- [ ] Advanced data validation.
- [ ] Invalid value correction during import.
- [ ] Data quality profiling.
- [ ] Automatic column type suggestions.
- [ ] Statistical models or regression.
- [ ] Optional AI/ML features.

## Next Operational Step

Immediate next step:

- [ ] Path to the First Publishable Preview - Step 2: Run `prepareImport` from the Wizard.

Practical order:

1. Inject `ImportDataService` through Riverpod.
2. Run `prepareImport` from the dialog flow.
3. Store `PreparedImportResult` in dialog state.
4. Show loading and error states.
5. Keep persistence disabled until final confirmation.
6. Prepare the next step: editable column type confirmation.
