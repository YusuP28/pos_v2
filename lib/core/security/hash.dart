import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

class Hash {
  Hash._();

  static const _salt = 'pos_v2_static_salt_2026';

  static String sha256(String input) {
    final bytes = utf8.encode('$_salt|$input');
    return crypto.sha256.convert(bytes).toString();
  }
}
