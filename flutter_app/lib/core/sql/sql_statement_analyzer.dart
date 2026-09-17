import 'package:sqlparser/sqlparser.dart';

/// What a statement does, as far as the read-only boundary is concerned.
enum SqlStatementKind {
  /// A `SELECT`, a compound select (`UNION` …) or a `VALUES` clause.
  select,

  /// Writes data or changes state: DML, DDL, `PRAGMA`, transactions, `VACUUM` …
  write,

  /// Parses, but is neither of the above.
  other,

  /// Does not parse as SQL at all.
  invalid,
}

/// What a single SQL string turned out to be.
class SqlStatementAnalysis {
  final SqlStatementKind kind;

  /// True when the string holds more than one statement.
  final bool hasMultipleStatements;

  /// Every table named in a `FROM`/`JOIN`, including the ones reached through a
  /// comma-separated table list or a subquery. Names are unquoted; a CTE's own
  /// name is not included (see [cteNames]).
  final Set<String> referencedTables;

  /// Names introduced by a `WITH` clause. They resolve inside the statement, so
  /// they are not checked against the caller's table allowlist.
  final Set<String> cteNames;

  /// Table-valued functions used as a source (`FROM pragma_table_info(...)`).
  final Set<String> tableValuedFunctions;

  /// Lower-cased names of every function called in the statement.
  final Set<String> functionNames;

  const SqlStatementAnalysis({
    required this.kind,
    required this.hasMultipleStatements,
    this.referencedTables = const {},
    this.cteNames = const {},
    this.tableValuedFunctions = const {},
    this.functionNames = const {},
  });

  bool get isSelect => kind == SqlStatementKind.select;
}

/// Parses SQL to decide what it does and which tables it touches.
///
/// This replaces the regular expressions the read-only boundary used to rely on.
/// Those matched table names only right after `FROM`/`JOIN`, so a comma-joined
/// table (`SELECT * FROM sheet, other_dataset_table`, `… , sqlite_master`) went
/// unnoticed, and they scanned raw text for blocked keywords, which rejected a
/// perfectly safe `WHERE note = 'update'`. An AST answers both questions
/// exactly: what kind of statement it is, and every table it reads.
class SqlStatementAnalyzer {
  /// SQL functions that reach outside the database. None of them is available in
  /// a default sqlite3 build, and none is ever needed here.
  static const Set<String> dangerousFunctions = {
    'load_extension',
    'readfile',
    'writefile',
    'edit',
    'fts3_tokenizer',
    'lsmode',
  };

  const SqlStatementAnalyzer();

  SqlStatementAnalysis analyze(String sql) {
    final trimmed = sql.trim();
    if (trimmed.isEmpty) {
      return const SqlStatementAnalysis(
        kind: SqlStatementKind.invalid,
        hasMultipleStatements: false,
      );
    }

    final engine = SqlEngine();
    final result = engine.parse(ParserEntrypoint.statement, trimmed);

    if (result.errors.isNotEmpty) {
      // A second statement is a parse error for this entrypoint; tell the two
      // cases apart so the caller can report the right thing.
      return SqlStatementAnalysis(
        kind: SqlStatementKind.invalid,
        hasMultipleStatements: _countsAsMultiple(engine, trimmed),
      );
    }

    final root = result.rootNode;
    final referencedTables = <String>{};
    final cteNames = <String>{};
    final tableValuedFunctions = <String>{};
    final functionNames = <String>{};

    for (final node in root.selfAndDescendants) {
      if (node is TableReference) {
        referencedTables.add(node.tableName);
      } else if (node is CommonTableExpression) {
        cteNames.add(node.cteTableName);
      } else if (node is TableValuedFunction) {
        tableValuedFunctions.add(node.name.toLowerCase());
      } else if (node is FunctionExpression) {
        functionNames.add(node.name.toLowerCase());
      }
    }

    return SqlStatementAnalysis(
      kind: _kindOf(root),
      hasMultipleStatements: false,
      referencedTables: referencedTables,
      cteNames: cteNames,
      tableValuedFunctions: tableValuedFunctions,
      functionNames: functionNames,
    );
  }

  bool _countsAsMultiple(SqlEngine engine, String sql) {
    final result = engine.parse(ParserEntrypoint.multiple, sql);

    final statements = [
      for (final statement in result.rootNode.statements)
        if (statement is! InvalidStatement) statement,
    ];
    return statements.length > 1;
  }

  SqlStatementKind _kindOf(AstNode node) {
    if (node is InvalidStatement) return SqlStatementKind.invalid;
    if (node is BaseSelectStatement) return SqlStatementKind.select;

    if (node is InsertStatement ||
        node is UpdateStatement ||
        node is DeleteStatement ||
        node is SchemaStatement ||
        node is AlterTableStatement ||
        node is PragmaCommand ||
        node is VacuumStatement ||
        node is BeginTransactionStatement ||
        node is CommitStatement ||
        node is RollbackStatement ||
        node is SavepointStatement ||
        node is ReleaseStatement ||
        node is Block) {
      return SqlStatementKind.write;
    }

    return SqlStatementKind.other;
  }
}
