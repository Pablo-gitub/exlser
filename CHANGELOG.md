# Changelog

## 2.0.1 - Guided Sheet Joins and Hardening

Cross-sheet analysis without SQL, plus a security and architecture pass.

### Added

- Guided multi-sheet joins: a dedicated workspace for comparing the sheets of a
  dataset without writing SQL, with `INNER`/`LEFT` choices and a limited preview.
- Relationship suggestions from normalized column names, compatible types, value
  overlap and uniqueness, labelled high, medium, or low confidence.
- Cardinality estimated from bounded samples, with its own confidence.
- Manual relationships, saved join configurations, and persisted
  `DatasetRelationship` metadata.
- Table overview: an interactive graph of a dataset's tables and their
  relationships, with drag, zoom, and fit-to-view.
- Confirmation before running a preview whose join risks being expensive.
- A warning when the browser cannot store datasets durably, for the web demo.
- Continuous integration on every push and pull request: analyzer, full test
  suite, formatting gate, landing-page build, and production dependency audit.

### Changed

- Raw SQL validation rewritten on a real SQL parser instead of keyword matching,
  which removes both the false positives and the bypasses of the regex version.
- File parsing moved off the UI isolate, with an explicit size limit.
- Framework and dependency majors updated across the app.
- Analyzer tightened with strict casts, strict inference, strict raw types, and
  nine behaviour lints.
- Landing page: robots and sitemap added, title and hero copy tightened.
- Workflows moved to the current action majors, Node 24, and a pinned Flutter
  version, so what CI validates is what the release tags build.

### Fixed

- Table overview: fit-to-view scale, zoom clamping, pan and drag competing for
  the same gesture, and dragging bounded at the canvas origin.
- Onboarding could not be completed: a disposed provider reference threw after
  the completion flag was written and before the router was notified.
- The web demo could not load datasets, because asset URLs reached drift's
  worker as relative paths and resolved against the worker's own context.
- XLSX import rejected valid absolute relationship targets.
- Saved join configurations could show results from a previous configuration.

### Security

- Closed a validator bypass: comma joins and `sqlite_master` reached the
  database through `executeRawQuery`, which ran unvalidated.
- Every raw query now passes a single-SELECT assertion at the repository
  boundary, not only in the use case.
- Identifiers are quoted when generated SQL interpolates them.

## 2.0.0 - Google Play Preparation

Current release candidate for the first Google Play publication.

### Added

- Type-aware filtering, sorting, pagination, and column visibility.
- Read-only SQL query mode with schema helper and validation.
- Automatic analytics with line, bar, and pie chart suggestions.
- Multi-format export: Excel, CSV, PDF, SQL, and JSON.
- PDF card export with per-row JSON QR codes.
- Nine supported UI languages.
- GitHub README screenshots and MIT license.

### Changed

- Renamed the project and public repository identity to Exlser.
- Renamed the Dart package to `exlser`.
- Locked the Android application ID to `com.paolopietrelli.exlser`.
- Aligned macOS, iOS, Linux, Windows, web, and local database naming.

### Removed

- Unused dependency injection placeholder.
- Generated iOS files that should not be tracked.

## 0.1.0 - First Publishable Preview

Initial preview focused on the local import workflow.

### Added

- CSV and XLSX import preparation.
- Import wizard with dataset name, file storage option, column type review, and final confirmation.
- User-confirmed schema before dataset creation.
- Local dataset persistence with Drift and dynamic SQL tables.
- Source file reference metadata.
- Dataset list with open and delete actions.
- Read-only dataset workspace powered by BLoC.
- Basic table and card views for imported rows.
- English and Italian user-facing strings for the import and dataset flows.
- Smoke tests for import, dataset creation, opening, and row reading.

### Not Included Yet

- Filtering and sorting.
- Export.
- Analytics and automatic charts.
- Cross-sheet or multi-dataset analysis.
