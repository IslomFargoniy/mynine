import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/core/crypto/pbkdf2.dart';

String hex(List<int> b) => b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('pbkdf2Sha256', () {
    // RFC 7914 §11 test vectors for PBKDF2-HMAC-SHA256.
    test('RFC 7914 vector 1 (c=1)', () {
      final out = pbkdf2Sha256(
        password: utf8.encode('passwd'),
        salt: utf8.encode('salt'),
        iterations: 1,
        keyLength: 64,
      );
      expect(
        hex(out),
        '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc'
        '49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783',
      );
    });

    test('RFC 7914 vector 2 (c=80000)', () {
      final out = pbkdf2Sha256(
        password: utf8.encode('Password'),
        salt: utf8.encode('NaCl'),
        iterations: 80000,
        keyLength: 64,
      );
      expect(
        hex(out),
        '4ddcd8f60b98be21830cee5ef22701f9641a4418d04c0414aeff08876b34ab56'
        'a1d425a1225833549adb841b51c9b3176a272bdebba1d078478f62b397f33c8d',
      );
    });

    // Known vector produced with PHP 8 on the dev machine:
    //   php -r 'echo base64_encode(hash_pbkdf2("sha256", "Mynine#2026",
    //            base64_decode("bXluaW5lLXNhbHQtMTY="), 120000, 32, true));'
    //   => HqHkSiYgWxTyj4vGEd32QBl0Q5fTXr4PprrLF0tcwdI=
    // (salt "bXluaW5lLXNhbHQtMTY=" is base64 of the ASCII bytes "mynine-salt-16")
    const phpHash =
        r'pbkdf2_sha256$120000$bXluaW5lLXNhbHQtMTY=$HqHkSiYgWxTyj4vGEd32QBl0Q5fTXr4PprrLF0tcwdI=';

    test('matches PHP hash_pbkdf2 output (120000 iterations, 32 bytes)', () {
      final out = pbkdf2Sha256(
        password: utf8.encode('Mynine#2026'),
        salt: base64.decode('bXluaW5lLXNhbHQtMTY='),
        iterations: 120000,
        keyLength: 32,
      );
      expect(base64.encode(out), 'HqHkSiYgWxTyj4vGEd32QBl0Q5fTXr4PprrLF0tcwdI=');
    });

    test('verifyPbkdf2Password accepts the right password only', () {
      expect(verifyPbkdf2Password('Mynine#2026', phpHash), isTrue);
      expect(verifyPbkdf2Password('mynine#2026', phpHash), isFalse);
      expect(verifyPbkdf2Password('', phpHash), isFalse);
    });

    test('verifyPbkdf2Password rejects malformed hashes', () {
      expect(verifyPbkdf2Password('x', null), isFalse);
      expect(verifyPbkdf2Password('x', 'bcrypt\$1\$a\$b'), isFalse);
      expect(verifyPbkdf2Password('x', r'pbkdf2_sha256$abc$AAAA$AAAA'), isFalse);
      expect(verifyPbkdf2Password('x', r'pbkdf2_sha256$10$###$AAAA'), isFalse);
    });
  });
}
