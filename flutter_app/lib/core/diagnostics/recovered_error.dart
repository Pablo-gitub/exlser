import 'package:flutter/foundation.dart';

/// Records an error the app deliberately recovered from.
///
/// Plenty of failures here are worth surviving rather than surfacing: a
/// workspace layout that could not be persisted, a column list that could not
/// be read, a chart that could not be built. Catching them as `catch (_)` kept
/// the app usable but threw the cause away, so a bug that reaches the user as
/// "nothing happened" — or as a generic error code — left nothing to go on.
///
/// This keeps the behaviour and the cause: in a debug build the failure is
/// printed with the place it came from; in a release build the call compiles
/// away, which matters for a local-first app that must not write logs of the
/// user's data anywhere.
void recordRecoveredError(
  Object error,
  StackTrace stackTrace, {
  required String context,
}) {
  if (!kDebugMode) return;

  debugPrint('[exlser] recovered from an error in $context: $error');
  debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
}
