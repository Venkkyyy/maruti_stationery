/// Sealed class for typed failures across the app.
/// Use this when propagating errors through providers.
sealed class Failure {
  final String message;
  const Failure(this.message);
}

/// Firebase / network errors
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'A server error occurred. Please try again.',
  ]);
}

/// Local validation / logic errors
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Auth-specific errors
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Not found errors
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested item was not found.']);
}

/// Permission / security errors
class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'You do not have permission for this action.',
  ]);
}
