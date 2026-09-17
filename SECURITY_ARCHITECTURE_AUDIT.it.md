# Audit architetturale e di sicurezza — Exlser

**Data:** 2026-09-17
**Branch analizzato:** `feature/multi-table-detection` (15 commit sopra `main`, +8793 righe)
**Baseline verificata:** `flutter analyze` pulito · 687 test verdi · i18n 386 chiavi × 9 locale, 0 mancanti ·
delete chain completa (include `dataset_relationships`) · `schemaVersion 4` con migrazione corretta ·
nessun permesso `INTERNET` nel manifest di release · `npm audit` landing page: 0 vulnerabilità

Legenda priorità: **P0** blocca il merge · **P1** da chiudere prima della prossima release ·
**P2** debito tecnico da pianificare · **P3** rifinitura

---

## 1. Table overview (`dataset_tables_graph_overview.dart`) — bug confermati

**Tutti chiusi il 2026-09-17.** Analyzer pulito, suite da 687 → **713 test** verdi, i18n 391 chiavi × 9 locale.

- [x] **P0 — Le relazioni salvate non vengono mai disegnate.**
      Il widget ora legge `loadRelationships(datasetId)` al mount e dopo ogni salvataggio, e le passa
      al layout builder come un join sintetico per relazione: riaprendo il workspace i collegamenti
      confermati sono già sul grafo.
      *Test:* `draws the relationships already saved for the dataset`.

- [x] **P0 — Il pannello compare anche con una sola tabella.**
      Doppia guardia: `dataset_view.dart` non lo monta sotto 2 tabelle e il widget stesso ritorna
      `SizedBox.shrink()` (protegge ogni futuro call site, e non legge nemmeno le relazioni).
      *Test:* `renders nothing when the dataset has a single table`.

- [x] **P1 — Errori silenziati e salvataggio non atomico.**
      Snackbar dedicate per generazione e salvataggio falliti, e salvataggio in blocco con esito
      esplicito: `Saved {saved} of {total} connections.` quando solo una parte passa.
      *Test:* `reports a failed generation…`, `reports a failed save…`,
      `tells the user how many connections a partial save stored`.

- [x] **P1 — Canvas a 320px fissi senza fit-to-content.**
      Zoom-to-fit automatico al primo layout (e dopo cambio scope, reset layout, riapertura) più il
      pulsante "Adatta alla vista"; le card sono limitate a 8 colonne con una riga "+N altre colonne",
      tenendo sempre visibili le colonne collegate.
      *Test:* `fits the whole graph inside the canvas on first layout`,
      `caps the columns a card renders and counts the rest`,
      `keeps a connected column visible even when the card is capped`.
      **Bug trovato durante il fix:** `getMaxScaleOnAxis()` misura anche l'asse z, che lo zoom lasciava
      a 1.0 — ogni zoom-out veniva letto come scala 1.0 e il clamp non funzionava. Ora la scala è
      uniforme sui tre assi, come fa `InteractiveViewer` internamente.

- [x] **P1 — Layout perso a ogni refresh.**
      Le posizioni dei nodi sono persistite in `uiStateJson` (`graphNodePositions`) tramite
      `UpdateGraphNodePositionsEvent`, ripristinate al load e reimpostate a vuoto dal reset layout.
      *Test:* `restores a saved node layout and persists a dragged one`, più il round-trip JSON e i
      due test sul bloc (incluso lo scarto di posizioni non finite).

- [x] **P2 — `_hoveredTableId` appiccicato.**
      L'hover non governa più `panEnabled`: conta solo se un gesto ha preso un nodo
      (`_draggingTableId` / `_pointerDownTableId`), entrambi azzerati su up e cancel. Una card
      ricostruita mentre è sotto il puntatore non può più bloccare il canvas.
      *Test:* `hovering a card leaves the canvas pannable, a pointer down on it does not`.

- [x] **P2 — Touch: primo drag che pana il canvas — NON era un bug.**
      Verificato: il test preesistente `dragging table node moves it without panning canvas` usa già
      un pointer touch e passa, perché la gesture arena assegna il gesto al recognizer più interno
      (il nodo) indipendentemente da `panEnabled`. Nessuna modifica necessaria; il gate su
      pointer-down resta come cintura di sicurezza per i gesti successivi.

- [x] **P2 — `_handlePointerSignal` era codice morto.**
      Confermato sperimentalmente: con uno scroll di 100px la scala risultava 0.9169 (il floor di
      boundary di `InteractiveViewer`) e non `exp(-100/250)` = 0.670 della formula custom — il
      `Listener` interno del viewer vince sempre il `PointerSignalResolver`. Rimosse le ~35 righe e il
      `Listener` esterno; l'isolamento della rotella dalla pagina resta garantito dal viewer stesso.
      *Test:* `mouse wheel over the canvas zooms without scrolling the page`.

- [x] **P2 — Connettore agganciato alla colonna sbagliata.**
      I quattro `firstWhere(orElse: () => columns.first)` in `join_graph_models.dart` sono sostituiti
      da una ricerca nullable che **scarta** la connessione: nessuna curva inventata e nessuno
      `StateError` su una tabella senza colonne.
      *Test:* `skips a confirmed join whose column is missing…`, `skips a suggestion whose column…`.

- [x] **P2 — Layout ricalcolato a ogni rebuild.**
      `JoinGraphData` è memoizzato su una chiave che copre tabelle, colonne, tabella attiva, scope,
      relazioni, suggerimenti e revisione delle posizioni: un rebuild non correlato riusa l'istanza,
      un drag la invalida.
      *Test:* `reuses the computed layout across unrelated rebuilds`.

- [x] **P2 — Salvataggio O(N²).**
      Nuova `CreateDatasetRelationshipsUseCase`: una sola `listForDataset`, dedup in memoria (contro
      lo stored e dentro il batch stesso) ed esito tripartito created/skipped/failed.
      *Test:* 6 casi in `create_dataset_relationships_usecase_test.dart`.

- [x] **P3 — Tripla affordance.**
      Rimosso il bottone `combine_sheets_button` da `dataset_view`; il pulsante "Modifica" della
      overview è ora sempre disponibile con ≥2 tabelle ed è l'unico ingresso al Combine Sheets, oltre
      allo `SheetSelector` che resta come selettore semplice. Il test di navigazione del router usa
      ora quel pulsante. *(Unica scelta di prodotto del lotto: banale da rimettere se preferisci
      tenere il bottone separato.)*

---

## 2. Sicurezza

- [ ] **P0 — Bypass del `ReadOnlySqlValidator` con join a virgola (dimostrato empiricamente).**
      Entrambe queste query superano la validazione:
      ```sql
      SELECT * FROM sheet, ds_99_secret
      SELECT name, sql FROM sheet, sqlite_master
      ```
      `_referencedTables` riconosce solo identificatori dopo `FROM`/`JOIN`
      (`read_only_sql_validator.dart:131`): si leggono le tabelle di altri dataset e l'intero schema
      del database. Impatto reale locale limitato (single-user), ma è il confine di sicurezza
      dichiarato in AGENTS.md.
      *Fix:* validare con `sqlparser` (già dipendenza transitiva di drift) invece che a regex.

- [ ] **P1 — Denylist di keyword sull'SQL grezzo: falsi positivi e sicurezza apparente.**
      `SELECT * FROM sheet WHERE note = 'update'` viene rifiutato (verificato); idem `--` dentro una
      stringa. *Fix:* rimuovere i literal prima dello scan keyword, o affidarsi al parser.

- [ ] **P1 — `executeRawQuery` non valida nulla.**
      `query_repository_impl.dart:431` è un passthrough usato da 6 call site (analytics, sampling
      relazioni, preview multi-sheet): il "choke point unico" esiste solo se il chiamante si ricorda
      di passare dal validator. *Fix:* rendere il passthrough privato e imporre la validazione in ingresso.

- [ ] **P1 — Identificatori interpolati senza quoting.**
      `SELECT DISTINCT $col FROM $table`, `SELECT $fn($col) FROM $table`
      (`query_repository_impl.dart:244`, `:312`) e `CREATE TABLE $tableName (...)`
      (`dynamic_table_builder.dart:39`). Tutta la sicurezza poggia sui sanitizer.
      *Fix:* quotare sempre (`"name"`) come difesa in profondità.

- [ ] **P1 — Due classi `SqlNameSanitizer` diverse, e i nomi tabella usano quella debole.**
      `core/normalizers/sql_name_sanitizer.dart` gestisce cifra iniziale, dedup e 30 keyword;
      `data/adapters/sanitizers/sql_name_sanitizer.dart` no — ed è quella importata da
      `create_dataset_table_usecase.dart:1`. Inoltre la wizard valida i duplicati sulle **label**
      (`import_dialog_viewmodel.dart:263`), non sul nome SQL finale: "Vendite 2024" e "Vendite-2024"
      passano la UI e collidono entrambe su `ds_N_vendite_2024` → import che fallisce in transazione.
      *Fix:* una sola classe, con dedup sul nome SQL generato.

- [ ] **P1 — Nessun isolate e nessun limite di dimensione file.**
      `compute(` / `Isolate.run`: 0 occorrenze in `lib/`. Parsing, boundary detection, type inference
      e mapping righe girano sull'isolate UI, con l'intero CSV decodificato in memoria
      (`csv_parser.dart:68`): freeze e OOM su file grandi, e sul web blocca l'unico thread.

- [ ] **P1 — `_recursiveCut` senza limite di profondità.**
      `table_boundary_detector.dart:298`, ricorsione a `:420` e `:438`: un foglio con righe vuote
      alternate (pattern comune negli export) porta la profondità a ~N/2 → stack overflow.
      *Fix:* worklist esplicita + cap sul numero di blocchi rilevati.

- [ ] **P2 — Dipendenze indietro dove conta.**
      `sqlite3_flutter_libs ^0.6.0+eol` (linea **EOL**: nessun fix CVE sulla lib nativa) e
      `excel_community 1.0.9` vs 2.4.0 — è il parser che macina file non fidati, cioè la superficie
      d'attacco principale. Poi `file_picker 10→13`, `flutter_riverpod 2.6→3.4`, `go_router 17→18`,
      `share_plus 11→13`, `sqlite3_web 0.5→0.9.4`, `sqlite3 3.1.6→3.5.2`.

- [ ] **P2 — La CI non fa da gate.**
      `dart.yml` è solo `workflow_dispatch`; gli altri workflow scattano solo su tag. Analyzer e test
      non girano su push/PR: la regola "verdi prima di `main`" è affidata alla disciplina manuale.

---

## 3. Architettura e manutenibilità

- [ ] **P1 — Violazioni della direzione delle dipendenze.**
      `domain → data`: `create_dataset_table_usecase.dart`, `infer_schema_usecase.dart`,
      `detect_matrix_table_usecase.dart`. `domain → application`: i due use case analytics che
      importano `application/dto/chart_data.dart`. `application → presentation` (la peggiore):
      `analysis_service.dart:13` e `chart_load_result.dart:2` importano `presentation/state/dataset_state.dart`.

- [ ] **P1 — 37 `catch (_)` che inghiottono l'errore** in `lib/`, con la UI che riceve codici generici
      (`refresh_failed`, `sheet_failed`). È il motivo per cui i bug della overview restano invisibili.

- [ ] **P2 — File oltre soglia:** `dataset_view.dart` 1948 righe, `dataset_bloc.dart` 1289,
      `sheet_joins_view.dart` 1104. Questo branch ha aggiunto altre 250 righe a `dataset_view`,
      contro la regola in AGENTS.md (nuova superficie → controller Riverpod dedicato).

- [ ] **P2 — `_loadColumnsByTableId`:** N+1 sequenziale su tutte le tabelle all'apertura del dataset,
      cache mai invalidata (`dataset_bloc.dart:729`).

- [ ] **P2 — Lint minimale:** solo `flutter_lints`, nessuna regola aggiuntiva, no `strict-casts` /
      `strict-raw-types`.

- [ ] **P3 — ~15 file con `/// TODO` segnaposto** (`multi_dataset_analytics`, `settings_viewmodel`,
      i widget dei filtri): scheletri mai completati.

- [ ] **P3 — Fixture binarie duplicate:** `test_fixtures/*.xlsx` in root sono byte-identiche a
      `flutter_app/test/fixtures/excel/` (le scrive il generatore in entrambi i posti,
      `tool/generate_multi_table_fixtures.py:113`).

---

## 4. Ordine di lavoro suggerito

- [x] **Ondata 1 — chiudere la table overview** — fatta il 2026-09-17 (vedi §1).
- [ ] **Ondata 2 — validator SQL su parser vero** (`sqlparser`) e `executeRawQuery` incapsulato:
      chiude i tre punti del validator in un colpo e rende reale il confine di sicurezza.
- [ ] **Ondata 3 — sanitizer unico** con dedup sul nome SQL + quoting degli identificatori.
- [ ] **Ondata 4 — import fuori dall'UI thread** (isolate), worklist nel detector, limite di
      dimensione file: è ciò che separa la demo dal prodotto su file reali.
- [ ] **Ondata 5 — CI su push/PR**, così le ondate 1-4 non regrediscono.
- [ ] **Ondata 6 — manutenzione:** aggiornare `excel_community` e la linea EOL di sqlite3, spezzare
      `dataset_view`, ridurre i `catch (_)`.
