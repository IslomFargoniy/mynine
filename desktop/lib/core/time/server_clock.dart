/// Keeps the offset between the local clock and the server clock.
///
/// Every exam response carries `server_time`; timers are computed from the
/// server's `finished_at` and [now], never from the local clock alone.
class ServerClock {
  ServerClock({DateTime Function()? localNow})
      : _localNow = localNow ?? DateTime.now;

  final DateTime Function() _localNow;
  Duration _offset = Duration.zero;
  bool _synced = false;

  /// server time - local time.
  Duration get offset => _offset;

  /// True once at least one server time sample has been applied.
  bool get isSynced => _synced;

  /// Current server time (UTC).
  DateTime now() => _localNow().toUtc().add(_offset);

  /// Applies a `server_time` sample.
  ///
  /// When [requestStartedAt] is given, the round trip is assumed symmetric and
  /// the sample is compared against the midpoint between request and response.
  void update(DateTime serverTime, {DateTime? requestStartedAt}) {
    final received = _localNow().toUtc();
    var reference = received;
    if (requestStartedAt != null) {
      final rtt = received.difference(requestStartedAt.toUtc());
      if (!rtt.isNegative) {
        reference = requestStartedAt.toUtc().add(rtt ~/ 2);
      }
    }
    _offset = serverTime.toUtc().difference(reference);
    _synced = true;
  }

  /// Time left until [finishedAt] according to the server clock (never negative).
  Duration remaining(DateTime? finishedAt) {
    if (finishedAt == null) return Duration.zero;
    final left = finishedAt.toUtc().difference(now());
    return left.isNegative ? Duration.zero : left;
  }

  bool isExpired(DateTime? finishedAt) =>
      finishedAt != null && !now().isBefore(finishedAt.toUtc());
}

/// Formats a duration as `HH:MM:SS`.
String formatHms(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(h)}:${two(m)}:${two(s)}';
}
