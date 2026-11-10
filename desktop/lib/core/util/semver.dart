/// Minimal semantic version parsing / comparison (`1.2.3`, `1.2.3-beta.1+5`).
class SemVer implements Comparable<SemVer> {
  const SemVer(this.major, this.minor, this.patch, [this.preRelease = const []]);

  final int major;
  final int minor;
  final int patch;
  final List<String> preRelease;

  static SemVer? tryParse(String? input) {
    if (input == null) return null;
    var s = input.trim();
    if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
    final plus = s.indexOf('+');
    if (plus >= 0) s = s.substring(0, plus);
    var pre = <String>[];
    final dash = s.indexOf('-');
    if (dash >= 0) {
      pre = s.substring(dash + 1).split('.').where((p) => p.isNotEmpty).toList();
      s = s.substring(0, dash);
    }
    final parts = s.split('.');
    if (parts.isEmpty || parts.length > 3) return null;
    final nums = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0) return null;
      nums.add(n);
    }
    while (nums.length < 3) {
      nums.add(0);
    }
    return SemVer(nums[0], nums[1], nums[2], pre);
  }

  static SemVer parse(String input) =>
      tryParse(input) ?? (throw FormatException('Invalid version: $input'));

  @override
  int compareTo(SemVer other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    // A version without pre-release is greater than one with it.
    if (preRelease.isEmpty && other.preRelease.isEmpty) return 0;
    if (preRelease.isEmpty) return 1;
    if (other.preRelease.isEmpty) return -1;
    final n = preRelease.length < other.preRelease.length
        ? preRelease.length
        : other.preRelease.length;
    for (var i = 0; i < n; i++) {
      final a = preRelease[i];
      final b = other.preRelease[i];
      final ai = int.tryParse(a);
      final bi = int.tryParse(b);
      int c;
      if (ai != null && bi != null) {
        c = ai.compareTo(bi);
      } else if (ai != null) {
        c = -1;
      } else if (bi != null) {
        c = 1;
      } else {
        c = a.compareTo(b);
      }
      if (c != 0) return c;
    }
    return preRelease.length.compareTo(other.preRelease.length);
  }

  bool operator >(SemVer o) => compareTo(o) > 0;
  bool operator <(SemVer o) => compareTo(o) < 0;
  bool operator >=(SemVer o) => compareTo(o) >= 0;
  bool operator <=(SemVer o) => compareTo(o) <= 0;

  @override
  bool operator ==(Object other) => other is SemVer && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease.join('.'));

  @override
  String toString() =>
      '$major.$minor.$patch${preRelease.isEmpty ? '' : '-${preRelease.join('.')}'}';
}

/// Returns true if [candidate] is a strictly newer version than [current].
/// Unparseable versions are never considered newer.
bool isNewerVersion(String? candidate, String current) {
  final a = SemVer.tryParse(candidate);
  final b = SemVer.tryParse(current);
  if (a == null || b == null) return false;
  return a > b;
}

/// Returns true if [current] is below [minVersion] (i.e. an update is mandatory).
bool isBelowMin(String current, String? minVersion) {
  final cur = SemVer.tryParse(current);
  final min = SemVer.tryParse(minVersion);
  if (cur == null || min == null) return false;
  return cur < min;
}
