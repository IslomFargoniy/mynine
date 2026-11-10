/// Machine error codes from API.md.
enum ApiErrorCode {
  unauthenticated('unauthenticated'),
  deviceBlocked('device_blocked'),
  clientOutdated('client_outdated'),
  invalidCode('invalid_code'),
  mockNotActive('mock_not_active'),
  mockNotStarted('mock_not_started'),
  mockFinished('mock_finished'),
  attemptFinished('attempt_finished'),
  paused('paused'),
  moduleLocked('module_locked'),
  moduleTimeOver('module_time_over'),
  validationFailed('validation_failed'),
  deviceNotApproved('device_not_approved'),
  invalidPassword('invalid_password'),
  forbidden('forbidden'),
  notFound('not_found'),
  methodNotAllowed('method_not_allowed'),
  tooManyRequests('too_many_requests'),
  serverError('server_error'),

  /// Client-side: no connection / timeout / DNS.
  network('network'),

  /// Anything else (unexpected status, malformed body, rate limit, …).
  unknown('unknown');

  const ApiErrorCode(this.wire);
  final String wire;

  static ApiErrorCode fromWire(String? code, int? status) {
    for (final c in values) {
      if (c.wire == code) return c;
    }
    // Fall back on HTTP status when the body has no code.
    return switch (status) {
      401 => unauthenticated,
      403 => forbidden,
      404 => notFound,
      426 => clientOutdated,
      429 => tooManyRequests,
      _ when status != null && status >= 500 => serverError,
      _ => unknown,
    };
  }
}

class ApiException implements Exception {
  ApiException({
    required this.code,
    this.statusCode,
    this.message,
    this.minVersion,
    this.startsAt,
    this.body,
  });

  final ApiErrorCode code;
  final int? statusCode;
  final String? message;

  /// For `client_outdated` (426).
  final String? minVersion;

  /// For `mock_not_started`.
  final DateTime? startsAt;
  final Object? body;

  bool get isNetwork => code == ApiErrorCode.network;

  /// True when retrying later may succeed (network or 5xx / 429).
  bool get isTransient =>
      isNetwork ||
      (statusCode != null && (statusCode! >= 500 || statusCode == 429));

  /// Candidate-facing English message.
  String get userMessage => switch (code) {
        ApiErrorCode.invalidCode => 'This code is not valid. Please check it and try again.',
        ApiErrorCode.mockNotActive => 'This exam is not active. Please ask the reception.',
        ApiErrorCode.mockNotStarted => startsAt != null
            ? 'The exam has not started yet. It starts at ${_hm(startsAt!)}.'
            : 'The exam has not started yet.',
        ApiErrorCode.mockFinished => 'This exam has already finished.',
        ApiErrorCode.attemptFinished => 'This exam has already been completed.',
        ApiErrorCode.deviceBlocked => 'This computer is blocked. Please ask the reception.',
        ApiErrorCode.clientOutdated => 'This app must be updated before the exam can start.',
        ApiErrorCode.unauthenticated => 'Session expired. Please enter your code again.',
        ApiErrorCode.network => 'No connection to the server. Please try again.',
        ApiErrorCode.paused => 'The exam is paused by the invigilator.',
        ApiErrorCode.moduleLocked => 'Please finish the previous section first.',
        ApiErrorCode.moduleTimeOver => 'Time for this section is over.',
        ApiErrorCode.validationFailed => message ?? 'Please check the entered data.',
        ApiErrorCode.deviceNotApproved =>
          message ?? 'This PC is waiting for administrator approval.',
        ApiErrorCode.invalidPassword => 'Incorrect password.',
        ApiErrorCode.forbidden => 'Access denied.',
        ApiErrorCode.notFound => 'Not found on the server.',
        ApiErrorCode.methodNotAllowed => 'Something went wrong. Please try again.',
        ApiErrorCode.tooManyRequests => 'Too many attempts. Please wait a minute and try again.',
        ApiErrorCode.serverError => 'The server has a problem. Please try again shortly.',
        ApiErrorCode.unknown => statusCode == 429
            ? 'Too many attempts. Please wait a minute and try again.'
            : 'Something went wrong. Please try again.',
      };

  static String _hm(DateTime t) {
    final l = t.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() =>
      'ApiException(${code.wire}, status: $statusCode, message: $message)';
}
