import 'package:flutter/foundation.dart';

/// How durable the storage the browser granted for the database is.
enum WebDatabaseDurability {
  /// Writes survive a reload, in OPFS or IndexedDB.
  persistent,

  /// Writes are kept, but two tabs open at once can corrupt each other.
  unreliable,

  /// Nothing is stored: the database lives in memory and dies with the tab.
  inMemory,
}

/// The outcome of opening the database in a browser.
///
/// Drift picks the best storage the browser allows and silently degrades — to
/// an unreliable one, or to no storage at all — when it can allow none. That
/// degradation is exactly what a user of the web demo needs to be told, since
/// a dataset they imported would otherwise vanish without explanation.
///
/// Plain types only: this is read on every platform, while the drift types it
/// is built from exist on the web alone.
@immutable
class WebDatabaseStatus {
  final WebDatabaseDurability durability;

  /// Drift's name for the chosen storage, for diagnostics.
  final String implementation;

  /// Browser features drift looked for and did not find.
  final List<String> missingFeatures;

  const WebDatabaseStatus({
    required this.durability,
    required this.implementation,
    this.missingFeatures = const [],
  });

  bool get isPersistent => durability == WebDatabaseDurability.persistent;
}
