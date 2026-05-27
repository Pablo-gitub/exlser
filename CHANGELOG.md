# Changelog

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
