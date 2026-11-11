/// Keeps the offset between the local clock and the server clock.
///
/// Every exam response carries `server_time`; timers are computed from the
/// server's `finished_at` and [now], never from the local clock alone.
///
/// Samples are not applied blindly: each one has an uncertainty (half its
/// round trip, plus half a second when the server only sends whole seconds),
/// and the offset of the most precise sample is kept. A kept sample slowly
/// loses precision with age (local clock drift), so fresher samples take
/// over in time. A sample that disagrees with the kept offset by more than
/// both uncertainties means the local clock jumped (NTP correction, manual
/// change, resume from sleep): it then replaces the offset at once.
class ServerClock {
  ServerClock({DateTime Function()? localNow})
      : _localNow = localNow ?? DateTime.now;

  final DateTime Function() _localNow;
  Duration _offset = Duration.zero;
  bool _synced = false;

  /// Uncertainty of the kept offset when it was measured.
  Duration _uncertainty = const Duration(days: 1);

  /// Local time (UTC) when the kept offset was measured.
  DateTime? _sampledAt;

  /// Called whenever the kept offset changes (persist it).
  void Function(Duration offset, Duration uncertainty)? onOffsetChanged;

  /// Assumed local clock drift used to age a kept sample (100 ppm).
  static const _driftPerSecondUs = 100;

  /// Extra tolerance before two samples are considered a clock jump.
  static const jumpTolerance = Duration(seconds: 1);

  /// Uncertainty used for samples without a known round trip.
  static const unknownRttUncertainty = Duration(seconds: 5);

  /// server time - local time.
  Duration get offset => _offset;

  /// True once at least one server time sample has been applied (or a
  /// persisted offset was restored).
  bool get isSynced => _synced;

  /// Current server time (UTC).
  DateTime now() => _localNow().toUtc().add(_offset);

  /// Precision of the kept offset right now (grows with its age).
  Duration get currentUncertainty {
    final at = _sampledAt;
    if (at == null) return _uncertainty;
    final age = _localNow().toUtc().difference(at).abs();
    return _uncertainty + Duration(microseconds: age.inSeconds * _driftPerSecondUs);
  }

  /// Restores an offset persisted by an earlier run (used until the first
  /// sample arrives; any real sample replaces it).
  void restore(Duration offset) {
    if (_synced) return;
    _offset = offset;
    _synced = true;
    _uncertainty = const Duration(days: 1);
    _sampledAt = null;
  }

  /// Applies a `server_time` sample.
  ///
  /// When [requestStartedAt] is given, the round trip is assumed symmetric and
  /// the sample is compared against the midpoint between request and response.
  void update(DateTime serverTime, {DateTime? requestStartedAt}) {
    final received = _localNow().toUtc();
    var reference = received;
    var uncertainty = unknownRttUncertainty;
    if (requestStartedAt != null) {
      final rtt = received.difference(requestStartedAt.toUtc());
      if (!rtt.isNegative) {
        reference = requestStartedAt.toUtc().add(rtt ~/ 2);
        uncertainty = rtt ~/ 2;
      }
    }
    final server = serverTime.toUtc();
    if (server.millisecond == 0 && server.microsecond == 0) {
      // API v1 sent whole seconds (truncated): up to one second less precise.
      uncertainty += const Duration(seconds: 1);
    }
    final candidate = server.difference(reference);

    final current = currentUncertainty;
    final jumped = _synced &&
        (candidate - _offset).abs() > uncertainty + current + jumpTolerance;
    if (!_synced || jumped || uncertainty <= current) {
      _offset = candidate;
      _uncertainty = uncertainty;
      _sampledAt = received;
      _synced = true;
      onOffsetChanged?.call(_offset, _uncertainty);
    }
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
