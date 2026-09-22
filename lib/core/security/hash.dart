import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;

class Hash {
  Hash._();

  static const int _iterations = 100000;
  static const int _keyLength = 32;
  static const int _saltLength = 16;

  // ─── Generate salt (secure random) ───
  static String generateSalt() {
    final rnd = Random.secure();
    final salt = List<int>.generate(_saltLength, (_) => rnd.nextInt(256));
    return base64Encode(salt);
  }

  // ─── PBKDF2-HMAC-SHA256 ───
  static String pbkdf2(String input, String saltB64) {
    final salt = base64Decode(saltB64);
    final hmac = crypto.Hmac(crypto.sha256, utf8.encode(input));
    var dk = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    var result = List<int>.from(dk);

    for (var i = 1; i < _iterations; i++) {
      dk = hmac.convert(dk).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= dk[j];
      }
    }
    return base64Encode(result.sublist(0, _keyLength));
  }

  // ─── Verify ───
  static bool verify(String input, String saltB64, String hashB64) {
    return pbkdf2(input, saltB64) == hashB64;
  }

  // ─── Legacy (backward-compatible) ───
  static const _legacySalt = 'pos_v2_static_salt_2026';
  static String sha256(String input) {
    final bytes = utf8.encode('$_legacySalt|$input');
    return crypto.sha256.convert(bytes).toString();
  }
}
