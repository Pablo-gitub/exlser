export const languages = [
  { code: "en", name: "English", flag: "🇬🇧" },
  { code: "it", name: "Italiano", flag: "🇮🇹" },
  { code: "es", name: "Español", flag: "🇪🇸" },
  { code: "fr", name: "Français", flag: "🇫🇷" },
  { code: "de", name: "Deutsch", flag: "🇩🇪" },
  { code: "zh", name: "中文", flag: "🇨🇳" },
  { code: "ru", name: "Русский", flag: "🇷🇺" },
  { code: "ja", name: "日本語", flag: "🇯🇵" },
  { code: "pt", name: "Português", flag: "🇵🇹" },
];

export const languageCodes = languages.map((language) => language.code);

const sharedFormats = ["Excel", "CSV", "JSON", "PDF", "SQL"];

export const translations = {
  en: {
    meta: { label: "English" },
    nav: {
      features: "Features",
      downloads: "Downloads",
      contact: "Contact",
      language: "Language",
      demo: "Try Demo",
    },
    hero: {
      aria: "Exlser product overview",
      eyebrow: "Local-first spreadsheet workspace",
      title: "Exlser",
      copy: "Turn CSV and Excel files into persistent local datasets with filters, SQL queries, charts, card views, QR codes, and multi-format exports.",
      desktop: "Download desktop",
      beta: "Join Android beta",
      actions: "Primary actions",
      strengths: ["No server", "No cloud account", "Runs on your device"],
    },
    intro: {
      eyebrow: "Built for real spreadsheet work",
      title: "Import once. Explore like a database.",
      text: "Exlser keeps the approachable flow of a spreadsheet app, then adds persistent datasets, structured filters, SQL, analytics, and export tools for repeatable work.",
      metricsLabel: "Product capabilities",
      metrics: [
        { value: "9", label: "languages" },
        { value: "5", label: "export formats" },
        { value: "6", label: "target platforms" },
      ],
    },
    video: {
      eyebrow: "Quick preview",
      title: "See the workflow before installing.",
      text: "The app guides you from file selection to schema confirmation, dataset exploration, filtering, analytics, and export.",
      demoCta: "Try the demo",
      desktopCta: "Download for your computer",
    },
    trailer: {
      eyebrow: "Mobile beta",
      title: "Join the mobile beta and see what is coming.",
      text: "The video shows the mobile experience you can expect: import files, review data, explore insights, and keep the workflow local on your device.",
      betaCta: "Request beta access",
      moreInfo: "Get more information",
    },
    legacy: {
      eyebrow: "Project origin",
      title: "See where everything started.",
      text: "The original web prototype is still online as a historical snapshot of the first Exlser idea.",
      cta: "Try the old version",
    },
    featuresHeading: {
      eyebrow: "Core features",
      title: "Everything stays close to the dataset.",
      text: "The first release focuses on useful local work: browse your data, find the right rows, inspect charts, and export exactly the current result.",
    },
    features: [
      {
        title: "Guided import",
        text: "Open CSV and Excel files, review inferred columns, and confirm the schema before anything is saved.",
        alt: "Exlser import screen",
      },
      {
        title: "Type-aware filtering",
        text: "Filter text, numbers, dates, and booleans with controls built for the selected column type.",
        alt: "Exlser filtering controls",
      },
      {
        title: "Saved workspaces",
        text: "Reopen local datasets from the Works page and continue from the state you saved previously.",
        alt: "Exlser saved works list",
      },
      {
        title: "SQL query mode",
        text: "Advanced users can run read-only SELECT queries with schema hints and row count feedback.",
        alt: "Exlser SQL query mode",
      },
      {
        title: "Automatic analytics",
        text: "Get suggested charts from your column types, then adjust columns and aggregations when needed.",
        alt: "Exlser analytics section",
      },
      {
        title: "Flexible export",
        text: "Export filtered datasets to Excel, CSV, JSON, PDF, or SQL while respecting visible columns.",
        alt: "Exlser export dialog",
      },
      {
        title: "Cards with QR codes",
        text: "Switch to card view and export row-level QR codes that encode each record as JSON.",
        alt: "Exlser card view with QR code",
      },
      {
        title: "Nine languages",
        text: "Use Exlser in English, Italian, Spanish, French, German, Chinese, Russian, Japanese, or Portuguese.",
        alt: "Exlser language settings",
      },
    ],
    crossPlatform: {
      eyebrow: "Cross-platform plan",
      title: "One data workflow, many devices.",
      text: "Exlser is developed with Flutter for Android, desktop, and web. The Android beta is distributed through Google Play, while desktop builds are made available from GitHub Releases.",
      alt: "Exlser running across phone, desktop, tablet, and web devices",
    },
    downloads: {
      eyebrow: "Get Exlser",
      title: "Choose the channel that fits your device.",
      channels: [
        {
          title: "Android beta",
          text: "Android builds are distributed through the Google Play beta program while the first public Play Store release is prepared.",
          cta: "Contact the developer",
        },
        {
          title: "Desktop builds",
          text: "Download the latest macOS, Windows, and Linux artifacts from GitHub Releases when you need a local desktop workflow.",
          cta: "Open releases",
        },
        {
          title: "Web demo",
          text: "Try Exlser directly in your browser before installing the desktop app or joining the Android beta.",
          cta: "Try demo",
        },
        {
          title: "Source code",
          text: "Exlser is open source. Follow the roadmap, inspect the code, or contribute improvements from the GitHub repository.",
          cta: "View repository",
        },
      ],
    },
    export: {
      eyebrow: "Export",
      title: "Share only the data you mean to share.",
      text: "Exports respect active filters, sorting, selected sheets, and hidden columns, so the output matches the current analysis.",
      formatsLabel: "Supported export formats",
      formats: sharedFormats,
    },
    contact: {
      eyebrow: "Open source",
      title: "Want to try the beta or follow development?",
      text: "Contact the developer for Android beta access, or follow the project on GitHub while desktop releases and the public Play Store release evolve.",
      developer: "Contact developer",
      github: "Open GitHub",
    },
    footer: {
      top: "Back to Exlser top",
      socials: "Social links",
    },
  },
  it: {
    meta: { label: "Italiano" },
    nav: {
      features: "Funzioni",
      downloads: "Download",
      contact: "Contatti",
      language: "Lingua",
      demo: "Prova demo",
    },
    hero: {
      aria: "Panoramica del prodotto Exlser",
      eyebrow: "Workspace locale per fogli di calcolo",
      title: "Exlser",
      copy: "Trasforma file CSV ed Excel in dataset locali persistenti con filtri, query SQL, grafici, vista a schede, QR code ed esportazioni multi-formato.",
      desktop: "Scarica desktop",
      beta: "Partecipa alla beta Android",
      actions: "Azioni principali",
      strengths: ["Nessun server", "Nessun account cloud", "Funziona sul tuo dispositivo"],
    },
    intro: {
      eyebrow: "Creato per lavorare davvero sui fogli",
      title: "Importa una volta. Esplora come un database.",
      text: "Exlser mantiene la semplicità di un foglio di calcolo e aggiunge dataset persistenti, filtri strutturati, SQL, analisi ed esportazioni per un lavoro ripetibile.",
      metricsLabel: "Capacità del prodotto",
      metrics: [
        { value: "9", label: "lingue" },
        { value: "5", label: "formati export" },
        { value: "6", label: "piattaforme" },
      ],
    },
    video: {
      eyebrow: "Anteprima rapida",
      title: "Guarda il flusso prima di installare.",
      text: "L'app ti guida dalla selezione del file alla conferma dello schema, fino a esplorazione, filtri, analisi ed esportazione.",
      demoCta: "Prova la demo",
      desktopCta: "Scarica per il tuo computer",
    },
    trailer: {
      eyebrow: "Beta mobile",
      title: "Partecipa alla beta mobile e scopri cosa ti aspetta.",
      text: "Il video mostra l'esperienza mobile prevista: importazione dei file, revisione dei dati, analisi e lavoro locale direttamente sul tuo dispositivo.",
      betaCta: "Richiedi accesso beta",
      moreInfo: "Ottieni maggiori informazioni",
    },
    legacy: {
      eyebrow: "Origine del progetto",
      title: "Guarda da dove è cominciato tutto.",
      text: "Il primo prototipo web resta online come snapshot storico della prima idea di Exlser.",
      cta: "Prova la vecchia versione",
    },
    featuresHeading: {
      eyebrow: "Funzioni principali",
      title: "Tutto resta vicino al dataset.",
      text: "La prima release punta sul lavoro locale utile: navigare i dati, trovare le righe giuste, leggere i grafici ed esportare esattamente il risultato corrente.",
    },
    features: [
      {
        title: "Import guidato",
        text: "Apri file CSV ed Excel, controlla le colonne rilevate e conferma lo schema prima di salvare.",
        alt: "Schermata di importazione di Exlser",
      },
      {
        title: "Filtri in base al tipo",
        text: "Filtra testi, numeri, date e booleani con controlli adatti alla colonna selezionata.",
        alt: "Controlli filtro di Exlser",
      },
      {
        title: "Workspace salvati",
        text: "Riapri dataset locali dalla pagina Lavori e continua dallo stato salvato.",
        alt: "Lista lavori salvati in Exlser",
      },
      {
        title: "Modalità query SQL",
        text: "Gli utenti esperti possono eseguire query SELECT in sola lettura con suggerimenti schema e conteggio righe.",
        alt: "Modalità query SQL di Exlser",
      },
      {
        title: "Analisi automatiche",
        text: "Ricevi grafici suggeriti dai tipi di colonna e poi modifica colonne e aggregazioni.",
        alt: "Sezione analisi di Exlser",
      },
      {
        title: "Export flessibile",
        text: "Esporta dataset filtrati in Excel, CSV, JSON, PDF o SQL rispettando le colonne visibili.",
        alt: "Dialog di esportazione di Exlser",
      },
      {
        title: "Schede con QR code",
        text: "Passa alla vista a schede ed esporta QR code per riga con il record codificato in JSON.",
        alt: "Vista schede Exlser con QR code",
      },
      {
        title: "Nove lingue",
        text: "Usa Exlser in inglese, italiano, spagnolo, francese, tedesco, cinese, russo, giapponese o portoghese.",
        alt: "Impostazioni lingua di Exlser",
      },
    ],
    crossPlatform: {
      eyebrow: "Piano cross-platform",
      title: "Un solo flusso dati, molti dispositivi.",
      text: "Exlser è sviluppato con Flutter per Android, desktop e web. La beta Android passa da Google Play, mentre le build desktop sono disponibili su GitHub Releases.",
      alt: "Exlser in esecuzione su telefono, desktop, tablet e web",
    },
    downloads: {
      eyebrow: "Ottieni Exlser",
      title: "Scegli il canale adatto al tuo dispositivo.",
      channels: [
        {
          title: "Beta Android",
          text: "Le build Android sono distribuite tramite il programma beta Google Play mentre viene preparata la prima release pubblica.",
          cta: "Contatta lo sviluppatore",
        },
        {
          title: "Build desktop",
          text: "Scarica gli ultimi artifact macOS, Windows e Linux da GitHub Releases per un flusso locale da desktop.",
          cta: "Apri le release",
        },
        {
          title: "Demo web",
          text: "Prova Exlser direttamente nel browser prima di installare l'app desktop o partecipare alla beta Android.",
          cta: "Prova demo",
        },
        {
          title: "Codice sorgente",
          text: "Exlser è open source. Segui la roadmap, leggi il codice o contribuisci dal repository GitHub.",
          cta: "Apri repository",
        },
      ],
    },
    export: {
      eyebrow: "Export",
      title: "Condividi solo i dati che vuoi condividere.",
      text: "Le esportazioni rispettano filtri attivi, ordinamento, fogli selezionati e colonne nascoste, quindi l'output corrisponde all'analisi corrente.",
      formatsLabel: "Formati di esportazione supportati",
      formats: sharedFormats,
    },
    contact: {
      eyebrow: "Open source",
      title: "Vuoi provare la beta o seguire lo sviluppo?",
      text: "Contatta lo sviluppatore per l'accesso alla beta Android oppure segui il progetto su GitHub mentre evolvono release desktop e Play Store pubblico.",
      developer: "Contatta sviluppatore",
      github: "Apri GitHub",
    },
    footer: {
      top: "Torna all'inizio di Exlser",
      socials: "Link social",
    },
  },
  es: {
    meta: { label: "Español" },
    nav: {
      features: "Funciones",
      downloads: "Descargas",
      contact: "Contacto",
      language: "Idioma",
      demo: "Probar demo",
    },
    hero: {
      aria: "Vista general del producto Exlser",
      eyebrow: "Espacio de trabajo local para hojas de cálculo",
      title: "Exlser",
      copy: "Convierte archivos CSV y Excel en datasets locales persistentes con filtros, consultas SQL, gráficos, tarjetas, códigos QR y exportaciones multiformato.",
      desktop: "Descargar escritorio",
      beta: "Unirse a la beta Android",
      actions: "Acciones principales",
      strengths: ["Sin servidor", "Sin cuenta en la nube", "Funciona en tu dispositivo"],
    },
    intro: {
      eyebrow: "Diseñado para trabajo real con hojas",
      title: "Importa una vez. Explora como una base de datos.",
      text: "Exlser mantiene el flujo sencillo de una hoja de cálculo y añade datasets persistentes, filtros estructurados, SQL, analítica y exportación para trabajo repetible.",
      metricsLabel: "Capacidades del producto",
      metrics: [
        { value: "9", label: "idiomas" },
        { value: "5", label: "formatos de exportación" },
        { value: "6", label: "plataformas" },
      ],
    },
    video: {
      eyebrow: "Vista rápida",
      title: "Mira el flujo antes de instalar.",
      text: "La app te guía desde la selección del archivo hasta la confirmación del esquema, exploración, filtros, analítica y exportación.",
      demoCta: "Probar la demo",
      desktopCta: "Descargar para tu ordenador",
    },
    trailer: {
      eyebrow: "Beta móvil",
      title: "Únete a la beta móvil y descubre lo que viene.",
      text: "El video muestra la experiencia móvil prevista: importar archivos, revisar datos, explorar análisis y trabajar localmente en tu dispositivo.",
      betaCta: "Solicitar acceso beta",
      moreInfo: "Obtener más información",
    },
    legacy: {
      eyebrow: "Origen del proyecto",
      title: "Mira dónde empezó todo.",
      text: "El prototipo web original sigue online como una captura histórica de la primera idea de Exlser.",
      cta: "Probar la versión antigua",
    },
    featuresHeading: {
      eyebrow: "Funciones clave",
      title: "Todo se mantiene cerca del dataset.",
      text: "La primera versión se centra en trabajo local útil: navegar datos, encontrar filas, revisar gráficos y exportar exactamente el resultado actual.",
    },
    features: [
      { title: "Importación guiada", text: "Abre CSV y Excel, revisa las columnas detectadas y confirma el esquema antes de guardar.", alt: "Pantalla de importación de Exlser" },
      { title: "Filtros por tipo", text: "Filtra textos, números, fechas y booleanos con controles adaptados a la columna seleccionada.", alt: "Controles de filtro de Exlser" },
      { title: "Espacios guardados", text: "Reabre datasets locales desde la página de trabajos y continúa desde el estado guardado.", alt: "Lista de trabajos guardados en Exlser" },
      { title: "Modo consulta SQL", text: "Los usuarios avanzados pueden ejecutar SELECT de solo lectura con ayuda de esquema y conteo de filas.", alt: "Modo consulta SQL de Exlser" },
      { title: "Analítica automática", text: "Obtén gráficos sugeridos por los tipos de columna y ajusta columnas y agregaciones.", alt: "Sección de analítica de Exlser" },
      { title: "Exportación flexible", text: "Exporta datasets filtrados a Excel, CSV, JSON, PDF o SQL respetando columnas visibles.", alt: "Diálogo de exportación de Exlser" },
      { title: "Tarjetas con QR", text: "Cambia a vista de tarjetas y exporta códigos QR por fila con cada registro en JSON.", alt: "Vista de tarjetas Exlser con QR" },
      { title: "Nueve idiomas", text: "Usa Exlser en inglés, italiano, español, francés, alemán, chino, ruso, japonés o portugués.", alt: "Ajustes de idioma de Exlser" },
    ],
    crossPlatform: {
      eyebrow: "Plan multiplataforma",
      title: "Un flujo de datos, muchos dispositivos.",
      text: "Exlser está desarrollado con Flutter para Android, escritorio y web. La beta Android se distribuye por Google Play, y las builds de escritorio por GitHub Releases.",
      alt: "Exlser funcionando en teléfono, escritorio, tablet y web",
    },
    downloads: {
      eyebrow: "Obtén Exlser",
      title: "Elige el canal que encaja con tu dispositivo.",
      channels: [
        { title: "Beta Android", text: "Las builds Android se distribuyen mediante el programa beta de Google Play mientras se prepara la primera versión pública.", cta: "Contactar al desarrollador" },
        { title: "Builds de escritorio", text: "Descarga los últimos artefactos para macOS, Windows y Linux desde GitHub Releases.", cta: "Abrir releases" },
        { title: "Demo web", text: "Prueba Exlser directamente en el navegador antes de instalar la app de escritorio o unirte a la beta Android.", cta: "Probar demo" },
        { title: "Código fuente", text: "Exlser es open source. Sigue la roadmap, revisa el código o contribuye desde GitHub.", cta: "Ver repositorio" },
      ],
    },
    export: {
      eyebrow: "Exportación",
      title: "Comparte solo los datos que quieres compartir.",
      text: "Las exportaciones respetan filtros activos, ordenación, hojas seleccionadas y columnas ocultas.",
      formatsLabel: "Formatos de exportación soportados",
      formats: sharedFormats,
    },
    contact: {
      eyebrow: "Open source",
      title: "¿Quieres probar la beta o seguir el desarrollo?",
      text: "Contacta al desarrollador para acceder a la beta Android o sigue el proyecto en GitHub.",
      developer: "Contactar desarrollador",
      github: "Abrir GitHub",
    },
    footer: { top: "Volver al inicio de Exlser", socials: "Enlaces sociales" },
  },
  fr: {
    meta: { label: "Français" },
    nav: { features: "Fonctionnalités", downloads: "Téléchargements", contact: "Contact", language: "Langue", demo: "Essayer la démo" },
    hero: {
      aria: "Présentation du produit Exlser",
      eyebrow: "Espace de travail local pour tableurs",
      title: "Exlser",
      copy: "Transformez vos fichiers CSV et Excel en datasets locaux persistants avec filtres, requêtes SQL, graphiques, cartes, QR codes et exports multi-formats.",
      desktop: "Télécharger desktop",
      beta: "Rejoindre la bêta Android",
      actions: "Actions principales",
      strengths: ["Aucun serveur", "Aucun compte cloud", "Fonctionne sur votre appareil"],
    },
    intro: {
      eyebrow: "Pensé pour le vrai travail sur tableurs",
      title: "Importez une fois. Explorez comme une base de données.",
      text: "Exlser garde la simplicité d'un tableur et ajoute datasets persistants, filtres structurés, SQL, analyses et outils d'export.",
      metricsLabel: "Capacités du produit",
      metrics: [
        { value: "9", label: "langues" },
        { value: "5", label: "formats d'export" },
        { value: "6", label: "plateformes" },
      ],
    },
    video: { eyebrow: "Aperçu rapide", title: "Découvrez le flux avant d'installer.", text: "L'application vous guide du choix du fichier à l'export, en passant par le schéma, l'exploration, les filtres et l'analyse.", demoCta: "Essayer la démo", desktopCta: "Télécharger pour votre ordinateur" },
    trailer: { eyebrow: "Bêta mobile", title: "Rejoignez la bêta mobile et découvrez la suite.", text: "La vidéo montre l'expérience mobile prévue : importer des fichiers, vérifier les données, explorer les analyses et travailler localement sur votre appareil.", betaCta: "Demander l'accès bêta", moreInfo: "Obtenir plus d'informations" },
    legacy: { eyebrow: "Origine du projet", title: "Découvrez où tout a commencé.", text: "Le prototype web original reste en ligne comme capture historique de la première idée d'Exlser.", cta: "Essayer l'ancienne version" },
    featuresHeading: { eyebrow: "Fonctionnalités clés", title: "Tout reste proche du dataset.", text: "La première version se concentre sur le travail local utile : parcourir, filtrer, analyser et exporter le résultat courant." },
    features: [
      { title: "Import guidé", text: "Ouvrez des CSV et Excel, vérifiez les colonnes détectées et confirmez le schéma avant sauvegarde.", alt: "Écran d'import Exlser" },
      { title: "Filtres par type", text: "Filtrez textes, nombres, dates et booléens avec des contrôles adaptés à la colonne.", alt: "Contrôles de filtre Exlser" },
      { title: "Espaces sauvegardés", text: "Rouvrez vos datasets locaux depuis la page Travaux et reprenez l'état sauvegardé.", alt: "Liste des travaux Exlser" },
      { title: "Mode requête SQL", text: "Les utilisateurs avancés peuvent lancer des SELECT en lecture seule avec aide de schéma et comptage.", alt: "Mode SQL Exlser" },
      { title: "Analyses automatiques", text: "Obtenez des graphiques suggérés depuis les types de colonnes et ajustez colonnes et agrégations.", alt: "Section analyse Exlser" },
      { title: "Export flexible", text: "Exportez en Excel, CSV, JSON, PDF ou SQL en respectant les colonnes visibles.", alt: "Dialogue d'export Exlser" },
      { title: "Cartes avec QR codes", text: "Passez en vue cartes et exportez un QR code par ligne contenant le record en JSON.", alt: "Vue cartes Exlser avec QR" },
      { title: "Neuf langues", text: "Utilisez Exlser en anglais, italien, espagnol, français, allemand, chinois, russe, japonais ou portugais.", alt: "Réglages de langue Exlser" },
    ],
    crossPlatform: { eyebrow: "Plan multiplateforme", title: "Un flux de données, plusieurs appareils.", text: "Exlser est développé avec Flutter pour Android, desktop et web. La bêta Android passe par Google Play, les builds desktop par GitHub Releases.", alt: "Exlser sur téléphone, desktop, tablette et web" },
    downloads: {
      eyebrow: "Obtenir Exlser",
      title: "Choisissez le canal adapté à votre appareil.",
      channels: [
        { title: "Bêta Android", text: "Les builds Android sont distribuées via la bêta Google Play pendant la préparation de la première version publique.", cta: "Contacter le développeur" },
        { title: "Builds desktop", text: "Téléchargez les derniers artefacts macOS, Windows et Linux depuis GitHub Releases.", cta: "Ouvrir les releases" },
        { title: "Démo web", text: "Essayez Exlser directement dans le navigateur avant d'installer l'app desktop ou de rejoindre la bêta Android.", cta: "Essayer la démo" },
        { title: "Code source", text: "Exlser est open source. Suivez la roadmap, inspectez le code ou contribuez sur GitHub.", cta: "Voir le dépôt" },
      ],
    },
    export: { eyebrow: "Export", title: "Partagez seulement les données voulues.", text: "Les exports respectent filtres actifs, tri, feuilles sélectionnées et colonnes masquées.", formatsLabel: "Formats d'export supportés", formats: sharedFormats },
    contact: { eyebrow: "Open source", title: "Vous voulez tester la bêta ou suivre le développement ?", text: "Contactez le développeur pour accéder à la bêta Android ou suivez le projet sur GitHub.", developer: "Contacter", github: "Ouvrir GitHub" },
    footer: { top: "Retour en haut d'Exlser", socials: "Liens sociaux" },
  },
  de: {
    meta: { label: "Deutsch" },
    nav: { features: "Funktionen", downloads: "Downloads", contact: "Kontakt", language: "Sprache", demo: "Demo testen" },
    hero: {
      aria: "Exlser Produktübersicht",
      eyebrow: "Lokaler Workspace für Tabellen",
      title: "Exlser",
      copy: "Verwandle CSV- und Excel-Dateien in lokale, persistente Datensätze mit Filtern, SQL-Abfragen, Diagrammen, Karten, QR-Codes und Exporten in mehreren Formaten.",
      desktop: "Desktop herunterladen",
      beta: "Android-Beta beitreten",
      actions: "Hauptaktionen",
      strengths: ["Kein Server", "Kein Cloud-Konto", "Läuft auf deinem Gerät"],
    },
    intro: {
      eyebrow: "Für echte Tabellenarbeit gebaut",
      title: "Einmal importieren. Wie eine Datenbank erkunden.",
      text: "Exlser behält den einfachen Tabellenfluss bei und ergänzt persistente Datensätze, strukturierte Filter, SQL, Analysen und Exportwerkzeuge.",
      metricsLabel: "Produktfähigkeiten",
      metrics: [
        { value: "9", label: "Sprachen" },
        { value: "5", label: "Exportformate" },
        { value: "6", label: "Plattformen" },
      ],
    },
    video: { eyebrow: "Kurzer Einblick", title: "Sieh den Workflow vor der Installation.", text: "Die App führt dich von Dateiauswahl und Schema-Bestätigung bis zu Exploration, Filtern, Analyse und Export.", demoCta: "Demo testen", desktopCta: "Für deinen Computer herunterladen" },
    trailer: { eyebrow: "Mobile Beta", title: "Mach bei der mobilen Beta mit und sieh, was kommt.", text: "Das Video zeigt die geplante mobile Erfahrung: Dateien importieren, Daten prüfen, Analysen erkunden und lokal auf deinem Gerät arbeiten.", betaCta: "Beta-Zugang anfragen", moreInfo: "Mehr Informationen" },
    legacy: { eyebrow: "Projektursprung", title: "Sieh, wo alles begonnen hat.", text: "Der ursprüngliche Web-Prototyp bleibt als historischer Snapshot der ersten Exlser-Idee online.", cta: "Alte Version testen" },
    featuresHeading: { eyebrow: "Kernfunktionen", title: "Alles bleibt nah am Datensatz.", text: "Die erste Version fokussiert nützliche lokale Arbeit: Daten durchsuchen, Zeilen finden, Diagramme prüfen und das aktuelle Ergebnis exportieren." },
    features: [
      { title: "Geführter Import", text: "Öffne CSV- und Excel-Dateien, prüfe erkannte Spalten und bestätige das Schema vor dem Speichern.", alt: "Exlser Importbildschirm" },
      { title: "Typspezifische Filter", text: "Filtere Text, Zahlen, Daten und Booleans mit passenden Steuerelementen.", alt: "Exlser Filtersteuerung" },
      { title: "Gespeicherte Workspaces", text: "Öffne lokale Datensätze erneut und arbeite mit dem gespeicherten Zustand weiter.", alt: "Gespeicherte Exlser-Arbeiten" },
      { title: "SQL-Abfragemodus", text: "Fortgeschrittene Nutzer können schreibgeschützte SELECT-Abfragen mit Schemahilfe und Zeilenzählung ausführen.", alt: "Exlser SQL-Modus" },
      { title: "Automatische Analysen", text: "Erhalte Diagrammvorschläge aus Spaltentypen und passe Spalten und Aggregationen an.", alt: "Exlser Analysebereich" },
      { title: "Flexibler Export", text: "Exportiere nach Excel, CSV, JSON, PDF oder SQL unter Beachtung sichtbarer Spalten.", alt: "Exlser Exportdialog" },
      { title: "Karten mit QR-Codes", text: "Wechsle zur Kartenansicht und exportiere je Zeile einen JSON-QR-Code.", alt: "Exlser Kartenansicht mit QR" },
      { title: "Neun Sprachen", text: "Nutze Exlser auf Englisch, Italienisch, Spanisch, Französisch, Deutsch, Chinesisch, Russisch, Japanisch oder Portugiesisch.", alt: "Exlser Spracheinstellungen" },
    ],
    crossPlatform: { eyebrow: "Cross-Platform-Plan", title: "Ein Datenworkflow, viele Geräte.", text: "Exlser wird mit Flutter für Android, Desktop und Web entwickelt. Die Android-Beta läuft über Google Play, Desktop-Builds über GitHub Releases.", alt: "Exlser auf Smartphone, Desktop, Tablet und Web" },
    downloads: {
      eyebrow: "Exlser erhalten",
      title: "Wähle den passenden Kanal für dein Gerät.",
      channels: [
        { title: "Android-Beta", text: "Android-Builds werden über das Google-Play-Betaprogramm verteilt, während die erste öffentliche Version vorbereitet wird.", cta: "Entwickler kontaktieren" },
        { title: "Desktop-Builds", text: "Lade die neuesten macOS-, Windows- und Linux-Artefakte von GitHub Releases herunter.", cta: "Releases öffnen" },
        { title: "Web-Demo", text: "Teste Exlser direkt im Browser, bevor du die Desktop-App installierst oder der Android-Beta beitrittst.", cta: "Demo testen" },
        { title: "Quellcode", text: "Exlser ist Open Source. Folge der Roadmap, prüfe den Code oder trage auf GitHub bei.", cta: "Repository ansehen" },
      ],
    },
    export: { eyebrow: "Export", title: "Teile nur die Daten, die du teilen willst.", text: "Exporte respektieren aktive Filter, Sortierung, ausgewählte Blätter und ausgeblendete Spalten.", formatsLabel: "Unterstützte Exportformate", formats: sharedFormats },
    contact: { eyebrow: "Open Source", title: "Beta testen oder Entwicklung verfolgen?", text: "Kontaktiere den Entwickler für Android-Beta-Zugang oder folge dem Projekt auf GitHub.", developer: "Entwickler kontaktieren", github: "GitHub öffnen" },
    footer: { top: "Zurück zum Exlser-Anfang", socials: "Social Links" },
  },
  zh: {
    meta: { label: "中文" },
    nav: { features: "功能", downloads: "下载", contact: "联系", language: "语言", demo: "试用演示" },
    hero: {
      aria: "Exlser 产品概览",
      eyebrow: "本地优先的表格数据工作区",
      title: "Exlser",
      copy: "将 CSV 和 Excel 文件转换为本地持久数据集，并支持筛选、SQL 查询、图表、卡片视图、二维码和多格式导出。",
      desktop: "下载桌面版",
      beta: "加入 Android 测试",
      actions: "主要操作",
      strengths: ["无需服务器", "无需云账号", "在你的设备上运行"],
    },
    intro: {
      eyebrow: "为真实表格工作而设计",
      title: "导入一次。像数据库一样探索。",
      text: "Exlser 保留表格应用的简单流程，同时加入持久数据集、结构化筛选、SQL、分析和导出工具。",
      metricsLabel: "产品能力",
      metrics: [
        { value: "9", label: "种语言" },
        { value: "5", label: "种导出格式" },
        { value: "6", label: "个平台" },
      ],
    },
    video: { eyebrow: "快速预览", title: "安装前先了解工作流程。", text: "应用会引导你完成文件选择、结构确认、数据探索、筛选、分析和导出。", demoCta: "试用演示", desktopCta: "下载到你的电脑" },
    trailer: { eyebrow: "移动端测试版", title: "加入移动端测试，看看即将上线的体验。", text: "视频展示了预期的移动端体验：导入文件、检查数据、查看分析，并在设备本地完成工作。", betaCta: "申请测试资格", moreInfo: "获取更多信息" },
    legacy: { eyebrow: "项目起点", title: "看看一切从哪里开始。", text: "最初的网页原型仍然在线，作为 Exlser 第一版想法的历史快照。", cta: "试用旧版本" },
    featuresHeading: { eyebrow: "核心功能", title: "所有操作都围绕数据集。", text: "首个版本聚焦实用的本地工作：浏览数据、查找行、查看图表，并导出当前结果。" },
    features: [
      { title: "引导式导入", text: "打开 CSV 和 Excel 文件，检查识别出的列，并在保存前确认结构。", alt: "Exlser 导入界面" },
      { title: "按类型筛选", text: "用适合列类型的控件筛选文本、数字、日期和布尔值。", alt: "Exlser 筛选控件" },
      { title: "已保存工作区", text: "从 Works 页面重新打开本地数据集，并继续之前保存的状态。", alt: "Exlser 已保存工作列表" },
      { title: "SQL 查询模式", text: "高级用户可以运行只读 SELECT 查询，并获得结构提示和行数反馈。", alt: "Exlser SQL 查询模式" },
      { title: "自动分析", text: "根据列类型获得图表建议，并可调整列和聚合方式。", alt: "Exlser 分析区域" },
      { title: "灵活导出", text: "将筛选后的数据导出为 Excel、CSV、JSON、PDF 或 SQL，并保留可见列设置。", alt: "Exlser 导出对话框" },
      { title: "带二维码的卡片", text: "切换到卡片视图，并导出每行对应的 JSON 二维码。", alt: "带二维码的 Exlser 卡片视图" },
      { title: "九种语言", text: "可使用英语、意大利语、西班牙语、法语、德语、中文、俄语、日语或葡萄牙语。", alt: "Exlser 语言设置" },
    ],
    crossPlatform: { eyebrow: "跨平台计划", title: "一个数据流程，多种设备。", text: "Exlser 使用 Flutter 开发，面向 Android、桌面和 Web。Android 测试版通过 Google Play 分发，桌面版本通过 GitHub Releases 发布。", alt: "Exlser 在手机、桌面、平板和网页上运行" },
    downloads: {
      eyebrow: "获取 Exlser",
      title: "选择适合你设备的渠道。",
      channels: [
        { title: "Android 测试版", text: "Android 版本通过 Google Play 测试计划分发，同时准备首个公开版本。", cta: "联系开发者" },
        { title: "桌面版本", text: "从 GitHub Releases 下载最新的 macOS、Windows 和 Linux 构建。", cta: "打开 Releases" },
        { title: "网页演示", text: "在安装桌面应用或加入 Android 测试前，可直接在浏览器中试用 Exlser。", cta: "试用演示" },
        { title: "源代码", text: "Exlser 是开源项目。你可以查看路线图、阅读代码或在 GitHub 贡献。", cta: "查看仓库" },
      ],
    },
    export: { eyebrow: "导出", title: "只分享你想分享的数据。", text: "导出会遵循当前筛选、排序、所选工作表和隐藏列设置。", formatsLabel: "支持的导出格式", formats: sharedFormats },
    contact: { eyebrow: "开源", title: "想试用测试版或关注开发？", text: "联系开发者获取 Android 测试资格，或在 GitHub 关注项目进展。", developer: "联系开发者", github: "打开 GitHub" },
    footer: { top: "回到 Exlser 顶部", socials: "社交链接" },
  },
  ru: {
    meta: { label: "Русский" },
    nav: { features: "Функции", downloads: "Загрузки", contact: "Контакты", language: "Язык", demo: "Попробовать демо" },
    hero: {
      aria: "Обзор продукта Exlser",
      eyebrow: "Локальное рабочее пространство для таблиц",
      title: "Exlser",
      copy: "Преобразуйте CSV и Excel в локальные наборы данных с фильтрами, SQL-запросами, графиками, карточками, QR-кодами и экспортом в разные форматы.",
      desktop: "Скачать для desktop",
      beta: "Присоединиться к Android beta",
      actions: "Основные действия",
      strengths: ["Без сервера", "Без облачного аккаунта", "Работает на вашем устройстве"],
    },
    intro: {
      eyebrow: "Для реальной работы с таблицами",
      title: "Импортируйте один раз. Исследуйте как базу данных.",
      text: "Exlser сохраняет простой подход таблиц и добавляет постоянные датасеты, структурные фильтры, SQL, аналитику и экспорт.",
      metricsLabel: "Возможности продукта",
      metrics: [
        { value: "9", label: "языков" },
        { value: "5", label: "форматов экспорта" },
        { value: "6", label: "платформ" },
      ],
    },
    video: { eyebrow: "Краткий обзор", title: "Посмотрите рабочий процесс перед установкой.", text: "Приложение ведет от выбора файла до подтверждения схемы, фильтрации, аналитики и экспорта.", demoCta: "Попробовать демо", desktopCta: "Скачать для компьютера" },
    trailer: { eyebrow: "Мобильная beta", title: "Присоединяйтесь к мобильной beta и посмотрите, что будет дальше.", text: "Видео показывает ожидаемый мобильный опыт: импорт файлов, просмотр данных, аналитика и локальная работа на вашем устройстве.", betaCta: "Запросить доступ к beta", moreInfo: "Получить больше информации" },
    legacy: { eyebrow: "История проекта", title: "Посмотрите, с чего все началось.", text: "Первый веб-прототип остается онлайн как исторический снимок исходной идеи Exlser.", cta: "Попробовать старую версию" },
    featuresHeading: { eyebrow: "Ключевые функции", title: "Все остается рядом с датасетом.", text: "Первая версия фокусируется на полезной локальной работе: просмотр данных, поиск строк, графики и экспорт текущего результата." },
    features: [
      { title: "Пошаговый импорт", text: "Открывайте CSV и Excel, проверяйте найденные колонки и подтверждайте схему перед сохранением.", alt: "Экран импорта Exlser" },
      { title: "Фильтры по типам", text: "Фильтруйте текст, числа, даты и boolean через элементы управления для выбранного типа.", alt: "Фильтры Exlser" },
      { title: "Сохраненные рабочие области", text: "Открывайте локальные датасеты со страницы Works и продолжайте с сохраненного состояния.", alt: "Список сохраненных работ Exlser" },
      { title: "SQL-режим", text: "Опытные пользователи могут выполнять read-only SELECT с подсказками схемы и количеством строк.", alt: "SQL-режим Exlser" },
      { title: "Автоматическая аналитика", text: "Получайте предложенные графики по типам колонок и меняйте колонки и агрегации.", alt: "Раздел аналитики Exlser" },
      { title: "Гибкий экспорт", text: "Экспортируйте в Excel, CSV, JSON, PDF или SQL с учетом видимых колонок.", alt: "Диалог экспорта Exlser" },
      { title: "Карточки с QR-кодами", text: "Переключайтесь на карточки и экспортируйте QR-код каждой строки в JSON.", alt: "Карточки Exlser с QR" },
      { title: "Девять языков", text: "Используйте Exlser на английском, итальянском, испанском, французском, немецком, китайском, русском, японском или португальском.", alt: "Настройки языка Exlser" },
    ],
    crossPlatform: { eyebrow: "Кроссплатформенный план", title: "Один поток данных, много устройств.", text: "Exlser разрабатывается на Flutter для Android, desktop и web. Android beta распространяется через Google Play, desktop-сборки через GitHub Releases.", alt: "Exlser на телефоне, desktop, планшете и web" },
    downloads: {
      eyebrow: "Получить Exlser",
      title: "Выберите канал для вашего устройства.",
      channels: [
        { title: "Android beta", text: "Android-сборки распространяются через beta-программу Google Play перед первой публичной версией.", cta: "Связаться с разработчиком" },
        { title: "Desktop-сборки", text: "Скачайте последние артефакты macOS, Windows и Linux из GitHub Releases.", cta: "Открыть releases" },
        { title: "Web-демо", text: "Попробуйте Exlser прямо в браузере перед установкой desktop-приложения или участием в Android beta.", cta: "Попробовать демо" },
        { title: "Исходный код", text: "Exlser открыт. Следите за roadmap, изучайте код или участвуйте на GitHub.", cta: "Открыть репозиторий" },
      ],
    },
    export: { eyebrow: "Экспорт", title: "Делитесь только нужными данными.", text: "Экспорт учитывает активные фильтры, сортировку, выбранные листы и скрытые колонки.", formatsLabel: "Поддерживаемые форматы экспорта", formats: sharedFormats },
    contact: { eyebrow: "Open source", title: "Хотите попробовать beta или следить за разработкой?", text: "Свяжитесь с разработчиком для Android beta или следите за проектом на GitHub.", developer: "Связаться", github: "Открыть GitHub" },
    footer: { top: "Вернуться наверх Exlser", socials: "Социальные ссылки" },
  },
  ja: {
    meta: { label: "日本語" },
    nav: { features: "機能", downloads: "ダウンロード", contact: "連絡先", language: "言語", demo: "デモを試す" },
    hero: {
      aria: "Exlser 製品概要",
      eyebrow: "ローカル優先のスプレッドシート作業空間",
      title: "Exlser",
      copy: "CSV と Excel を、フィルター、SQL クエリ、グラフ、カード表示、QR コード、複数形式エクスポートに対応したローカルデータセットに変換します。",
      desktop: "デスクトップ版を入手",
      beta: "Android ベータに参加",
      actions: "主な操作",
      strengths: ["サーバー不要", "クラウドアカウント不要", "端末上で動作"],
    },
    intro: {
      eyebrow: "実務の表計算作業向け",
      title: "一度インポート。データベースのように探索。",
      text: "Exlser は表計算アプリの使いやすさを保ちつつ、永続データセット、構造化フィルター、SQL、分析、エクスポートを追加します。",
      metricsLabel: "製品機能",
      metrics: [
        { value: "9", label: "言語" },
        { value: "5", label: "エクスポート形式" },
        { value: "6", label: "対象プラットフォーム" },
      ],
    },
    video: { eyebrow: "クイックプレビュー", title: "インストール前に流れを確認。", text: "ファイル選択からスキーマ確認、探索、フィルター、分析、エクスポートまで案内します。", demoCta: "デモを試す", desktopCta: "コンピューター用をダウンロード" },
    trailer: { eyebrow: "モバイルベータ", title: "モバイルベータに参加して今後の体験を確認。", text: "動画では、ファイルのインポート、データ確認、分析、端末上でのローカル作業というモバイル体験を紹介します。", betaCta: "ベータアクセスを依頼", moreInfo: "詳しい情報を見る" },
    legacy: { eyebrow: "プロジェクトの原点", title: "すべての始まりを見る。", text: "最初の Web プロトタイプは、Exlser の初期アイデアの記録として今も公開されています。", cta: "旧バージョンを試す" },
    featuresHeading: { eyebrow: "主な機能", title: "すべてがデータセットの近くにあります。", text: "最初のリリースは、データ閲覧、行の検索、グラフ確認、現在の結果のエクスポートに集中しています。" },
    features: [
      { title: "ガイド付きインポート", text: "CSV と Excel を開き、検出された列を確認し、保存前にスキーマを確定します。", alt: "Exlser インポート画面" },
      { title: "型に応じたフィルター", text: "テキスト、数値、日付、真偽値を、選択した列に合う操作で絞り込みます。", alt: "Exlser フィルター操作" },
      { title: "保存されたワークスペース", text: "Works ページからローカルデータセットを再度開き、保存状態から続けられます。", alt: "Exlser 保存済み作業一覧" },
      { title: "SQL クエリモード", text: "上級者はスキーマヒントと行数表示付きで読み取り専用 SELECT を実行できます。", alt: "Exlser SQL クエリモード" },
      { title: "自動分析", text: "列タイプからグラフ候補を取得し、列や集計を調整できます。", alt: "Exlser 分析セクション" },
      { title: "柔軟なエクスポート", text: "表示列を尊重して Excel、CSV、JSON、PDF、SQL にエクスポートできます。", alt: "Exlser エクスポート画面" },
      { title: "QR コード付きカード", text: "カード表示に切り替え、各行を JSON として表す QR コードを出力できます。", alt: "QR コード付き Exlser カード表示" },
      { title: "9 言語対応", text: "英語、イタリア語、スペイン語、フランス語、ドイツ語、中国語、ロシア語、日本語、ポルトガル語で利用できます。", alt: "Exlser 言語設定" },
    ],
    crossPlatform: { eyebrow: "クロスプラットフォーム計画", title: "1 つのデータ作業を複数の端末で。", text: "Exlser は Flutter で Android、デスクトップ、Web 向けに開発されています。Android ベータは Google Play、デスクトップ版は GitHub Releases で配布されます。", alt: "スマートフォン、デスクトップ、タブレット、Web で動作する Exlser" },
    downloads: {
      eyebrow: "Exlser を入手",
      title: "端末に合うチャンネルを選択してください。",
      channels: [
        { title: "Android ベータ", text: "Android 版は最初の公開リリース準備中に Google Play ベータプログラムで配布されます。", cta: "開発者に連絡" },
        { title: "デスクトップ版", text: "macOS、Windows、Linux の最新ビルドを GitHub Releases から入手できます。", cta: "Releases を開く" },
        { title: "Web デモ", text: "デスクトップ版のインストールや Android ベータ参加前に、ブラウザで Exlser を試せます。", cta: "デモを試す" },
        { title: "ソースコード", text: "Exlser はオープンソースです。ロードマップやコードを確認し、GitHub で貢献できます。", cta: "リポジトリを見る" },
      ],
    },
    export: { eyebrow: "エクスポート", title: "共有したいデータだけを共有。", text: "エクスポートはフィルター、並び替え、選択シート、非表示列を反映します。", formatsLabel: "対応エクスポート形式", formats: sharedFormats },
    contact: { eyebrow: "オープンソース", title: "ベータを試す、または開発を追跡しますか？", text: "Android ベータへのアクセスは開発者に連絡してください。開発状況は GitHub で確認できます。", developer: "開発者に連絡", github: "GitHub を開く" },
    footer: { top: "Exlser の先頭に戻る", socials: "ソーシャルリンク" },
  },
  pt: {
    meta: { label: "Português" },
    nav: { features: "Recursos", downloads: "Downloads", contact: "Contato", language: "Idioma", demo: "Testar demo" },
    hero: {
      aria: "Visão geral do Exlser",
      eyebrow: "Workspace local para planilhas",
      title: "Exlser",
      copy: "Transforme arquivos CSV e Excel em datasets locais persistentes com filtros, consultas SQL, gráficos, cartões, QR codes e exportação em vários formatos.",
      desktop: "Baixar desktop",
      beta: "Entrar na beta Android",
      actions: "Ações principais",
      strengths: ["Sem servidor", "Sem conta na nuvem", "Roda no seu dispositivo"],
    },
    intro: {
      eyebrow: "Feito para trabalho real com planilhas",
      title: "Importe uma vez. Explore como um banco de dados.",
      text: "Exlser mantém o fluxo simples de uma planilha e adiciona datasets persistentes, filtros estruturados, SQL, análises e ferramentas de exportação.",
      metricsLabel: "Capacidades do produto",
      metrics: [
        { value: "9", label: "idiomas" },
        { value: "5", label: "formatos de exportação" },
        { value: "6", label: "plataformas" },
      ],
    },
    video: { eyebrow: "Prévia rápida", title: "Veja o fluxo antes de instalar.", text: "O app guia você da seleção do arquivo até confirmação do esquema, exploração, filtros, análises e exportação.", demoCta: "Testar demo", desktopCta: "Baixar para seu computador" },
    trailer: { eyebrow: "Beta mobile", title: "Participe da beta mobile e veja o que está chegando.", text: "O vídeo mostra a experiência mobile prevista: importar arquivos, revisar dados, explorar análises e trabalhar localmente no seu dispositivo.", betaCta: "Solicitar acesso beta", moreInfo: "Obter mais informações" },
    legacy: { eyebrow: "Origem do projeto", title: "Veja onde tudo começou.", text: "O protótipo web original continua online como um registro histórico da primeira ideia do Exlser.", cta: "Testar versão antiga" },
    featuresHeading: { eyebrow: "Recursos principais", title: "Tudo fica perto do dataset.", text: "A primeira versão foca no trabalho local útil: navegar dados, encontrar linhas, ver gráficos e exportar exatamente o resultado atual." },
    features: [
      { title: "Importação guiada", text: "Abra CSV e Excel, revise colunas detectadas e confirme o esquema antes de salvar.", alt: "Tela de importação do Exlser" },
      { title: "Filtros por tipo", text: "Filtre textos, números, datas e booleanos com controles adequados à coluna.", alt: "Controles de filtro do Exlser" },
      { title: "Workspaces salvos", text: "Reabra datasets locais pela página Trabalhos e continue do estado salvo.", alt: "Lista de trabalhos salvos no Exlser" },
      { title: "Modo SQL", text: "Usuários avançados podem executar SELECT somente leitura com ajuda de esquema e contagem de linhas.", alt: "Modo SQL do Exlser" },
      { title: "Análises automáticas", text: "Receba gráficos sugeridos pelos tipos de coluna e ajuste colunas e agregações.", alt: "Seção de análises do Exlser" },
      { title: "Exportação flexível", text: "Exporte para Excel, CSV, JSON, PDF ou SQL respeitando colunas visíveis.", alt: "Diálogo de exportação do Exlser" },
      { title: "Cartões com QR codes", text: "Use a visualização em cartões e exporte um QR por linha com o registro em JSON.", alt: "Cartões do Exlser com QR code" },
      { title: "Nove idiomas", text: "Use Exlser em inglês, italiano, espanhol, francês, alemão, chinês, russo, japonês ou português.", alt: "Configurações de idioma do Exlser" },
    ],
    crossPlatform: { eyebrow: "Plano multiplataforma", title: "Um fluxo de dados, muitos dispositivos.", text: "Exlser é desenvolvido com Flutter para Android, desktop e web. A beta Android é distribuída pelo Google Play, e builds desktop pelo GitHub Releases.", alt: "Exlser em celular, desktop, tablet e web" },
    downloads: {
      eyebrow: "Obter Exlser",
      title: "Escolha o canal adequado ao seu dispositivo.",
      channels: [
        { title: "Beta Android", text: "Builds Android são distribuídas pelo programa beta do Google Play enquanto a primeira versão pública é preparada.", cta: "Contatar desenvolvedor" },
        { title: "Builds desktop", text: "Baixe os artefatos mais recentes para macOS, Windows e Linux no GitHub Releases.", cta: "Abrir releases" },
        { title: "Demo web", text: "Teste o Exlser diretamente no navegador antes de instalar o app desktop ou entrar na beta Android.", cta: "Testar demo" },
        { title: "Código-fonte", text: "Exlser é open source. Siga o roadmap, veja o código ou contribua pelo GitHub.", cta: "Ver repositório" },
      ],
    },
    export: { eyebrow: "Exportação", title: "Compartilhe apenas os dados que quer compartilhar.", text: "Exportações respeitam filtros ativos, ordenação, folhas selecionadas e colunas ocultas.", formatsLabel: "Formatos de exportação suportados", formats: sharedFormats },
    contact: { eyebrow: "Open source", title: "Quer testar a beta ou acompanhar o desenvolvimento?", text: "Contate o desenvolvedor para acesso à beta Android ou acompanhe o projeto no GitHub.", developer: "Contatar desenvolvedor", github: "Abrir GitHub" },
    footer: { top: "Voltar ao topo do Exlser", socials: "Links sociais" },
  },
};

export function getInitialLanguage() {
  const pathLanguage = getLanguageFromPath(window.location.pathname);

  if (pathLanguage) {
    return pathLanguage;
  }

  const browserLanguage = window.navigator.language.split("-")[0];

  if (translations[browserLanguage]) {
    return browserLanguage;
  }

  return "en";
}

export function getLanguageFromPath(pathname) {
  const firstSegment = pathname.split("/").filter(Boolean)[0];

  return languageCodes.includes(firstSegment) ? firstSegment : null;
}

export function getLocalizedPath(language, currentLocation = window.location) {
  const safeLanguage = translations[language] ? language : "en";
  const segments = currentLocation.pathname.split("/").filter(Boolean);

  if (languageCodes.includes(segments[0])) {
    segments[0] = safeLanguage;
  } else {
    segments.unshift(safeLanguage);
  }

  const path = `/${segments.join("/")}/`;

  return `${path}${currentLocation.search}${currentLocation.hash}`;
}

export function getDemoPath(currentLocation = window.location) {
  const demoPath = "/demo/";
  const isLocalHost = ["localhost", "127.0.0.1", "::1"].includes(currentLocation.hostname);

  return isLocalHost ? `https://exlser.com${demoPath}` : demoPath;
}
