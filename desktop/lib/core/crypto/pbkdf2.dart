import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256 (RFC 8018), compatible with PHP
/// `hash_pbkdf2('sha256', $password, $salt, $iterations, $length, true)`.
Uint8List pbkdf2Sha256({
  required List<int> password,
  required List<int> salt,
  required int iterations,
  required int keyLength,
}) {
  if (iterations < 1) throw ArgumentError.value(iterations, 'iterations');
  if (keyLength < 1) throw ArgumentError.value(keyLength, 'keyLength');
  final hmac = Hmac(sha256, password);
  const hLen = 32;
  final blocks = (keyLength + hLen - 1) ~/ hLen;
  final out = BytesBuilder(copy: false);

  for (var block = 1; block <= blocks; block++) {
    final saltBlock = Uint8List(salt.length + 4)
      ..setAll(0, salt)
      ..[salt.length] = (block >> 24) & 0xff
      ..[salt.length + 1] = (block >> 16) & 0xff
      ..[salt.length + 2] = (block >> 8) & 0xff
      ..[salt.length + 3] = block & 0xff;
    var u = Uint8List.fromList(hmac.convert(saltBlock).bytes);
    final t = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < hLen; j++) {
        t[j] ^= u[j];
      }
    }
    out.add(t);
  }
  return Uint8List.sublistView(out.takeBytes(), 0, keyLength);
}

/// Verifies [password] against a hash in the format used by the server
/// setting `desktop_exit_password_offline`:
///
///     pbkdf2_sha256$<iterations>$<salt_b64>$<hash_b64>
///
/// The salt is the base64-decoded raw bytes; the key length is the length of
/// the decoded hash (32 for the server's 32-byte output).
bool verifyPbkdf2Password(String password, String? encoded) {
  if (encoded == null || encoded.isEmpty) return false;
  final parts = encoded.split(r'$');
  if (parts.length != 4 || parts[0] != 'pbkdf2_sha256') return false;
  final iterations = int.tryParse(parts[1]);
  if (iterations == null || iterations < 1 || iterations > 10000000) {
    return false;
  }
  final List<int> salt;
  final List<int> expected;
  try {
    salt = base64.decode(base64.normalize(parts[2]));
    expected = base64.decode(base64.normalize(parts[3]));
  } on FormatException {
    return false;
  }
  if (expected.isEmpty) return false;
  final actual = pbkdf2Sha256(
    password: utf8.encode(password),
    salt: salt,
    iterations: iterations,
    keyLength: expected.length,
  );
  return constantTimeEquals(actual, expected);
}

bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
