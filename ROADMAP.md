# ExlSer Roadmap

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

v0.1.0 (First Publishable Preview), v0.2.0 (Filtering and Sorting), and
v0.4.0 (Basic Analytics) are complete. The next major work is Export (v0.3.0),
which was deferred after analytics per the team's chosen delivery order.

Analytics was implemented in five phases:
- Value objects and domain entities (`ChartType`, `AggregationType`,
  `ChartSuggestion`, `ColumnStatistics`).
- Application DTOs (`ChartData`, `CategoryChartData`, `TimeSeriesChartData`,
  `EmptyChartData`, `CategoryPoint`, `TimeSeriesPoint`).
- Use cases: `SuggestChartsUseCase`, `GetColumnStatisticsUseCase`,
  `GetCategoryDistributionUseCase`, `GetTimeSeriesUseCase`.
- `AnalysisService` orchestrating the use cases.
- BLoC extension with `LoadAnalyticsEvent`, `ChangeChartConfigEvent`,
  and a `DatasetAnalyticsState` sealed hierarchy
  (Idle / Loading / Loaded / Error).
- Chart widgets: `PieChartWidget`, `DistributionChartWidget`,
  `LineChartWidget` (fl_chart 1.x).
- `AnalyticsSection` widget wired into `DatasetView` with column and
  aggregation dropdowns.
- Full test coverage for all new use cases and BLoC handlers.

A boolean filter bug was also fixed in this cycle: boolean string values
(`"true"`, `"yes"`, `"1"`, etc.) are now normalized to integer `1`/`0`
during import so SQL integer comparisons work correctly.

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
- [x] Latest known full test run: `flutter test` passing with 298 tests.
- [x] Latest known analyzer state: `flutter analyze` passing with no issues.

### Existing UI Skeleton

- [x] Home view skeleton exists.
- [x] File picker and drop area exist.
- [x] `HomeViewModel` tracks selected file path/bytes.
- [x] Import dialog skeleton exists.
- [x] General import step exists.
- [x] Column type confirmation step exists.
- [x] Final confirmation and dataset creation step exists.
- [x] Base router exists.
- [x] Dataset list skeleton exists.
- [x] Dataset view skeleton exists.
- [x] Dataset BLoC placeholder exists.

Current checkpoint:

```text
Import creation flow is wired through the wizard.
The app is not publishable yet because created datasets still need to be listed,
opened, displayed, and deleted from the UI.
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

- [x] Inject `ImportDataService` through Riverpod.
- [x] Execute `ImportDataService.prepareImport` from the dialog flow.
- [x] Store `PreparedImportResult` in temporary dialog state.
- [x] Show loading state while parsing/inference is running.
- [x] Show import errors using `ImportException.code`.
- [x] Do not persist anything yet.

Definition of done:

- [x] The wizard can parse a real selected CSV/XLSX file.
- [x] The prepared result contains sheets, columns, row counts, and inferred types.
- [x] Parser/schema errors are visible in the UI.
- [x] Tests cover success and failure states.

### 3. Add Column Type Confirmation

Goal: the user can review and correct the schema before dataset creation.

- [x] Show detected sheets.
- [x] Show original column names.
- [x] Show normalized database column names.
- [x] Show inferred column types.
- [x] Allow manual type override: text, integer, real, boolean, date.
- [x] Validate that every column has a selected type.
- [x] Keep `PreparedImportResult` immutable.
- [x] Store user modifications in dialog/ViewModel state.
- [x] Build `ConfirmedImport` from the prepared result plus user choices.

Definition of done:

- [x] The user can correct column types before creation.
- [x] Corrected types are passed to `CreateDatasetService`.
- [x] Tests cover Prepared -> Confirmed conversion.

### 4. Add Final Confirmation and Dataset Creation

Goal: the dataset is created only after the user confirms the wizard.

- [x] Show final summary: dataset name, source file, storage mode, sheet count, column count, row count.
- [x] Call `SaveUploadedFileUseCase` using the selected `saveLocally` option.
- [x] Call `CreateDatasetService.createDataset` only when the user clicks Finish/Create Dataset.
- [x] Use the real `CreatedDatasetResult.datasetId`.
- [x] Close the dialog after success.
- [x] Clear the selected file in Home after success.
- [x] Navigate to `DatasetView` with the real dataset id.
- [x] Remove temporary navigation to `/datasets/1`.

Definition of done:

- [x] The UI creates a dataset end-to-end.
- [x] The source file reference is registered.
- [x] Navigation uses the real dataset id.
- [x] Tests cover the confirmation flow.

### 5. Add i18n and User-Facing Import Errors

Goal: all visible import wizard messages are localized and understandable.

- [x] Map `ImportException.code` values to localized messages.
- [x] Move all visible import wizard strings to i18n/string manager.
- [x] Show clear messages for unsupported file, empty file, parser failure, schema failure, and missing file data.
- [x] Add retry/cancel behavior for failed preparation.

Definition of done:

- [x] No hardcoded user-facing strings remain in the wizard.
- [x] Technical errors are translated into user-readable messages.

### 6. Implement Dataset List

Goal: created datasets are visible and manageable.

- [x] Connect `DatasetsListViewModel` or a Riverpod provider to `GetDatasetsUseCase`.
- [x] Show an empty state when no datasets exist.
- [x] Show created datasets.
- [x] Display dataset name.
- [x] Display creation date.
- [x] Display last opened date when available.
- [x] Display source file information when available.
- [x] Open a selected dataset.
- [x] Delete a selected dataset with user confirmation.
- [x] Use `DeleteDatasetUseCase` for deletion.

Definition of done:

- [x] Created datasets appear in the list.
- [x] Open works with a real dataset id.
- [x] Delete removes dataset, schema, rows, and file reference.
- [x] ViewModel or widget tests cover list/open/delete.

### 7. Implement the Read-Only Dataset Workspace with BLoC

Goal: a created dataset can be opened and read.

- [x] Add `flutter_bloc` when the real dataset workspace implementation starts.
- [x] Replace placeholder `DatasetBloc` with a concrete implementation.
- [x] Implement minimum events: load dataset, change sheet, refresh rows, change view mode.
- [x] Implement minimum states: initial, loading, loaded, empty, error.
- [x] Load dataset metadata.
- [x] Load dataset tables/sheets from the schema repository.
- [x] Load columns for the active sheet.
- [x] Load initial rows with `FetchRowsUseCase`.
- [x] Mark dataset as opened by updating `lastOpenedAt`.
- [x] Connect `DatasetView` to the BLoC.

Definition of done:

- [x] Opening a dataset shows sheet metadata, columns, and rows.
- [x] Changing sheet reloads columns and rows.
- [x] Loading, empty, and error states are visible.
- [x] BLoC tests cover the main states and events.

### 8. Implement the Basic Data Table

Goal: imported rows are readable in the UI.

- [x] Implement the real `DatasetTableView`.
- [x] Support vertical scrolling.
- [x] Support horizontal scrolling.
- [x] Show column headers.
- [x] Show rows loaded from the database.
- [x] Handle null and empty cell values.
- [x] Add a reasonable initial row limit or pagination.

Definition of done:

- [x] The imported dataset is readable as a table.
- [x] The UI remains usable with many columns.

### 9. Prepare the First Public Preview

Goal: prepare the first public build.

- [x] Decide whether to fix or explicitly accept the 6 known analyzer info warnings.
- [x] Add widget tests for Home/upload/import dialog.
- [x] Add a smoke test for import -> create -> open dataset.
- [x] Verify build on web.
- [x] Verify build on at least one native platform.
- [x] Verify app name, splash screen, icons, and assets.
- [x] Verify database persistence after app restart.
- [x] Update README with run/test/build instructions.
- [x] Set app version for v0.1.0.
- [x] Add initial changelog/release notes.

### Milestone Reached: v0.1.0 - First Publishable Preview

The first publishable preview is reached only when all work in the previous section is complete.

Publish criteria:

- [x] A user can select a CSV or XLSX file.
- [x] A user can process the selected file through the import wizard.
- [x] A user can review detected sheets and columns.
- [x] A user can correct inferred column types.
- [x] A user can confirm the import.
- [x] A user can create a persistent dataset.
- [x] A user can see the created dataset in the dataset list.
- [x] A user can open the dataset.
- [x] A user can view imported rows in a table.
- [x] A user can delete a dataset safely.
- [x] `flutter test` passes.
- [x] `flutter analyze` has no blocking issues.
- [x] A release build can be produced for the chosen first target platform.
- [x] The README explains what the preview can and cannot do.

## Path to Filtering and Sorting

Goal: make dataset browsing useful beyond read-only viewing.

- [x] Define UI/domain filter models for text, number, date, and boolean values.
- [x] Define `DatasetSort` and sort direction models.
- [x] Complete `ApplyFiltersUseCase`.
- [x] Complete `GetDistinctValuesUseCase`.
- [x] Wire `QueryRepositoryImpl.queryWithFilter`.
- [x] Wire `QueryRepositoryImpl.queryWithFilterAndOrder`.
- [x] Extend Dataset BLoC with add filter, remove filter, clear filters, and sort column events.
- [x] Implement a guided filter panel with column selection, type-specific controls, and active filter chips.
- [x] Add text filter UI using a simple contains search by default.
- [x] Add numeric filter UI using a range selector based on loaded values.
- [x] Add date filter UI using a from/to range.
- [x] Add boolean filter UI using a true/false selector.
- [x] Keep SQL-style operators behind an advanced-mode toggle.
- [x] Add sortable table headers.
- [x] Add visible-column controls for hiding irrelevant data in the workspace.
- [x] Add localized filter, sort, and error messages.
- [x] Persist workspace UI state in `uiStateJson`.
- [x] Restore filters, active sheet, hidden columns, and view mode when reopening a dataset.
- [x] Add tests for composed SQL filters.
- [x] Add BLoC tests for filtering and sorting.

Future filtering enhancements:

- [ ] Add global search across all visible columns.
- [ ] Add distinct value suggestions for text and boolean filters.
- [ ] Add min/max assistance for numeric and date filters.
- [ ] Add a desktop/web advanced column-filter row inspired by DevExpress.

### Milestone Reached: v0.2.0 - Filtering and Sorting

Publish criteria:

- [x] The user can filter text, numbers, dates, and booleans.
- [x] The user can sort by column.
- [x] Workspace state is restored when reopening a dataset.

## Path to Export

Goal: export dataset data or filtered results.

- [x] Export the current sheet using active filters, sorting, and visible columns.
- [x] Complete `ExportCsvUseCase`.
- [x] Complete `ExportExcelUseCase`.
- [x] Complete `ExportPdfUseCase`.
- [x] Include `ExportSqlUseCase` in this release.
- [x] Implement `ExportDataService`.
- [x] Add export action from DatasetView.
- [x] Integrate native share/download flow.
- [x] Handle web/native differences through `share_plus`.
- [x] Add export use case tests.
- [x] Add export service tests.

### Milestone Reached: v0.3.0 - Export

Publish criteria:

- [x] The user can export at least CSV and Excel.
- [x] Export respects the selected sheet, active filters, sorting, and visible columns.

## Path to Basic Analytics

Goal: provide useful summaries and charts.

- [x] Define `ChartSuggestion` models with chart type, x/date column,
      y/value column, category/group column, and aggregation function.
- [x] Implement `SuggestChartsUseCase` from confirmed dataset columns.
- [x] Add `suggestAll()` to `SuggestChartsUseCase`: returns one `ChartSuggestion`
      per supported chart type given the available columns.
- [x] Complete `AggregateColumnUseCase`.
- [x] Implement `AnalysisService`.
- [x] Wire aggregations to `QueryRepositoryImpl.aggregate`.
- [x] Add basic statistics for numeric columns (`GetColumnStatisticsUseCase`).
- [x] Add distributions for categorical columns (`GetCategoryDistributionUseCase`).
- [x] Connect `DistributionChart` (bar chart for high-cardinality categories).
- [x] Connect `PieChart` (pie/donut for ≤8 categories).
- [x] Connect `LineChart` (time series with area fill).
- [x] Add bar/column chart support for high-cardinality categories.
- [ ] Add scatter plot support for numeric-vs-numeric datasets.
- [x] Add multi-chart analytics panel to DatasetView.
      - Auto-generate one chart per supported type on load.
      - Each chart is independent with its own column and aggregation controls.
      - Column selectors for each chart show only compatible column types
        (e.g., date columns for line chart X axis, numeric columns for Y axis).
      - A trash button removes individual charts.
      - A "+" button adds a new chart for any supported type.
- [x] Persist chart panel configuration in `uiStateJson` so charts are
      restored when reopening a dataset.
- [x] Respect active filters in all chart queries.
- [ ] Add scatter plot support for numeric-vs-numeric datasets.

Note: scatter plot is deferred to a future release. The `ChartType.scatter`
value and `SuggestChartsUseCase` support it structurally, but the
`ScatterChart` widget is not yet implemented.

### Automatic Chart Suggestion Rules

The dataset workspace should behave like a guided lightweight BI surface.
After import and schema confirmation, `DatasetView` reads the detected column
types and proposes a useful initial visualization instead of starting from an
empty analytics panel.

Supported column types:

- `text`
- `integer`
- `real`
- `boolean`
- `date`

Initial chart priority:

1. If at least one `date` column and one numeric column exist, suggest a
   time-based line or area chart.
2. Otherwise, if at least one `text` column and one numeric column exist,
   suggest a category chart. Use a pie/donut chart for small category sets and
   a bar/column chart for larger category sets.
3. Otherwise, if at least two numeric columns exist, suggest a scatter plot.
4. Otherwise, if at least one boolean column exists, suggest a true/false
   distribution chart.
5. Otherwise, show the table and a clear "no automatic chart available"
   analytics empty state.

### Chart Rules

Category distribution:

- Required columns: one `text` column and one numeric column.
- Default chart: pie/donut for up to roughly 8-10 categories.
- Fallback chart: bar/column when category count is higher.
- Label: selected text column.
- Value: selected numeric column aggregated by category.
- Controls: label column, value column, aggregation (`SUM`, `AVG`, `COUNT`,
  `MIN`, `MAX`), sort direction, and top-N limit.

Time series:

- Required columns: one `date` column and one numeric column.
- Default chart: line or area chart.
- X axis: selected date column.
- Y axis: selected numeric column.
- Optional grouping: selected text column for series/category split.
- Controls: date column, numeric column, optional category column,
  aggregation, and chart type (`line` or `area`).

Scatter plot:

- Required columns: at least two numeric columns.
- X axis: selected numeric column.
- Y axis: selected numeric column.
- Optional grouping/label: selected text column.
- Controls: x numeric column, y numeric column, optional group column.

Boolean distribution:

- Required columns: one boolean column.
- Default chart: pie/donut or bar chart with true/false counts.
- Optional numeric aggregation: sum or average of a numeric column grouped by
  boolean value.

Regression and forecast:

- Candidate inputs: two numeric columns, or one `date` column plus one numeric
  target column.
- First implementation should stay simple: linear regression, moving average,
  and lightweight trend lines.
- Forecast controls: x/date column, target numeric column, forecast horizon,
  and method (`trend`, `moving_average`, `linear_regression`).
- This is an advanced analytics enhancement and can be delivered after the
  first basic charting release if needed.

### DatasetView Analytics Layout

The analytics section should be integrated into `DatasetView` without replacing
the read-only table.

Planned structure:

```text
DatasetView
├── Dataset header
├── Sheet selector
├── Suggested chart panel
│   ├── Chart type selector
│   ├── X/category dropdown
│   ├── Y/value dropdown
│   ├── Aggregation dropdown
│   ├── Optional group/top-N/sort controls
│   └── Chart
├── Data table
└── Filters / stats
```

For the first analytics release, the table should remain the primary reliable
surface and the suggested chart panel can appear above or below it. A more BI-
oriented workspace can move toward a chart panel plus table workspace after the
read-only and filtering flows are stable.

### Automatic Chart Suggestion and Column Compatibility

Each chart type only accepts specific column types for its axes:

| Chart type  | X axis column types            | Y axis column types     | Y required? |
|-------------|-------------------------------|-------------------------|-------------|
| `line`      | `date`                        | `integer`, `real`       | yes         |
| `bar`       | `text`, `boolean`, `date`     | `integer`, `real`       | no          |
| `pie`       | `text`, `boolean`             | `integer`, `real`       | no          |
| `scatter`   | `integer`, `real`             | `integer`, `real`       | yes         |

Column selectors in each chart card show only the columns that match
the allowed types for that axis and chart type.

`suggestAll(columns)` returns one `ChartSuggestion` per chart type for
which the column set has at least the required columns. The auto-populated
analytics panel shows one card per returned suggestion.

### Milestone Reached: v0.4.0 - Basic Analytics

Publish criteria:

- [x] The user can see one chart card per supported chart type on open.
- [x] Each chart card is independent with its own column and aggregation controls.
- [x] Column dropdowns in each card show only compatible columns for that chart type.
- [x] The user can add additional charts with a "+" button.
- [x] The user can delete individual charts with a trash button.
- [x] Chart panel configuration is persisted in `uiStateJson`.
- [x] Analytics respects the selected sheet and active filters.

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

- [ ] Path to Export (v0.3.0) — deferred after analytics, now the priority.

Practical order:

1. Export the current sheet using active filters, sorting, and visible columns.
2. Complete `ExportCsvUseCase`.
3. Complete `ExportExcelUseCase` and `ExportPdfUseCase`.
4. Implement `ExportDataService` orchestrating the use cases.
5. Add export dialog triggered from `DatasetView`.
6. Integrate share sheet/download fallback (handle web vs native).
7. Write export use case and service tests.
8. Ship v0.3.0.
