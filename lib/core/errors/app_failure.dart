/// Base type for expected, user-presentable failures.
///
/// Data layers translate low-level exceptions into one of these so that the
/// domain and presentation layers never depend on transport details.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  /// Safe-to-display description. Must not contain secrets or personal data.
  final String message;

  /// Original error, kept for logging only.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message = 'Check your connection and try again.',
    Object? cause,
  ]) : super(cause: cause);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'The requested item was not found.'])
    : super();
}

class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure([
    super.message = 'Something went wrong.',
    Object? cause,
  ]) : super(cause: cause);
}
