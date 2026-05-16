### **Piano di Refattorizzazione – Fase 2: Architettura Data-Driven**

---

[Readme](README.md)

[Refactoring Plan (English)](REFACTORING_PLAN.md)

---

# Panoramica

ExcelCategory sta evolvendo da:

> Semplice utility di filtraggio Excel in memoria

a:

> Motore di elaborazione dati persistente, relazionale e data-driven.

La prima fase di refactoring ha introdotto la Clean Architecture.  
La seconda fase introduce un core relazionale persistente basato su Drift (SQLite).

---

# Fase 1 (Completata)

- Fondamenta di Clean Architecture
- Isolamento del Domain Layer
- Astrazione dei Repository
- Introduzione dei UseCase
- Presentazione ibrida Riverpod/BLoC
- Test unitari per la logica di dominio

Limitazioni della Fase 1:

- I dati sono ancora mantenuti in memoria
- Il filtraggio non è scalabile su dataset di grandi dimensioni
- Non esiste persistenza dei dataset
- Non è presente un sistema di inferenza tipizzata delle colonne

---

# Fase 2 (In Corso)

## 🎯 Obiettivo

Trasformare ExcelCategory in uno strumento analitico con persistenza dati locale.

## Gestione Stato Presentation

La Fase 2 usa una strategia ibrida:

- Riverpod gestisce provider applicativi, dependency wiring, routing, settings, ViewModel leggeri e stato temporaneo della UI, incluso il wizard di import.
- BLoC gestisce il workspace dataset, dove lo stato e' guidato da eventi: dataset aperto, sheet attivo, filtri, ordinamento, righe caricate, refresh, modalita' di visualizzazione e future interazioni analytics.

Questa separazione mantiene semplice il flusso di import e lascia al workspace dataset una struttura piu' forte per crescere.

---

## 1️⃣ Introduzione del Layer Database con Drift

```

core/database/
├── app_database.dart
├── connection/
├── tables/
├── daos/

```

### Nuove Tabelle Core

- datasets
- dataset_tables
- dataset_columns
- tabelle dinamiche generate per ogni foglio Excel

---

## 2️⃣ Motore di Inferenza dello Schema

- Lettura delle prime N righe (es. 200)
- Inferenza del tipo di dato per ogni colonna
- Conferma opzionale da parte dell’utente
- Creazione dinamica della tabella relazionale
- Popolamento dei dati nel database

Tipi supportati:

- TEXT
- INTEGER
- REAL
- DATE
- BOOLEAN

---

## 3️⃣ Sostituzione del Filtraggio in Memoria

Prima:
```

Filtraggio su List<ExcelDataEntity>

```

Dopo:
```

Filtraggio tramite clausole SQL (WHERE)

```

Vantaggi:

- Prestazioni significativamente superiori
- Supporto reale a filtri numerici e intervalli di date
- Scalabilità su dataset di grandi dimensioni

---

## 4️⃣ Persistenza dei Dataset

Ogni sessione di lavoro conterrà:

- Nome file sorgente
- Hash del file (opzionale ma consigliato)
- Stato UI (filtri, ordinamenti, ecc.)
- Metadati delle tabelle
- Metadati delle colonne

Permette:

- Riapertura dei lavori precedenti
- Confronto tra dataset differenti
- Analisi storica dei dati

---

## 5️⃣ Estensioni Future

- Aggregazioni (GROUP BY)
- Motore statistico
- Modelli di regressione (TensorFlow Lite)
- Moduli di calcolo ad alte prestazioni (Rust)
- Sistema di confronto tra dataset multipli

---

# Direzione Architetturale

Il sistema evolverà nel seguente flusso:

Excel → Schema Mapper → Database Drift → Query Engine → UI

---

# Visione a Lungo Termine

ExcelCategory diventa:

- Un lightweight BI tool locale
- Una piattaforma di analisi dati offline
- Un progetto dimostrativo di architettura software avanzata

---

# Strategia di Branch

Branch corrente:

```

refactor/architectural_refactoring

```

---

# Debito Tecnico da Affrontare

- CI che builda a ogni push
- Miglioramento della strategia di release
- Gestione corretta delle formule Excel
- Introduzione di filtri tipizzati nella UI

---

# Obiettivo Finale

Non solo un’app Flutter.

Ma uno strumento dati strutturato, estensibile e architetturalmente solido.
