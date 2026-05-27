### **Piano di Refattorizzazione – Fase 1 e 2: Storia Architetturale**

---

[Readme](README.md) · [Refactoring Plan (English)](REFACTORING_PLAN.md)

---

# Panoramica

Exlser si è evoluto in due fasi architetturali distinte:

**Fase 1** ha trasformato un semplice filtro Excel in memoria in una codebase Clean Architecture.

**Fase 2** ha sostituito tutta la gestione dati in memoria con un core di persistenza relazionale costruito su Drift (SQLite).

Entrambe le fasi sono completate. Questo documento registra le decisioni prese, i vincoli che hanno affrontato e il debito tecnico residuo.

---

# Fase 1 (Completata)

**Obiettivo:** introdurre disciplina architetturale in un'app Flutter in crescita.

Cambiamenti introdotti:
- Separazione dei layer Clean Architecture (`core`, `domain`, `data`, `application`, `presentation`)
- Isolamento del domain layer (entità, interfacce repository, value objects)
- Use case layer per tutte le operazioni di business
- Astrazione dei repository (il domain dipende da interfacce, non da implementazioni)
- Layer presentation ibrido Riverpod/BLoC
- Unit test per la logica di dominio

Limitazioni risolte dalla Fase 2:
- I dati erano ancora in memoria — nessuna persistenza tra sessioni
- Il filtraggio non scalava oltre dataset piccoli
- Nessuna inferenza tipizzata dello schema
- Nessuna gestione dei dataset

---

# Fase 2 (Completata)

**Obiettivo:** sostituire tutta la gestione dati in memoria con un layer di persistenza relazionale locale.

## Gestione Stato Presentation

La Fase 2 ha consolidato la strategia ibrida di state management:

- **Riverpod** gestisce provider applicativi, dependency wiring, routing, settings, ViewModel leggeri e stato temporaneo della UI, incluso il wizard di import.
- **BLoC** gestisce il workspace dataset, dove lo stato è guidato da eventi: dataset aperto, sheet attivo, filtri, ordinamento, righe caricate, refresh, modalità di visualizzazione e analytics.

Questa separazione mantiene semplice il flusso di import e lascia al workspace dataset una struttura più forte per crescere.

---

## 1️⃣ Layer Database con Drift

```
core/database/
├── app_database.dart
├── connection/
├── tables/
├── daos/
```

Tabelle core introdotte:
- `datasets` — metadati dataset (nome, file sorgente, created_at, ui_state)
- `dataset_tables` — metadati foglio (nome originale, nome SQL-safe, conteggio righe)
- `dataset_columns` — schema colonna (nome originale, nome DB, tipo, nullable, stats)
- `dataset_files` — riferimenti file (path, modalità storage)

Ogni foglio importato genera anche la propria tabella SQL dinamica a runtime.

---

## 2️⃣ Motore di Inferenza dello Schema

Processo:
1. Lettura delle prime N righe (200) dal file importato
2. Inferenza del tipo per ogni colonna (TEXT, INTEGER, REAL, DATE, BOOLEAN)
3. Rilevamento della nullability
4. Presentazione dello schema inferito all'utente per revisione e correzione
5. Alla conferma: creazione della tabella relazionale e popolamento righe

Tipi supportati: TEXT, INTEGER, REAL, DATE, BOOLEAN.

---

## 3️⃣ Filtraggio SQL

Prima della Fase 2:
```
Filtraggio su List<Entity> in memoria
```

Dopo la Fase 2:
```
Generazione clausole SQL WHERE da oggetti FilterCondition tipizzati
```

Vantaggi:
- Scalabile su dataset di grandi dimensioni
- Filtri numerici e date type-correct
- 16+ operatori, ognuno mappato a un frammento SQL
- Filtri serializzati in JSON e persistiti per sheet

---

## 4️⃣ Persistenza dei Dataset

Ogni sessione dataset salva:
- Nome file sorgente e riferimento file
- Stato UI (filtri, ordinamento, colonne nascoste) come JSON per sheet
- Metadati tabelle e colonne
- Tutte le righe dati in tabelle SQL dinamiche

Abilita:
- Riapertura sessioni precedenti senza re-import
- Fondamenta per l'analisi cross-dataset
- Ripristino storico dello stato filtri

---

## 5️⃣ Estensioni Future

- Aggregazioni cross-sheet e multi-dataset (v0.5.0)
- Statistiche avanzate e analytics
- Modelli di regressione e forecast
- Motore di confronto multi-dataset

---

# Flusso Architetturale

```
File (CSV/XLSX)
  → Parser (SpreadsheetParser / ParserFactory)
  → Inferenza schema (PreparedImportResult)
  → Conferma utente (ConfirmedImport)
  → CreateDatasetService (Drift: tabelle + colonne + righe)
  → QueryRepository (SELECT / filtro / sort / paginate)
  → Stato BLoC workspace
  → UI
```

---

# Strategia di Branch

Entrambe le fasi di refactoring sono atterrate su `main`.
Tutto lo sviluppo corrente avviene su `main` o su feature branch mergiati in `main`.

---

# Debito Tecnico

| Elemento | Stato |
|---|---|
| CI si attiva a ogni push (non solo su tag) | Aperto — refactor CI pianificato |
| Valutazione formule nelle celle Excel non gestita | Aperto |
| Riferimenti file web temporanei (nessun path persistente) | By design — vincolo WASM |
| Import batch di più file | Non ancora implementato (v0.5.0+) |
| Settings oltre la selezione lingua | Pianificato per v0.6.0 |

---

# Obiettivo Finale

Non solo un'app Flutter.

Uno strumento di analisi dati strutturato, estensibile e localmente persistente — e una dimostrazione pubblica di come Clean Architecture scala in un progetto Flutter reale.
