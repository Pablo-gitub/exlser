/// Base interface for all usecases.
///
/// A usecase represents a single business operation
/// executed by the application.
abstract class UseCase<Result, Params> {
  Future<Result> call(Params params);
}

/// Empty params class for usecases without parameters.
class NoParams {
  const NoParams();
}
