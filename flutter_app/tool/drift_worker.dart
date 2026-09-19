// Entry point of the web worker Drift runs SQLite in.
//
// Compiled to `web/drift_worker.js`, which the web build serves and
// `connection_web.dart` loads. Keeping the source here — instead of relying on
// a prebuilt artifact downloaded per release — means the worker is always
// compiled from the exact Drift version in pubspec.lock:
//
//   dart compile js -O4 -o web/drift_worker.js tool/drift_worker.dart
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
