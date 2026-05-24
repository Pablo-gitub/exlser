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

### ✅ COMPLETATO - UI/UX Layer (Tutte le fasi implementate)

#### **Phase 1B: Messaggi d'Errore in UI** ✅ COMPLETATO
**Priority: ALTA** - Permette agli utenti di capire cosa è andato storto

✅ **COMPLETATO!** Il sistema di messaggi d'errore è pienamente implementato:

- ✅ **i18n strings:** Tutti in place in en.json e it.json
- ✅ **AppStrings constants:** Mappati correttamente in app_strings.dart
- ✅ **UI Widget:** `_ChartErrorMessage` implementato in analytics_section.dart (lines 856-902)
- ✅ **Integration:** `AnalyticsChart.error` propagato dal BLoC
- ✅ **Tests:** 365 test passing, inclusi 11 test di validazione per eccezioni

---

#### **Phase 1C: Etichette User-Friendly** ✅ COMPLETATO
**Priority: ALTA** - Elimina linguaggio tecnico

✅ **COMPLETATO!** Etichette specifiche per tipo di chart:

- ✅ **_xColumnLabel()** (line 698): Ritorna etichette in base al chartType
  - Line: `AppStrings.datasetWorkspaceAnalyticsDate` → "Date"
  - Bar/Pie: `AppStrings.datasetWorkspaceAnalyticsGroupBy` → "Group by"
  - Scatter: `AppStrings.datasetWorkspaceAnalyticsXColumn` → "X axis"

- ✅ **_yColumnLabel()** (line 709): Ritorna etichette specifiche
  - Line: `AppStrings.datasetWorkspaceAnalyticsValueOverTime` → "Value over time"
  - Bar/Pie: `AppStrings.datasetWorkspaceAnalyticsValue` → "Value"
  - Scatter: `AppStrings.datasetWorkspaceAnalyticsYColumn` → "Y axis"

- ✅ **Integration:** Usate in analytics_section.dart linee 375 e 386
- ✅ **i18n:** Tutti gli i18n keys presenti in en.json e it.json

---

#### **Phase 1D: Chart Title Sentences** ✅ COMPLETATO
**Priority: MEDIA** - Contesto naturale per ogni chart

✅ **COMPLETATO!** Titoli descrittivi già calcolati e mostrati:

- ✅ **_chartSentence()** (line 718): Computa titoli come:
  - "Count by {group}" - per conteggi su categorie
  - "Count over {date}" - per conteggi nel tempo
  - "{aggregation} of {value} by {group}" - es. "Sum of Sales by Brand"
  - "{aggregation} of {value} over {date}" - es. "Average Price over Date"

- ✅ **Display:** Titolo mostrato nella chart card header (line 334)
- ✅ **i18n:** Template strings mappati a AppStrings:
  - `datasetWorkspaceAnalyticsTitleCountBy`
  - `datasetWorkspaceAnalyticsTitleCountOver`
  - `datasetWorkspaceAnalyticsTitleAggregationBy`
  - `datasetWorkspaceAnalyticsTitleAggregationOver`

---

#### **Phase 1A UI: Validator Integration in UI** ✅ COMPLETATO
**Priority: MASSIMA** - Previene invalid config prima del caricamento

✅ **COMPLETATO!** Validator integrato nei dropdown:

- ✅ **Integration:** `ChartConfigValidator.getValidAggregations()` usato in line 321-324
- ✅ **Dropdown Filtering:** `_AggregationDropdown` riceve solo opzioni valide (line 404)
  - Solo aggregazioni valide sono mostrate nel dropdown
  - Dropdown disabilitato se nessuna opzione disponibile
- ✅ **Y Column Logic:** Nascosto automaticamente quando COUNT è selezionato (line 407-410)
- ✅ **Exception Guard:** `GetCategoryDistributionUseCase` lancia exception per config invalide
- ✅ **Tests:** 11 test specifici per la validazione delle aggregazioni

---

### ⏸️ DEFERRED - Architectural (Prossima sessione)

#### **Phase 1E: Per-Sheet Chart Persistence** (3-4 ore)
**Priority: MEDIA** - Architettura, non urgente

- [ ] Spostare charts da top-level a per-table state
- [ ] Update JSON serialization
- [ ] Update BLoC handlers
- [ ] Test multi-sheet scenarios

---

## 📊 TIMELINE COMPLETATO

| Phase | Ore | Status |
|-------|-----|--------|
| Phase 1A Foundation (Validator) | ✅ | Completato - 16 test |
| Phase 1B Error Messages | ✅ | Completato - Implementato |
| Phase 1C User-Friendly Labels | ✅ | Completato - 2 metodi |
| Phase 1D Chart Title Sentences | ✅ | Completato - 1 metodo |
| Phase 1A UI Validator Integration | ✅ | Completato - Integrato |
| **Totale Fase 1** | **~5-6** | **✅ COMPLETATO** |
| Phase 1E Per-Sheet Persistence | 3-4 | ⏸️ Deferred |

---

## 🎯 SUCCESS CRITERIA - ✅ TUTTI RAGGIUNTI

- ✅ Messaggi d'errore specifici (`ChartLoadError` enum con 5 tipi)
- ✅ Etichette user-friendly ("Group by", "Value", "Date", "Value over time")
- ✅ Chart title sentences visible per ogni chart
- ✅ UI previene selezione config invalide (dropdown disabilitati/filtrati)
- ✅ Tutti 365 test passing (inclusi 27 nuovi test per validator e handler)
- ✅ Documentazione aggiornata (questo file)
- ✅ Validazione a livello domain + service + UI
- ✅ Error propagation complete: BLoC → Widget → User message

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

## 🚀 PROSSIMO PASSO

**Phase 1E: Per-Sheet Chart Persistence** (ArchitectureL refactor, deferred)

Attualmente i charts sono salvati a livello top-level del dataset. Per una migliore UX:
- Charts dovrebbero essere indipendenti per ogni sheet
- Quando cambi sheet, visualizzi solo i charts di quel sheet
- Ogni sheet mantiene la propria configurazione di charts

**Timeline:** 3-4 ore (non urgente - attualmente i charts funzionano, solo l'UX di sheet-switching potrebbe essere migliorata)

**Oppure:** Se consideri la Fase 1 completata, puoi procedere con altri miglioramenti analitici come:
- Scatter charts (per data correlazione tra due colonne numeriche)
- Statistics cards (media, mediana, deviazione standard)
- Data quality warnings (valori nulli, outliers)
- Histogram charts
- Grouped time series aggregation
