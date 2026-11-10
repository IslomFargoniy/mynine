import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/core/time/server_clock.dart';
import 'package:mynine_desktop/core/util/semver.dart';

void main() {
  group('SemVer', () {
    test('ordering', () {
      expect(SemVer.parse('1.2.0') > SemVer.parse('1.1.9'), isTrue);
      expect(SemVer.parse('1.10.0') > SemVer.parse('1.9.0'), isTrue);
      expect(SemVer.parse('2.0.0') > SemVer.parse('1.99.99'), isTrue);
      expect(SemVer.parse('1.0.0') == SemVer.parse('v1.0.0+5'), isTrue);
      expect(SemVer.parse('1.0.0-beta') < SemVer.parse('1.0.0'), isTrue);
      expect(SemVer.parse('1.0.0-beta.2') < SemVer.parse('1.0.0-beta.10'), isTrue);
      expect(SemVer.parse('1.0') == SemVer.parse('1.0.0'), isTrue);
    });

    test('helpers', () {
      expect(isNewerVersion('1.2.0', '1.1.0'), isTrue);
      expect(isNewerVersion('1.1.0', '1.1.0'), isFalse);
      expect(isNewerVersion('garbage', '1.1.0'), isFalse);
      expect(isNewerVersion(null, '1.1.0'), isFalse);
      expect(isBelowMin('1.0.0', '1.1.0'), isTrue);
      expect(isBelowMin('1.1.0', '1.1.0'), isFalse);
      expect(isBelowMin('1.1.0', null), isFalse);
    });
  });

  group('ServerClock', () {
    test('timer uses server offset, not local clock', () {
      var local = DateTime.utc(2026, 11, 12, 9, 0, 0);
      final clock = ServerClock(localNow: () => local);
      // Server is 90 s ahead of this PC.
      clock.update(DateTime.utc(2026, 11, 12, 9, 1, 30));
      expect(clock.offset, const Duration(seconds: 90));
      final finishedAt = DateTime.parse('2026-11-12T14:31:30+05:00'); // 09:31:30Z
      expect(clock.remaining(finishedAt), const Duration(minutes: 30));
      local = local.add(const Duration(minutes: 10));
      expect(clock.remaining(finishedAt), const Duration(minutes: 20));
      expect(formatHms(clock.remaining(finishedAt)), '00:20:00');
      local = local.add(const Duration(minutes: 21));
      expect(clock.remaining(finishedAt), Duration.zero);
      expect(clock.isExpired(finishedAt), isTrue);
    });

    test('uses the round-trip midpoint', () {
      var local = DateTime.utc(2026, 1, 1, 0, 0, 2);
      final clock = ServerClock(localNow: () => local);
      // Request sent at 00:00:00, response at 00:00:02, server said 00:00:11.
      clock.update(DateTime.utc(2026, 1, 1, 0, 0, 11), requestStartedAt: DateTime.utc(2026, 1, 1));
      expect(clock.offset, const Duration(seconds: 10));
      local = DateTime.utc(2026, 1, 1, 0, 0, 5);
      expect(clock.now(), DateTime.utc(2026, 1, 1, 0, 0, 15));
    });

    test('negative offset (PC clock ahead)', () {
      final clock = ServerClock(localNow: () => DateTime.utc(2026, 1, 1, 12));
      clock.update(DateTime.utc(2026, 1, 1, 11, 55));
      expect(clock.remaining(DateTime.utc(2026, 1, 1, 12)), const Duration(minutes: 5));
    });
  });
}
