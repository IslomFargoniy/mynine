import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/core/api/trusted_roots.dart';

void main() {
  test('the bundled Let\'s Encrypt roots are valid PEM certificates', () {
    for (final pem in bundledRootPems) {
      // Throws TlsException on a malformed certificate.
      SecurityContext(withTrustedRoots: false).setTrustedCertificatesBytes(utf8.encode(pem));
    }
    expect(bundledRootPems, hasLength(2));
  });

  test('HttpClients get the bundled roots', () {
    expect(() => trustedSecurityContext(), returnsNormally);
    final client = HttpOverrides.runWithHttpOverrides(() => HttpClient(), TrustedRootsHttpOverrides());
    client.close();
  });
}
