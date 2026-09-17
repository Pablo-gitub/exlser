# Audit architetturale e di sicurezza — Exlser

**Data:** 2026-09-17
**Branch analizzato:** `feature/multi-table-detection` (15 commit sopra `main`, +8793 righe)
**Stato:** §1 e §2 chiuse (vedi §5 per le verifiche); §3 aperta.
**Baseline all'apertura dell'audit:** `flutter analyze` pulito · 687 test verdi · i18n 386 chiavi × 9 locale, 0 mancanti ·
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

**Chiusi 8 su 9 il 2026-09-17** (il nono, gli aggiornamenti major di framework, è parzialmente
aperto per scelta: vedi in fondo). Analyzer pulito, **741 test** verdi, i18n 393 chiavi × 9 locale.

- [x] **P0 — Bypass del `ReadOnlySqlValidator` con join a virgola.**
      La validazione non lavora più sul testo ma sull'**AST**: nuovo
      `core/sql/sql_statement_analyzer.dart` su `sqlparser` (promosso a dipendenza diretta, era già
      transitivo di drift) che restituisce tipo di statement, tabelle referenziate — comprese quelle
      raggiunte via lista con virgola, subquery e CTE — funzioni e table-valued function.
      Le due query dell'audit ora sono rifiutate con `unknown_table`, e con loro
      `sqlite_master`, `pragma_table_info(...)` e `load_extension(...)`.
      *Test:* 22 casi in `read_only_sql_validator_test.dart` (prima non esisteva un test diretto).

- [x] **P1 — Denylist di keyword: falsi positivi eliminati.**
      Non c'è più nessuno scan testuale: `WHERE note = 'update'`, un literal con `;` o con `--`, e un
      commento finale sono query legittime e passano. Restano rifiutati DML, DDL, `PRAGMA`,
      transazioni e statement multipli, ma per **struttura**, non per stringa.
      Nuovo codice d'errore `invalid_syntax` (9 locale + mappatura UI) per distinguere un errore di
      sintassi da un comando bloccato.
      **Effetto collaterale voluto:** le CTE read-only (`WITH x AS (SELECT …) SELECT * FROM x`) ora
      funzionano — il corpo resta comunque soggetto all'allowlist.

- [x] **P1 — `executeRawQuery` non valida nulla.**
      Nuovo `core/sql/read_only_sql_guard.dart`: ogni SQL grezzo che passa dal repository deve essere
      **un singolo SELECT**, altrimenti `UnsafeRawQueryException` prima di toccare il database. I 6
      call site interni (analytics, filtri, sampling relazioni, preview multi-sheet) passano senza
      modifiche — il che è anche la prova che il vincolo non è arbitrario.
      *Test:* 6 casi sul guard + un test sul repository che verifica che il datasource non venga
      nemmeno raggiunto.

- [x] **P1 — Identificatori interpolati senza quoting.**
      Nuovo `SqlNameSanitizer.quote()` usato in tutte le istruzioni dinamiche: tabelle e colonne in
      `query_repository_impl` (fetch, filtri, count, distinct, aggregati, INSERT), `CREATE TABLE` in
      `dynamic_table_builder`, `WHERE`/`ORDER BY`/`COUNT` in `apply_filters_usecase`.
      23 asserzioni di test aggiornate alla forma quotata.

- [x] **P1 — Due `SqlNameSanitizer`.**
      Cancellata la classe debole in `data/adapters/sanitizers/` (e il suo test): resta solo quella in
      `core/normalizers/`. `CreateDatasetTableUseCase` ora usa quella — il che chiude anche una delle
      violazioni di layer `domain → data` — e le passa i nomi già presenti nel dataset, così due fogli
      che sanificano allo stesso identificatore producono `..._1` invece di collidere al CREATE TABLE.
      La wizard valida i duplicati anche sul **nome SQL**, non solo sull'etichetta.
      *Test:* 4 nuovi casi sul use case (collisione, caratteri invalidi, unicode, nome vuoto), più il
      caso di collisione nella wizard. Chiusi i TODO che erano rimasti nel test file.

- [x] **P1 — Parsing sul thread UI e nessun limite di dimensione.**
      CSV ed Excel ora fanno il lavoro pesante in un isolate (`compute`: decodifica, unzip, XML,
      boundary detection), con entry point top-level e payload immutabile; sul web, che non ha
      isolate, `compute` esegue inline come prima. Aggiunto un limite di **256 MiB** con
      `FileTooLargeException`, controllato prima di risolvere il parser, con messaggio localizzato in
      9 lingue che riporta il limite.
      *Test:* 3 casi sul limite; i test dei parser girano attraverso `compute` con fixture binarie reali.
      **Resta fuori** (dichiarato): l'inferenza di schema e il mapping delle righe in
      `ImportDataService`/`CreateDatasetService` girano ancora sull'isolate UI. Spostarli richiede un
      seam iniettabile perché i test mockano `ParserFactory` e `InferSchemaUseCase`, e gli oggetti
      mockati non sono inviabili a un isolate — va progettato, non improvvisato.

- [x] **P1 — `_recursiveCut` senza limite di profondità.**
      Sostituita da un worklist esplicito (`_cutIntoBlocks`) con `_trim` e `_findWidestGutter`
      separati, ordine di lettura preservato e tetto di **200 blocchi** per foglio: esaurito il
      budget i box rimanenti vengono emessi interi invece di essere spezzati, senza perdere contenuto.
      *Test:* una griglia da 2500 righe alternate contenuto/vuoto e una diagonale sparsa 600×600.

- [x] **P2 — La CI non fa da gate.**
      Nuovo `.github/workflows/ci.yml` su **push e pull request**: job Flutter (`pub get`, format
      informativo, `analyze`, `test`) e job landing page (`npm ci`, `build`, `npm audit --audit-level=high`),
      con `concurrency` per annullare i run sovrapposti.
      Nota: `dart.yml` non è una CI Dart — è una build IPA iOS con il nome sbagliato; conviene
      rinominarla (non l'ho fatto: si perde lo storico dei run nella UI di Actions).

- [~] **P2 — Dipendenze indietro — chiuso a metà, per scelta.**
      **Fatto e verificato** (analyzer pulito, 741 test verdi):
      86 pacchetti aggiornati dentro i vincoli esistenti; `drift` 2.32 → **2.35** con codegen
      rigenerato; `sqlparser` → 0.45; **`sqlite3` 3.1.6 → 3.5.2** (e vincolo alzato a `^3.5.2`, così
      non può risolvere più in basso); **`excel_community` 1.0.9 → 2.4.0** — il major che conta,
      perché è il parser dei file non fidati, validato dai test con fixture `.xlsx` binarie reali;
      rimosso `sqlite3_flutter_libs` dal pubspec: la `0.6.0+eol` è un pacchetto **vuoto** di
      deprecazione (il nativo arriva da `sqlite3` 3.x), e resta comunque pinnata come transitiva da
      `drift_flutter`, quindi i vecchi script di build restano esclusi.
      **Lasciati aperti, con motivo:** `flutter_riverpod` 2.6 → 3.4, `go_router` 17 → 18,
      `file_picker` 10 → 13, `share_plus` 11 → 13, `desktop_drop` 0.7 → 0.8 sono major che toccano
      wiring, navigazione e canali di piattaforma: la suite non copre l'interazione reale e da qui non
      posso provare l'app su Android/desktop. `sqlite3_web` 0.5 → 0.9.4 richiede anche di rigenerare
      `web/drift_worker.js` e `web/sqlite3.wasm`, che sono asset committati e vanno scaricati dalla
      release di drift/sqlite3 e provati sulla demo web.

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
- [x] **Ondata 2 — validator SQL su parser vero** e `executeRawQuery` guardato — fatta il 2026-09-17.
- [x] **Ondata 3 — sanitizer unico** con dedup sul nome SQL + quoting degli identificatori — fatta.
- [x] **Ondata 4 — import fuori dall'UI thread** (isolate nei parser), worklist nel detector, limite
      di dimensione file — fatta; resta da spostare l'inferenza di schema (vedi §2).
- [x] **Ondata 5 — CI su push/PR** — fatta (`.github/workflows/ci.yml`).
- [ ] **Ondata 6 — manutenzione rimasta:** i major di framework (`flutter_riverpod` 3, `go_router` 18,
      `file_picker` 13, `share_plus` 13, `desktop_drop` 0.8) e lo stack web (`sqlite3_web` 0.9 +
      asset `drift_worker.js`/`sqlite3.wasm`), che richiedono prove manuali su device; spezzare
      `dataset_view`; ridurre i 37 `catch (_)`.

---

## 5. Verifiche eseguite il 2026-09-17

- `flutter analyze`: pulito
- `flutter test`: **741 test** verdi (erano 687 all'apertura dell'audit)
- i18n: **393 chiavi × 9 locale**, set identici
- `flutter build web --release`: compila con le dipendenze aggiornate
- `flutter build linux --debug`: compila e linka il nativo (sqlite3 3.5.2 e il plugin FFI `jni`)
- `dart run build_runner build --delete-conflicting-outputs`: rigenerato dopo il bump di drift
- `dart format`: solo sui file toccati, nessuna riscrittura collaterale

Note per chi rilascia:
- `path_provider_foundation` 2.6 è passata a Dart+FFI, quindi è correttamente **uscita** dal
  registrant dei plugin macOS/iOS: il diff su `GeneratedPluginRegistrant.swift` è atteso, non una
  regressione.
- `jni` compare nei plugin generati di Linux/Windows come plugin FFI transitivo delle dipendenze
  aggiornate.
- Android e iOS non sono verificabili da questa sessione: vale una build per ciascuno prima del tag.
