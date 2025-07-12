### **REFACTORING\_PLAN.md (Bozza Corretta)**
[Refactoring Plan](REFACTORING_PLAN.md)
# Piano di Refactoring per l'Applicazione Excel Category

Questo documento illustra il piano di refactoring per l'applicazione Flutter "Excel Category", con l'obiettivo di trasformare l'architettura attuale (MVC + Riverpod "base") in una soluzione più robusta, manutenibile e scalabile, basata sui principi della **Clean Architecture**, **MVVM (Model-View-ViewModel)**, i principi **SOLID** e l'adozione del **Test-Driven Development (TDD)**.

## 1\. Stato Attuale e Motivazioni per il Refactoring

L'applicazione attuale è funzionale e permette la lettura, il filtraggio e l'esportazione di dati da file Excel. Tuttavia, come in molti progetti iniziali, l'architettura presenta alcune limitazioni:

  * **Accoppiamento Elevato:** Componenti di diversi strati (es. UI, Controller, Provider) sono strettamente interconnessi, rendendo difficile la modifica o la sostituzione di un componente senza impattare pesantemente gli altri.
  * **Difficoltà di Testabilità:** La logica di business è mescolata con dettagli di framework (Flutter, Riverpod) e I/O, rendendo difficile scrivere unit test isolati e affidabili. L'assenza attuale di una suite di test è un rischio significativo per future modifiche.
  * **Violazioni dei Principi SOLID:** Si riscontrano violazioni del Single Responsibility Principle (SRP) e del Dependency Inversion Principle (DIP), portando a classi con troppe responsabilità e dipendenze da implementazioni concrete anziché astrazioni.
  * **Problema della Lettura Formule Excel:** L'attuale libreria di parsing Excel non valuta le formule, restituendo valori vuoti. Il refactoring permetterà di isolare e risolvere questo problema in modo pulito.

Il refactoring è motivato dalla volontà di migliorare la **manutenibilità**, la **scalabilità**, la **testabilità** e la **robustezza** dell'applicazione, trasformandola in un esempio di sviluppo software di alta qualità.

## 2\. Architettura Target: Clean Architecture (MVVM con Flutter BLoC e Flutter Riverpod)

L'architettura adottata seguirà i principi della Clean Architecture, suddividendo l'applicazione in strati ben definiti:

```
lib/
├── main.dart
├── core/                   // Elementi trasversali e condivisi (Errori, Use Cases base, Utility)
├── di_container.dart       // Configurazione della Dependency Injection con Riverpod
└── features/               // Moduli/Funzionalità autonome
    └── excel_processing/   // La nostra feature specifica (Elaborazione Excel)
        ├── data/           // Implementazioni concrete di Repository e Data Source
        │   ├── datasources/
        │   └── repositories/
        ├── domain/         // Il cuore della logica di business pura (Entities, Repositories Interfacce, Use Cases)
        │   ├── entities/
        │   ├── repositories/
        │   └── usecases/
        └── presentation/   // UI e gestione dello stato (BLoC, Pagine, Widget)
            ├── bloc/       // <-- Qui useremo Flutter BLoC
            ├── pages/
            └── widgets/
```

### Principi e Pattern Applicati:

  * **Clean Architecture:**

      * **Indipendenza Framework:** Il Domain Layer sarà completamente agnostico a Flutter o qualsiasi libreria esterna.
      * **Testabilità:** Ogni strato avrà responsabilità chiare, facilitando i test unitari isolati.
      * **Separazione delle Responsabilità:** Ogni strato si occupa di un singolo "concern".
      * **Dipendenza Unidirezionale:** Gli strati esterni dipendono da quelli interni, mai il contrario.

  * **MVVM (Model-View-ViewModel) nel Presentation Layer:**

      * **View (`pages/`, `widgets/`):** Widget Flutter che si occupano della visualizzazione e dell'interazione con l'utente. Osservano i `ViewModel` (rappresentati dai **BLoC**) e inviano eventi.
      * **ViewModel (`bloc/excel_bloc.dart`):** I **BLoC** agiranno come ViewModel, esponendo lo stato della UI e gestendo la logica di presentazione, orchestrando le chiamate ai `Use Cases` del Domain Layer.

  * **Principi SOLID:**

      * **Single Responsibility Principle (SRP):** Ogni classe/modulo avrà una singola ragione per cambiare. Esempi: `ExcelDataEntity` solo per la rappresentazione dei dati; `ReadExcelFileUseCase` solo per leggere il file; `ExcelLocalDatasource` solo per l'interazione diretta con la libreria Excel.
      * **Open/Closed Principle (OCP):** Le entità e i moduli saranno aperti all'estensione ma chiusi alla modifica. Ad esempio, aggiungere un nuovo tipo di esportazione non dovrebbe modificare i `Use Case` esistenti, ma estendere `FileExportRepository` con una nuova implementazione.
      * **Liskov Substitution Principle (LSP):** Gli oggetti di una superclasse potranno essere sostituiti con oggetti delle sottoclassi senza alterare la correttezza del programma. (Meno evidente in questo refactoring, ma un principio guida).
      * **Interface Segregation Principle (ISP):** I client non saranno costretti a dipendere da interfacce che non usano. I repository del Domain Layer avranno interfacce precise per le operazioni di cui hanno bisogno.
      * **Dependency Inversion Principle (DIP):** I moduli di alto livello (es. `Use Cases`) non dipenderanno da moduli di basso livello (es. implementazioni concrete dei repository), ma da astrazioni (interfacce). La **Dependency Injection (con Flutter Riverpod)** sarà usata per "invertire" questa dipendenza.

  * **Design Patterns:**

      * **Builder:** Potrebbe essere considerato per la costruzione di oggetti complessi (`ExcelDataEntity` da raw data, se la logica di parsing diventa complessa).
      * **Adapter:** Essenziale nel **Data Layer**. La libreria `package:excel` (o una nuova libreria) fungerà da "adaptee". Il `ExcelLocalDatasource` sarà l'adapter che converte i dati specifici della libreria nel formato dell' `ExcelDataEntity` del Domain Layer.
      * **Strategy:** La logica di filtraggio e pivoting potrebbe essere implementata come diverse "strategie" che implementano un'interfaccia comune, permettendo di cambiare l'algoritmo al runtime. Questo sarà gestito all'interno dei `Use Cases` o da classi helpers chiamate dai `Use Cases`.
      * **Observer (Implicit con Flutter BLoC e Flutter Riverpod):** I **BLoC** agiscono come soggetti osservabili (`Stream` di stati) e i `View` sono gli osservatori che reagiscono ai cambiamenti di stato. **Flutter Riverpod** stesso implementa il pattern Observer per la gestione delle dipendenze e la reattività della UI.
      * **State:** Il pattern State sarà naturalmente integrato nel **BLoC**, dove ogni stato (`ExcelState`) rappresenta un differente stato della UI (es. `Loading`, `Loaded`, `Filtered`, `Error`).

  * **Test-Driven Development (TDD):**

      * **Test-First Approach:** Per ogni nuova funzionalità o refactoring di logica di business critica, verranno scritti prima i test falliti, poi il codice per farli passare, e infine il refactoring.
      * **Livelli di Test:**
          * **Unit Tests:** Per `Entities`, `Use Cases` (Domain Layer), `Datasources` e `Repository Implementations` (Data Layer), **BLoC** (Presentation Layer).
          * **Widget Tests:** Per i componenti UI che consumano i **BLoC**.
          * **Integration Tests (Opzionale per questo progetto):** Per scenari end-to-end che coinvolgono più strati.

## 3\. Piano di Migrazione Fasi (Bottom-Up)

Il refactoring sarà eseguito in modo incrementale sul branch `feature/clean-architecture-excel` per minimizzare i rischi e permettere progressi visibili.

1.  **Domain Layer - Entità (Core Business Objects):**

      * Definire `ExcelDataEntity` (`excel_data_entity.dart`) come rappresentazione pura di una riga Excel.
      * Definire `ExcelFilterEntity` (`excel_filter_entity.dart`) come rappresentazione pura dello stato dei criteri di filtro.
      * *Sostituisce concettualmente:* `lib/model/excel_element.dart` e la parte "dati" di `lib/model/filters.dart`.

2.  **Core Layer - Gestione Errori e Usecase Base:**

      * Definire classi `Failure` e `Exception` generiche (`core/errors/`).
      * Definire un `UseCase` base (`core/usecases/`) per standardizzare le chiamate ai casi d'uso.

3.  **Domain Layer - Interfacce Repository (Contratti):**

      * Definire `ExcelRepository` (`excel_repository.dart`) con metodi astratti per le operazioni sui dati Excel (lettura, filtraggio, pivoting).
      * Definire `FileExportRepository` (`file_export_repository.dart`) con metodi astratti per l'esportazione dei file.

4.  **Domain Layer - Use Cases (Logica di Business Pura):**

      * Implementare `ReadExcelFileUseCase` (usa `ExcelRepository`).
      * Implementare `ApplyFiltersUseCase` (usa `ExcelFilterEntity` e `ExcelDataEntity`).
      * Implementare `GetFilteredDataUseCase`.
      * Implementare `ExportToExcelUseCase` e `ExportToPdfUseCase` (usano `FileExportRepository`).
      * *Sostituisce concettualmente:* La logica di `FileController.processExcelFile` (parte business), la logica di `Filters` e la logica di esportazione di `ExcelExportController`.

5.  **Data Layer - Data Sources (Interazione Esterna):**

      * Implementare `ExcelLocalDatasource` (`excel_local_datasource.dart`). **Qui verrà affrontato il problema delle formule Excel**, esplorando librerie alternative o soluzioni specifiche per ottenere i valori calcolati. Questo datasource si occuperà della lettura "fisica" del file e della conversione in formati gestibili dal Repository.
      * Implementare `FileHandlerDatasource` (`file_handler_datasource.dart`) per la gestione del salvataggio/condivisione su diverse piattaforme.
      * *Sostituisce concettualmente:* La parte di I/O di `FileController` e la gestione di `FileSaver`/`Share` in `ExcelExportController`.

6.  **Data Layer - Repository Implementations (Bridge tra Data e Domain):**

      * Implementare `ExcelRepositoryImpl` (`excel_repository_impl.dart`) che userà `ExcelLocalDatasource`. Questa classe si occuperà di mappare le `Exception` (dal Datasource) in `Failure` (per il Domain Layer).
      * Implementare `FileExportRepositoryImpl` (`file_export_repository_impl.dart`) che userà `FileHandlerDatasource`.

7.  **Dependency Injection (Riverpod - di\_container.dart):**

      * Configurare tutti i `Provider` di **Flutter Riverpod** per iniettare le dipendenze dei `Use Cases` con le rispettive implementazioni dei `Repository`, e dei `Repository` con i `Datasources`.

8.  **Presentation Layer - BLoC (ViewModel):**

      * Definire `ExcelBloc` (`excel_bloc.dart`), i suoi `ExcelEvent` (`excel_event.dart`) e i suoi `ExcelState` (`excel_state.dart`) utilizzando il pacchetto **flutter\_bloc**. Questo BLoC sarà il ViewModel che la UI osserverà. Riceverà eventi dalla UI e orchestrerà le chiamate ai `Use Cases`.
      * *Sostituisce concettualmente:* `ElementsProvider`, `FiltersProvider`, `ColumnTitlesProvider`.

9.  **Presentation Layer - Pagine e Widget (UI):**

      * Riprogettare `lib/features/excel_processing/presentation/pages/excel_home_page.dart` e `excel_details_page.dart` per consumare lo stato di `ExcelBloc` e inviare eventi.
      * Adattare i widget esistenti (`ColumnFilterCard`, `RowFilters`, `DetailsElement`, `InsertFile`) e spostarli in `lib/features/excel_processing/presentation/widgets/`, facendoli interagire con il nuovo `ExcelBloc`.
      * *Sostituisce direttamente:* `view/home_page.dart`, `view/filter_details.dart`, e i widget in `view/home_page_widgets` e `view/filter_details_widgets`.

10. **Integrazione e Pulizia Finale:**

      * Aggiornare `main.dart` per usare le nuove pagine.
      * Rimuovere gradualmente le vecchie cartelle (`lib/model`, `lib/control`, `lib/provider`, `lib/view`) una volta che tutto il loro contenuto è stato migrato e verificato.
      * Assicurarsi che tutti i test passino.
