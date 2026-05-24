# Analytics UI/UX Review & Roadmap

## Sommario dei Problemi Originali (36 punti)

Il sistema di analytics ha identificato 36 aree di miglioramento distribuite in 8 categorie:
1. **Correttezza e fiducia utente** - Prevenire chart che mostrano dati sbagliati
2. **Linguaggio user-friendly** - Usare termini chiari ("Group by" invece di "X axis")
3. **Chart defaults e suggerimenti** - Suggerimenti intelligenti in base ai dati
4. **Leggibilità chart** - Titoli, tooltip, formattazione
5. **Interaction model** - Draft mode, load overlay, undo
6. **Filtri e stato** - Mostrare context, persistenza per foglio
7. **Analytics depth** - Statistiche, histogram, scatter
8. **Accessibilità e localizzazione** - i18n, screen readers, colori

**Dettagli completi:** Consultare sezione "Priority 1-8" in fondo.

---

## 📋 ROADMAP - STATO ATTUALE E PROSSIMI PASSI

### ✅ COMPLETATO - Foundation Layer (Phase 1A + 1B)

**Commit:** `9a324c2` - Chart configuration validation e error handling

- ✅ **ChartConfigValidator** - Validazione domain layer
  - `isAggregationValidForChartType()` - Controlla aggregazione valida
  - `getValidAggregations()` - Filtra opzioni basate su Y column
  - `validateChartSuggestion()` - Validazione completa configuration
  - Previene SUM/AVG/MIN/MAX senza numeric Y column
  - 16 test ✅

- ✅ **GetCategoryDistributionUseCase guard**
  - Lancia `InvalidChartConfigException` se aggregazione invalida
  - Niente più fallback silenzioso a COUNT(*)
  - 11 test ✅

- ✅ **Error handling infrastructure**
  - `ChartLoadResult` DTO - wrappa data + error
  - `ChartLoadError` enum - 5 tipi di errore
  - `AnalyticsChart.error?` - errore per chart
  - Service layer cattura e mappa eccezioni
  - BLoC propaga errori a state
  - Tutti 365 test ✅

---

### 🔄 IN PROGRESS - UI/UX Layer (5-6 ore stimate)

#### **Phase 1B: Messaggi d'Errore in UI** (2-3 ore)
**Priority: ALTA** - Permette agli utenti di capire cosa è andato storto

✅ **COMPLETATO!** Il sistema di messaggi d'errore è già pienamente implementato:

- ✅ **i18n strings:** Già in place in en.json e it.json
  - `dataset.workspace.analytics.error_messages.invalid_aggregation`
  - `dataset.workspace.analytics.error_messages.no_rows_after_filter`
  - `dataset.workspace.analytics.error_messages.unsupported`
  - `dataset.workspace.analytics.error_messages.internal`
  - `dataset.workspace.analytics.error_messages.no_numeric_column`

- ✅ **AppStrings constants:** Mappati correttamente in app_strings.dart (lines 270-279)

- ✅ **UI Widget:** `_ChartErrorMessage` implementato in analytics_section.dart
  - Riceve `ChartLoadError` e mostra messaggio specifico
  - Chiamato da `_ChartBody` quando `error != null` (line 813-814)
  - Mappatura: `_errorMessage()` method (lines 888-900)

- ✅ **Integration:** `AnalyticsChart.error` passato correttamente dal BLoC (line 295 del card widget)

**Come funziona il flusso:**
1. BLoC riceve errore da service e lo mette in `AnalyticsChart.error`
2. Widget riceve `AnalyticsChart` e passa `error` a `_ChartBody`
3. `_ChartBody` mostra `_ChartErrorMessage` se error != null
4. `_ChartErrorMessage` mapperà l'errore al messaggio i18n

**Expected outcome:** ✅ User vede messaggio specifico che spiega il problema.

---

#### **Phase 1C: Etichette User-Friendly** (1-2 ore)
**Priority: ALTA** - Elimina linguaggio tecnico

- [ ] **Passo 1:** Rinominare controlli dropdown
  - Bar/Pie: `X axis` → `Group by`, `Y axis` → `Value`
  - Line: `X axis` → `Date`, `Y axis` → `Value over time`
  - Aggiungere i18n keys

- [ ] **Passo 2:** Update analytics_section.dart widget
  - Compute label based on `suggestion.chartType`
  - Pass labels a `_ColumnDropdown` e `_AggregationDropdown`
  - File: `lib/presentation/widgets/dataset_sections/analytics_section.dart`

**Expected outcome:** UI mostra "Group by Product" invece di "X axis: Product".

---

#### **Phase 1D: Chart Title Sentences** (1 ora)
**Priority: MEDIA** - Contesto naturale per ogni chart

- [ ] **Passo 1:** Aggiungere field a ChartData DTO
  - `chartSentence: String?`
  - File: `lib/application/dto/chart_data.dart`

- [ ] **Passo 2:** Compute sentence in analytics_section.dart
  - Examples: "Count by Brand", "Sum of Sales by Product", "Average Temperature over Date"
  - Format: `{aggregation} of {yColumn} grouped by {xColumn}` oppure `{aggregation} over {xColumn}`

- [ ] **Passo 3:** Display sentence nel chart card
  - Sopra il chart o come subtitle
  - File: `lib/presentation/widgets/dataset_sections/analytics_section.dart`

**Expected outcome:** Chart mostra "Sum of Sales by Brand" - contesto immediato.

---

#### **Phase 1A: Validator Integration in UI** (1-2 ore)
**Priority: MASSIMA** - Previene invalid config prima del caricamento

- [ ] **Passo 1:** Integrare ChartConfigValidator nel dropdown
  - Disabilitare opzioni non valide in `_AggregationDropdown`
  - Nascondere Y column quando `COUNT` è selezionato
  - Marcare Y come required per `SUM/AVG/MIN/MAX`
  - File: `lib/presentation/widgets/dataset_sections/analytics_section.dart`

- [ ] **Passo 2:** Aggiungere tooltip
  - "Non disponibile - nessuna colonna numerica selezionata"
  - "Richiesta per questa aggregazione"

**Expected outcome:** UI previene selezione di config invalide, disabling visual.

---

### ⏸️ DEFERRED - Architectural (Prossima sessione)

#### **Phase 1E: Per-Sheet Chart Persistence** (3-4 ore)
**Priority: MEDIA** - Architettura, non urgente

- [ ] Spostare charts da top-level a per-table state
- [ ] Update JSON serialization
- [ ] Update BLoC handlers
- [ ] Test multi-sheet scenarios

---

## 📊 TIMELINE STIMATO

| Phase | Ore | Status |
|-------|-----|--------|
| Phase 1A+1B Foundation | ✅ | Completato - Tutti test passing |
| Phase 1B Error Messages | 2-3 | **IN PROGRESS** |
| Phase 1C Labels | 1-2 | **PENDING** |
| Phase 1D Titles | 1 | **PENDING** |
| Phase 1A UI Integration | 1-2 | **PENDING** |
| **Totale Fase 1** | **5-6** | **In progress** |
| Phase 1E Per-Sheet | 3-4 | Deferred |

---

## 🎯 SUCCESS CRITERIA

Dopo completamento Phase 1B-1D:

- ✅ Messaggi d'errore specifici invece di "no chart available"
- ✅ Etichette user-friendly ("Group by", "Value", "Date")
- ✅ Chart title sentences visible per ogni chart
- ✅ UI previene selezione config invalide
- ✅ Tutti test passan do (aggiunti nuovi test per UI)
- ✅ Documentazione aggiornata

---

## 📝 PRIORITY 1-8 ORIGINALI (Dettagli completi)

### Priority 1 - Correctness And User Trust

**1. Prevent Numeric Aggregations Without A Numeric Value Column**
- ✅ SOLVED by ChartConfigValidator
- ✅ SOLVED by GetCategoryDistributionUseCase guard
- 🔄 TODO: UI validation to prevent selection

**2. Make Line Charts Always Require A Date Column And Numeric Value Column**
- ✅ SOLVED by ChartConfigValidator
- 🔄 TODO: UI to show as required

**3. Replace Generic Empty Messages With Specific Reasons**
- 🔄 TODO: Phase 1B - Error messages

**4. Add Per-Chart Error State**
- ✅ SOLVED by ChartLoadError enum + AnalyticsChart.error field

### Priority 2 - Make Controls Match User Language

**5. Rename X/Y Controls Per Chart Type**
- 🔄 TODO: Phase 1C - User-facing labels

**6. Rename Aggregations In Plain User Terms**
- 🔄 TODO: Phase 1C + Phase 1D

**7. Hide Irrelevant Controls**
- 🔄 TODO: Phase 1A UI - Hide Y when COUNT

### Priority 3 - Better Chart Defaults

**8-11.** Chart suggestions, cardinality rules, top-N controls
- ℹ️ DEFERRED: Not blocking core functionality

### Priority 4 - Chart Readability

**12. Show Chart Titles And Axis Meaning**
- 🔄 TODO: Phase 1D - Chart title sentences

**13-17.** Bar labels, tooltips, pie legend, date formatting, number formatting
- ℹ️ DEFERRED: Polish improvements

### Priority 5 - Interaction Model

**19-22.** Draft mode, keep previous visible, undo, loading granularity
- ℹ️ DEFERRED: UX polish

### Priority 6 - Filters, Hidden Columns, Workspace State

**23-26.** Filter indicators, hidden column handling, per-sheet persistence
- 🔄 TODO: Phase 1E (deferred)

### Priority 7 - Analytics Depth

**27-32.** Statistics cards, data quality warnings, histogram, scatter, grouped time series
- ℹ️ DEFERRED: Future enhancements

### Priority 8 - Accessibility

**33-36.** Localization, chart labels, color accessibility, screen readers
- 🔄 TODO: Phase 1C+1D (i18n)
- ℹ️ DEFERRED: Advanced accessibility

---

## 🚀 PROSSIMO COMANDO

Procediamo con **Phase 1B: Error Messages in UI**

Inizia con: Aggiungere i18n strings e update analytics_section.dart per mostrare messaggi d'errore specifici.
