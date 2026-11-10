/// Port of the web `buildRange(from, to)`: numbers, single letters, roman
/// numerals or a comma-separated list (from == to).
List<String> buildRange(String? fromRaw, String? toRaw) {
  if (fromRaw == null || toRaw == null) return const [];
  final from = fromRaw.trim();
  final to = toRaw.trim();
  if (from.isEmpty || to.isEmpty) return const [];

  final numRe = RegExp(r'^\d+$');
  if (numRe.hasMatch(from) && numRe.hasMatch(to)) {
    return _span(int.parse(from), int.parse(to)).map((n) => '$n').toList();
  }
  final letterRe = RegExp(r'^[A-Za-z]$');
  if (letterRe.hasMatch(from) && letterRe.hasMatch(to)) {
    return _span(from.toUpperCase().codeUnitAt(0), to.toUpperCase().codeUnitAt(0))
        .map(String.fromCharCode)
        .toList();
  }
  final romanRe = RegExp(r'^[ivxlcdm]+$', caseSensitive: false);
  if (romanRe.hasMatch(from) && romanRe.hasMatch(to)) {
    final a = romanToInt(from);
    final b = romanToInt(to);
    if (a <= 0 || b <= 0) return const [];
    return _span(a, b).map(intToRoman).toList();
  }
  if (from.contains(',') && from == to) {
    return from.split(',').map((s) => s.trim().toUpperCase()).where((s) => s.isNotEmpty).toList();
  }
  return const [];
}

Iterable<int> _span(int a, int b) sync* {
  final step = a <= b ? 1 : -1;
  for (var i = a; step > 0 ? i <= b : i >= b; i += step) {
    yield i;
  }
}

int romanToInt(String roman) {
  const map = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000};
  final s = roman.toUpperCase();
  var result = 0;
  var prev = 0;
  for (var i = s.length - 1; i >= 0; i--) {
    final cur = map[s[i]] ?? 0;
    if (cur < prev) {
      result -= cur;
    } else {
      result += cur;
    }
    prev = cur;
  }
  return result;
}

String intToRoman(int num) {
  const table = [
    (1000, 'M'), (900, 'CM'), (500, 'D'), (400, 'CD'), (100, 'C'), (90, 'XC'),
    (50, 'L'), (40, 'XL'), (10, 'X'), (9, 'IX'), (5, 'V'), (4, 'IV'), (1, 'I'),
  ];
  var n = num;
  final b = StringBuffer();
  for (final (v, s) in table) {
    while (n >= v) {
      b.write(s);
      n -= v;
    }
  }
  return b.toString();
}
