## ExcelCategory – Development Roadmap

Architecture Status

The project architecture has been fully designed following a layered approach:

```
core
domain
data
application
presentation
```
The current goal is to progressively implement the application using vertical feature slices.

⸻

Phase 0 – Architecture (Completed)

Implemented skeleton for:

Core
```
core/errors
core/usecases
core/database
```

Domain
```
entities
value_objects
repositories
usecases
```

Data
```
repositories_impl
parsers
datasources
dynamic_table_builder
```

Application
```
services
```

Presentation
```
views
viewmodels
widgets
bloc
```
⸻

Phase 1 – Dataset Import Pipeline

Goal:
```
Import Excel/CSV
→ infer schema
→ confirm schema
→ create SQL tables
→ insert rows
```

Files to implement:

UseCases
```
domain/usecases/schema/infer_schema_usecase.dart
domain/usecases/schema/build_dynamic_table_usecase.dart
domain/usecases/schema/register_columns_usecase.dart
domain/usecases/schema/insert_rows_usecase.dart
```

Data Adapters
```
data/adapters/parsers/excel_parser.dart
data/adapters/parsers/csv_parser.dart
data/adapters/parsers/parser_factory.dart
```

DataSources
```
data/datasources/file_datasource.dart
data/datasources/drift_datasource.dart
```

Schema Builder
```
data/schema/dynamic_table_builder.dart
```

Repositories
```
data/repositories/schema_repository_impl.dart
data/repositories/dataset_repository_impl.dart
```

Application Service
```
application/services/import_data_service.dart
```

UI
```
presentation/views/home/home_view.dart
presentation/widgets/schema/schema_confirmation_dialog.dart
```

Result:
```
User can import a dataset and store it in the database
```
⸻

Phase 2 – Dataset Workspace

Goal:
```
Open dataset
View rows
Switch sheets
```

Files:

UseCases
```
domain/usecases/dataset/get_datasets_usecase.dart
domain/usecases/dataset/open_dataset_usecase.dart
```

Repository
```
data/repositories/query_repository_impl.dart
```

Application
```
application/services/query_data_service.dart
```

UI
```
presentation/views/dataset_list/datasets_list_view.dart
presentation/views/dataset/dataset_view.dart
presentation/widgets/dataset_views/dataset_table_view.dart
```

Result:
```
User can open dataset and view data
```
⸻

Phase 3 – Filtering Engine

Goal:
```
Apply filters to dataset columns
```

Files:

UseCases
```
domain/usecases/query/apply_filters_usecase.dart
domain/usecases/query/fetch_rows_usecase.dart
domain/usecases/query/get_distinct_values_usecase.dart
```

Application
```
application/services/query_data_service.dart
```

UI
```
presentation/widgets/filters/filter_text_widget.dart
presentation/widgets/filters/filter_numeric_widget.dart
presentation/widgets/filters/filter_date_widget.dart
presentation/widgets/dataset_sections/filters_section.dart
```

Result:
```
Dataset filtering working
```
⸻

Phase 4 – Analytics

Goal:
```
Generate charts
```

Files:

UseCases
```
domain/usecases/query/aggregate_column_usecase.dart
```

Services
```
application/services/analysis_service.dart
```

UI
```
presentation/widgets/charts/distribution_chart.dart
presentation/widgets/charts/pie_chart.dart
presentation/widgets/charts/line_chart.dart
presentation/widgets/dataset_sections/analytics_section.dart
```

Result:
```
Charts generated from filtered data
```
⸻

Phase 5 – Export System

Goal:
```
Export filtered results
```

Files:

UseCases
```
domain/usecases/export/export_excel_usecase.dart
domain/usecases/export/export_csv_usecase.dart
domain/usecases/export/export_pdf_usecase.dart
domain/usecases/export/export_sql_usecase.dart
```

Service
```
application/services/export_data_service.dart
```

UI
```
Export dialog from dataset view
```

Result:
```
User can export results
```
⸻

Phase 6 – Cross-Sheet Analytics

Goal:
```
Compare sheets
Merge datasets
Join tables
```

Files:
```
presentation/views/multi_dataset_analytics/\*
application/services/analysis_service.dart
```
⸻

Phase 7 – Application Polish

Files:
```
presentation/views/settings/_
presentation/views/onboarding/_
presentation/views/splash/\*
```
⸻

Legacy Code Removal

Old architecture to remove progressively:
```
features/excel/_
control/_
model/_
provider/_
view/\*
```

Removal strategy: 
1. remove when equivalent new feature is implemented 
2. avoid breaking functionality during migration

⸻

Future Features

Possible extensions:
```
Regression models
Advanced analytics
Dataset comparison tools
BI dashboard
```
⸻

Current Priority

Next implementation step:
```
Phase 1 – Dataset Import Pipeline
```
⸻
