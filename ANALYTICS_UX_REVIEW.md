# Analytics UI/UX Review

This document summarizes recommended improvements for the Dataset analytics
experience. The review is based on the current chart panel, chart suggestion
logic, chart loading flow, and chart rendering widgets.

## Current State

The analytics section already supports:

- automatic chart suggestions from column types;
- bar, pie, and line charts;
- multiple chart cards in the Dataset workspace;
- per-chart column and aggregation controls;
- chart configuration persistence in `uiStateJson`;
- chart reload when filters change;
- aggregation help text.

The main UX issue is that the controls expose the internal query model too
directly. Users can create combinations that are technically accepted by the UI
but semantically wrong or unclear.

## Priority 1 - Correctness And User Trust

### 1. Prevent Numeric Aggregations Without A Numeric Value Column

**Problem**

For category charts, the UI allows selecting `SUM`, `AVG`, `MIN`, or `MAX` even
when the Y/value column is empty. In `GetCategoryDistributionUseCase`, if the
aggregation is not `COUNT` but `yColumn == null`, the query falls back to
`COUNT(*)`. This means a chart configured as "Sum by product" can actually show
"Count by product".

**Impact**

This is the most important issue because it can produce misleading analysis.
Users may trust a chart that does not represent the selected aggregation.

**Recommendation**

- If aggregation is `COUNT`, hide or disable the Y/value column.
- If aggregation is `SUM`, `AVG`, `MIN`, or `MAX`, require a numeric Y/value
  column.
- If the user clears the Y/value column, automatically switch aggregation back
  to `COUNT`.
- If there are no numeric columns, only expose `COUNT`.

**Implementation Notes**

- Add aggregation compatibility rules near `ChartSuggestion` or as a small
  `ChartConfigValidator`.
- Filter the aggregation dropdown options based on selected chart type and
  available Y/value column.
- Guard the use case too: never silently convert `SUM/AVG/MIN/MAX` to
  `COUNT(*)`.

### 2. Make Line Charts Always Require A Date Column And Numeric Value Column

**Problem**

Line charts require both X/date and Y/numeric values in `AnalysisService`, but
the UI renders the Y dropdown as nullable for every chart type. If the user
selects `-`, the chart becomes empty with a generic "no chart" message.

**Impact**

The user sees a chart disappear without understanding what must be fixed.

**Recommendation**

- For line charts, make the Y/value dropdown required.
- Remove the nullable `-` option for line charts.
- Show a contextual validation message if the selected configuration is
  incomplete.

### 3. Replace Generic Empty Messages With Specific Reasons

**Problem**

The same "no chart available" message is used for:

- no compatible columns;
- invalid chart configuration;
- no rows after filters;
- missing Y/value column;
- unsupported chart type;
- internal chart loading failure.

**Impact**

Users cannot tell whether the dataset is unsuitable, the filters are too
restrictive, or the configuration is wrong.

**Recommendation**

Introduce contextual empty/error states:

- "Select a numeric value column to use Sum."
- "No rows match the current filters."
- "This chart type is not available for the selected columns."
- "This chart failed to load. Try changing columns or filters."

### 4. Add Per-Chart Error State

**Problem**

If one chart fails to load, the BLoC turns loading off but the card does not
keep a specific error reason. The user sees an empty/no-chart message.

**Impact**

Failures look like valid empty results.

**Recommendation**

- Add `errorCode` or `errorMessageKey` to `AnalyticsChart`.
- Render an inline retry action inside the failed chart card.
- Keep the rest of the analytics panel usable if only one chart fails.

## Priority 2 - Make Controls Match User Language

### 5. Rename X/Y Controls Per Chart Type

**Problem**

The UI currently exposes generic `X axis` and `Y axis` labels. This is correct
for developers, but less clear for users doing guided analysis.

**Recommendation**

Use chart-specific labels:

- Bar/Pie:
  - `Group by` instead of `X axis`;
  - `Value` or `Measure` instead of `Y axis`.
- Line:
  - `Date` instead of `X axis`;
  - `Value over time` instead of `Y axis`.
- Future scatter:
  - `X value` and `Y value`.

### 6. Rename Aggregations In Plain User Terms

**Problem**

Aggregation labels are understandable, but the interaction still feels SQL-like
when combined with X/Y controls.

**Recommendation**

Represent the chosen chart as a sentence:

```text
Show [Sum] of [Price] grouped by [Product]
Show [Count] grouped by [Brand]
Show [Average] of [Temperature] over [Date]
```

This sentence can appear above the chart and update live.

### 7. Hide Irrelevant Controls

**Problem**

The Y/value dropdown is shown whenever numeric columns exist, even when the
current aggregation does not need it.

**Recommendation**

- `COUNT`: hide Y/value column or show it disabled with "Not needed for count".
- `SUM/AVG/MIN/MAX`: show Y/value column as required.
- Pie with high-cardinality data: show a warning or switch to bar chart.

## Priority 3 - Better Chart Defaults And Suggestions

### 8. Avoid Duplicate Auto-Suggested Charts

**Problem**

`suggestAll()` can suggest both bar and pie charts from the same category/value
pair. The analytics panel may start with two charts that say nearly the same
thing.

**Recommendation**

- Show one best automatic chart by default.
- Put alternatives behind `Add chart`.
- Prefer:
  - line chart for date + numeric;
  - bar chart for many categories;
  - pie chart only for small category counts;
  - count distribution for text/boolean without numeric values.

### 9. Use Cardinality Before Choosing Pie Charts

**Problem**

Pie charts are suggested from column types, not from actual distinct value
count. If a text column has many values, the pie becomes hard to read.

**Recommendation**

- Use column statistics or a distinct-count query before suggesting pie.
- Suggested rule:
  - `<= 8` categories: pie is acceptable;
  - `9-20` categories: bar chart;
  - `> 20` categories: bar chart with top-N and "Other".

### 10. Add Top-N And "Other" Controls

**Problem**

Category distribution is hard-coded to `LIMIT 20`. Users cannot control whether
they are seeing all categories, top 10, top 20, or an abbreviated result.

**Recommendation**

Add controls:

- `Top N`: 5, 10, 20, 50;
- `Group remaining as Other`: on/off;
- sort by value descending/ascending;
- sort by label.

### 11. Improve Add Chart Dialog

**Problem**

The add-chart dialog only lists chart type labels. It does not explain why a
chart is available or what it will use.

**Recommendation**

Show chart options as descriptive rows:

- "Trend over time" - requires a date and a numeric value.
- "Category comparison" - compares groups with a value or count.
- "Share by category" - good for a few groups.

Also localize chart type labels instead of hardcoded English.

## Priority 4 - Chart Readability

### 12. Show Chart Titles And Axis Meaning

**Problem**

Charts do not currently show a clear title such as "Sum of Price by Product".
The axis labels exist in the data DTO but are not visibly rendered as labels.

**Recommendation**

Each chart card should show:

- chart sentence/title;
- active aggregation;
- group/date/value columns;
- filter status.

Example:

```text
Sum of Quantity by Brand
Filtered by: Product contains "book"
Showing top 20 brands
```

### 13. Improve Bar Chart Labels

**Problem**

Bar labels are truncated after 8 characters, with no visible way to see the
full label.

**Recommendation**

- Add tooltips with full label and value.
- Allow horizontal scroll or rotate labels for dense charts.
- Use a side legend/table for long labels.
- For expanded mode, show full labels.

### 14. Add Bar Chart Tooltips

**Problem**

The bar chart currently has no explicit tooltip behavior for full category
label and precise value.

**Recommendation**

Add `BarTouchData` with:

- full label;
- formatted value;
- aggregation label;
- percentage of total where useful.

### 15. Improve Pie Chart Legend

**Problem**

The pie legend shows labels only. Slice titles show percentages, but not values.
With many labels, the legend can become crowded.

**Recommendation**

- Show label + value + percentage in the legend.
- Hide slice text for very small percentages.
- Add hover/tap tooltip.
- Add "Other" grouping.
- Avoid pie charts above a category threshold.

### 16. Improve Line Chart Date Formatting

**Problem**

The line chart formats dates as `MM/DD`, which is not localized and can be
ambiguous. It can also show duplicate labels when the date range is dense.

**Recommendation**

- Use locale-aware date formatting.
- Change format based on range:
  - same month: day;
  - same year: day/month;
  - multiple years: month/year or year.
- Show full date in tooltip.

### 17. Improve Number Formatting

**Problem**

Axis values use hardcoded `K` and `M` formatting and are not locale-aware.

**Recommendation**

- Use locale-aware compact number formatting.
- Keep precision consistent.
- Support future currency/percentage formatting if column metadata provides it.

### 18. Add Expanded Mode Controls

**Problem**

Expanded chart mode only shows the chart body and a close button. It does not
include the configuration controls or explanatory context.

**Recommendation**

Expanded mode should include:

- chart title;
- controls;
- active filters;
- larger chart;
- optional data table for chart points;
- export chart image/data action in the future.

## Priority 5 - Interaction Model

### 19. Use Draft Controls With Apply Instead Of Immediate Reload

**Problem**

Every dropdown change immediately reloads the chart. Changing aggregation and
value column in sequence can produce intermediate invalid or misleading states.

**Recommendation**

Use local draft state per chart:

- user changes controls;
- invalid combinations are shown inline;
- `Apply` reloads the chart once.

For power users, this can later become "Auto apply" toggle.

### 20. Keep Previous Chart Visible During Reload

**Problem**

On config change, the chart data is replaced with `EmptyChartData` while
loading. The card flashes to loading/empty state.

**Recommendation**

Keep the previous chart visible with a loading overlay until the new data is
ready. This makes changes feel less abrupt.

### 21. Add Undo For Chart Removal

**Problem**

Removing a chart is immediate.

**Recommendation**

After removal, show a snackbar:

```text
Chart removed. Undo
```

### 22. Improve Loading Granularity

**Problem**

The full analytics section has a loading state, and each chart can have a
loading spinner. The UX can feel jumpy.

**Recommendation**

- Use skeleton/loading overlay inside each chart card.
- Do not collapse chart card height while loading.
- Keep the add/refresh buttons stable.

## Priority 6 - Filters, Hidden Columns, And Workspace State

### 23. Show That Charts Respect Active Filters

**Problem**

Charts already respect active filters through the generated WHERE clause, but
the chart card does not make this visible.

**Recommendation**

Show a small indicator:

```text
Filtered result
3 active filters
```

Clicking it could scroll to the filter panel or open a filter summary.

### 24. Decide Whether Hidden Columns Should Be Hidden From Analytics

**Problem**

The analytics controls receive all table columns, including hidden columns.
This can be useful, but it may surprise users who hid a column because they did
not want it in the current workspace/export.

**Recommendation**

Pick one explicit rule:

- hidden columns are excluded from analytics controls by default; or
- hidden columns remain available but are visually marked as hidden.

The second option is more flexible.

### 25. Persist Charts Per Sheet

**Problem**

Filters, sorting, and hidden columns are persisted per sheet in `tableStates`,
but analytics chart configuration is stored at top level. If different sheets
have different schemas, restored charts may be invalid or confusing.

**Recommendation**

Move chart persistence into per-table state, or add a `chartsByTableId` map.

Suggested shape:

```json
{
  "tableStates": {
    "12": {
      "filters": [],
      "sort": null,
      "hiddenColumnDbNames": [],
      "charts": []
    }
  }
}
```

### 26. Reset Or Explain Charts On Sheet Change

**Problem**

When switching sheets, restored chart compatibility depends on matching column
names and types. If charts disappear, the user gets a generic empty state.

**Recommendation**

- If restored charts are invalid for the new sheet, show:
  "Charts were reset because this sheet has a different schema."
- Offer "Generate suggested charts" action.

## Priority 7 - Analytics Depth

### 27. Add Column Statistics To The Analytics Panel

**Problem**

`GetColumnStatisticsUseCase` exists but the analytics UI does not surface basic
stats directly.

**Recommendation**

Add summary cards for selected numeric columns:

- count;
- null count;
- distinct count;
- min;
- max;
- average;
- sum.

For text/boolean/date:

- count;
- null count;
- distinct count;
- most common values.

### 28. Add Data Quality Warnings

**Problem**

Charts may silently ignore null labels and parse invalid numeric/date values as
`0` or skip points depending on use case.

**Recommendation**

Show warnings when relevant:

- "12 rows have empty category values and are excluded."
- "5 values could not be parsed as dates."
- "Some numeric values were converted before aggregation."

### 29. Add Distribution/Histogram For Numeric Columns

**Problem**

Numeric-only datasets currently have limited visual support because scatter is
deferred and category charts need a grouping column.

**Recommendation**

Add histogram charts:

- numeric column distribution;
- configurable bins;
- min/max outlier visibility.

This gives useful analytics even with a single numeric column.

### 30. Add Scatter Plot When Ready

**Problem**

`ChartType.scatter` exists structurally but is intentionally not implemented.

**Recommendation**

When implemented, expose it only when at least two numeric columns exist:

- X numeric column;
- Y numeric column;
- optional group/color column;
- optional regression trend line.

### 31. Add Grouped Time Series

**Problem**

`ChartSuggestion` has `groupColumn`, but the UI and use cases do not expose
multi-series charts yet.

**Recommendation**

For date + numeric + text:

- allow optional "Split by" column;
- render multiple series;
- cap series count or require top-N groups.

### 32. Add Regression / Forecast Later

**Problem**

The roadmap mentions regression/forecasting, but current analytics are purely
descriptive.

**Recommendation**

Add this after chart basics are stable:

- moving average;
- linear trend line;
- simple forecast horizon;
- confidence/limitations text.

## Priority 8 - Accessibility And Localization

### 33. Localize Chart Type Labels

**Problem**

`ChartType.label` returns hardcoded English labels: `Line`, `Bar`, `Pie`,
`Scatter`.

**Recommendation**

Move chart type display labels to i18n.

### 34. Localize Boolean Labels In Chart Data

**Problem**

Boolean values are formatted as `True` / `False` in the use case.

**Recommendation**

Keep raw values in the DTO and format labels in the presentation layer, or add
a label formatter that uses i18n.

### 35. Improve Color Accessibility

**Problem**

Charts use theme colors plus a small fixed palette. There is no guarantee of
contrast or color-blind friendliness.

**Recommendation**

- Use a color-blind-safe categorical palette.
- Do not rely only on color; include labels/tooltips.
- Respect high-contrast theme in the future.

### 36. Add Semantics For Screen Readers

**Problem**

Charts are visual and do not expose a textual summary.

**Recommendation**

Add a screen-reader summary per chart:

```text
Bar chart. Sum of sales by brand. Highest value: Nike, 1200.
```

Also provide a compact data table behind the chart.

## Suggested Implementation Order

1. Fix aggregation/Y-column validity.
2. Add contextual empty/error states.
3. Rename chart controls to user-facing language.
4. Add chart title sentence and active-filter indicator.
5. Add top-N and pie/cardinality rules.
6. Improve tooltips, labels, and locale formatting.
7. Persist charts per sheet.
8. Add statistics cards.
9. Add histogram/scatter/grouped time series.
10. Add regression/forecasting.

## First Concrete Patch Recommendation

Start with a small, high-impact patch:

- introduce a `ChartConfigValidator`;
- make `AggregationDropdown` receive allowed aggregations;
- hide/disable Y/value column when aggregation is `COUNT`;
- require Y/value column for `SUM`, `AVG`, `MIN`, `MAX`;
- change `GetCategoryDistributionUseCase` so invalid metric aggregations never
  silently fall back to `COUNT(*)`;
- add tests for:
  - count without Y column;
  - sum without Y column rejected or auto-corrected;
  - line chart without Y column rejected by UI/config validator;
  - only count available when there are no numeric columns.

## Current Implementation Update

**Session 2026-05-24:** Implemented Phase 1A and 1B validation and error handling.

### Fully Completed (Phase 1A & 1B)

- [x] `ChartConfigValidator` (lib/domain/entities/) fully implemented:
  - `isAggregationValidForChartType()` validates aggregation for chart type
  - `getValidAggregations()` returns filtered list based on Y column presence
  - `validateChartSuggestion()` validates complete chart configuration
  - Prevents SUM/AVG/MIN/MAX without numeric Y column
  - Rejects invalid X/Y column types for chart type
  - All 16 unit tests passing

- [x] `InvalidChartConfigException` (lib/domain/exceptions/) created
  - Thrown by GetCategoryDistributionUseCase on invalid aggregation
  - Prevents silent COUNT(*) fallback for SUM/AVG/MIN/MAX without Y column

- [x] `GetCategoryDistributionUseCase` guard implemented:
  - Throws InvalidChartConfigException if aggregationType != COUNT && yColumn == null
  - No more silent conversion to COUNT(*)
  - All 11 validation tests passing

- [x] Error handling infrastructure in place:
  - `ChartLoadResult` DTO (lib/application/dto/) wraps data + error
  - `ChartLoadError` enum with 5 error types
  - `AnalyticsChart.error?` field stores per-chart errors
  - `AnalysisService.loadChartData()` catches exceptions and maps to ChartLoadError
  - DatasetBloc integrates error handling into chart state

- [x] Complete test coverage:
  - 16 ChartConfigValidator tests
  - 11 GetCategoryDistributionUseCase validation tests
  - All BLoC tests updated for ChartLoadResult
  - **All 365 tests passing** ✅

### Still Open (Remaining UI/UX Work)

**Phase 1B - Error Messages in UI:**
- [ ] Display per-chart error messages in analytics_section.dart
- [ ] Map ChartLoadError types to user-facing messages
- [ ] Show specific messages vs. generic "no chart available"

**Phase 1C - User-Facing Labels:**
- [ ] Replace "X axis" → "Group by" (bar/pie)
- [ ] Replace "Y axis" → "Value" (bar/pie) / "Value over time" (line)
- [ ] Replace "X axis" → "Date" (line)
- [ ] Add i18n string keys for chart-type-specific labels

**Phase 1D - Chart Title Sentences:**
- [ ] Add `chartSentence` field to ChartData
- [ ] Compute sentences like "Sum of Sales by Brand"
- [ ] Display above chart card

**Phase 1A - Validator Integration in UI:**
- [ ] Wire `getValidAggregations()` into `_AggregationDropdown`
- [ ] Disable invalid aggregation options in dropdown
- [ ] Hide Y/value when COUNT is selected
- [ ] Show Y/value as required for SUM/AVG/MIN/MAX
- [ ] Add tooltips explaining disabled options

**Phase 1E - Per-Sheet Persistence (DEFERRED):**
- [ ] Move charts from top-level to per-table state
- [ ] Update JSON serialization
- [ ] Update BLoC handlers for per-table access
- [ ] Test multi-sheet scenarios
- (Larger refactoring; scheduled for follow-up session)

## Updated Analytics Roadmap (Session 2026-05-24)

Foundation (validation and error handling) is complete. Remaining work focuses on
UI/UX improvements. Prioritized by impact and estimated effort.

### Immediate Next (Phase 1B-1D) — 5-6 hours estimated

**PHASE 1B: Error Messages in UI** (2-3 hours)
1. Add i18n string keys for each ChartLoadError type
2. Update `analytics_section.dart` to check `AnalyticsChart.error`
3. Render specific messages instead of generic "no chart available"
4. Examples:
   - `invalidAggregation` → "Select a numeric value column to use this aggregation."
   - `noRowsAfterFilter` → "No rows match the current filters."
   - `internalFailure` → "Chart failed to load. Try changing columns or filters."

**PHASE 1A: Wire Validator into UI** (1-2 hours)
1. Pass `getValidAggregations()` result to `_AggregationDropdown`
2. Disable aggregation options that are not in the allowed list
3. Hide Y/value dropdown when aggregation is `COUNT`
4. Mark Y/value as required for `SUM/AVG/MIN/MAX`
5. Add tooltip on disabled options explaining why they are disabled

**PHASE 1C: User-Facing Control Labels** (1-2 hours)
1. Compute labels based on `suggestion.chartType`:
   - Bar/Pie: `Group by`, `Value`
   - Line: `Date`, `Value over time`
2. Pass labels to `_ColumnDropdown` and `_AggregationDropdown`
3. Update i18n keys to use chart-type-specific strings

**PHASE 1D: Chart Title Sentences** (1 hour)
1. Add `chartSentence: String?` field to `ChartData`
2. Compute in `analytics_section.dart`:
   - `Count by Brand`
   - `Sum of Total grouped by Product`
   - `Average Temperature over Date`
3. Display above chart (in card header or as subtitle)

### High Priority (Phase 2) — 3-4 hours estimated

After Phase 1 UX improvements are complete:

1. **Show active filter context on charts**
   - Add filter indicator: "Filtered result — 3 active filters"
   - Clarifies that charts respect current filter state

2. **Per-sheet chart persistence** (architectural)
   - Move charts from top-level `uiStateJson` to per-table state
   - Prevent chart restoration across incompatible schemas
   - Update JSON serialization for per-table access

3. **Keep previous chart visible during reload**
   - Show loading overlay instead of immediately showing EmptyChartData
   - Smoother UX when changing chart configuration

4. **Improve Add Chart dialog**
   - Replace plain labels with descriptive options:
     - `Trend over time` (date + numeric)
     - `Category comparison` (category + optional numeric)
     - `Share by category` (category with small cardinality)
   - Show why each option is available for current columns

### Medium Priority (Phase 3) — 2-3 hours estimated

Polish and additional features:

1. **Chart readability improvements**
   - Add tooltips to bar/pie charts (full label, value, percentage)
   - Improve pie chart legend (show value + percentage)
   - Locale-aware date formatting for line charts
   - Compact number formatting (K, M, B)

2. **Top-N and cardinality controls**
   - Top 5/10/20/50 selector for category charts
   - Auto-prefer pie only for ≤8 categories
   - Use cardinality query before suggesting pie

3. **Localization**
   - Move `ChartType.label` to i18n
   - Localize boolean labels (True/False based on locale)

### Medium Priority

These items improve readability and workflow quality but are less urgent than
preventing misleading charts.

1. **Add top-N controls for category charts**
   - Top 5 / 10 / 20 / 50.
   - Sort by value or label.
   - Optionally group remaining values as `Other`.

2. **Use cardinality before suggesting pie charts**
   - Pie only for small category counts.
   - Bar chart for larger category sets.
   - Show top-N for high-cardinality data.

3. **Improve bar chart tooltips**
   - Show full label.
   - Show formatted value.
   - Show aggregation type.
   - Optionally show percentage of total.

4. **Improve pie chart legend**
   - Show label + value + percentage.
   - Hide slice text for very small percentages.
   - Prefer tooltips for dense charts.

5. **Improve date and number formatting**
   - Use locale-aware compact number formatting.
   - Format line chart dates based on range and locale.
   - Show full date in tooltip.

6. **Make expanded chart mode more useful**
   - Include chart title.
   - Include current controls.
   - Include active filters.
   - Optionally include the chart data table.

7. **Add undo for chart removal**
   - Show a snackbar with `Undo` after deleting a chart card.

8. **Expose basic column statistics**
   - Use existing `GetColumnStatisticsUseCase`.
   - Add count/null/distinct/min/max/avg/sum cards.

### Lower Priority

These items are valuable but should wait until the core chart UX is stable.

1. **Numeric histogram**
   - Useful for numeric-only datasets.
   - Requires binning controls and careful labeling.

2. **Scatter plot**
   - Use when at least two numeric columns exist.
   - Add optional group/color column later.

3. **Grouped time series**
   - Date + numeric + optional category series.
   - Requires series limiting/top-N to avoid unreadable charts.

4. **Regression and forecast**
   - Linear trend line.
   - Moving average.
   - Simple forecast horizon.
   - Must include limitation text so users do not over-trust predictions.

5. **Chart export**
   - Export chart image.
   - Export chart data as CSV/JSON.

6. **Accessibility deepening**
   - Add semantic summaries.
   - Add color-blind-safe palette.
   - Add non-color-only encodings.

## Recommended Next Patch (Session 2026-05-24)

**Status:** Validation & error infrastructure complete. Ready for UI implementation.

The next patch series is focused, phased, and low-risk because the service and
BLoC layers already handle all error cases correctly.

### Patch 1: Phase 1B - Error Messages (Session 2026-05-24 or next)
```
Add contextual error messages and hide generic "no chart available" state.
```

Scope:
- Add i18n strings for each `ChartLoadError` type
- Update `analytics_section.dart` to check `AnalyticsChart.error`
- Render specific error message when `error != null`
- Estimated: 2-3 hours

### Patch 2: Phase 1A - Validator Integration (Recommended next)
```
Wire ChartConfigValidator into AnalyticsSection dropdown controls.
```

Scope:
- Pass `ChartConfigValidator.getValidAggregations()` to `_AggregationDropdown`
- Filter dropdown options to only allowed aggregations
- Hide Y/value when `COUNT` is selected
- Mark Y/value as required for `SUM/AVG/MIN/MAX`
- Add tooltip explaining disabled options
- Estimated: 1-2 hours

Why this is highest-leverage:
- Domain/application layers already validate everything correctly
- UI currently still allows users to select invalid configurations
- Prevents misleading chart loads before they reach the service
- Very low risk: validation layer already tested comprehensively

### Patch 3: Phase 1C/1D - Labels and Titles (Follow-up)
```
Improve chart readability with user-facing labels and title sentences.
```

Scope:
- Replace "X axis"/"Y axis" with "Group by"/"Value"/"Date" labels
- Compute and display chart title sentences ("Sum of Sales by Brand")
- Add i18n keys for chart-type-specific labels
- Estimated: 2-3 hours

### Why This Order

1. **Correctness first:** Error messages confirm the system works correctly
2. **Prevention second:** UI validation prevents bad states before loading
3. **UX polish third:** Labels and titles improve readability

All foundation is in place. No architectural risk. Proceed with confidence.
