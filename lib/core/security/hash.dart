import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;

/// Hasil hashing password: hash PBKDF2 beserta salt acak yang dipakai.
class HashedPassword {
  final String hash;
  final String salt;

  const HashedPassword({required this.hash, required this.salt});
}

/// Hasil pengecekan password terhadap data tersimpan.
enum PasswordCheck {
  /// Cocok dengan hash PBKDF2 (format sekarang).
  match,

  /// Cocok, tetapi masih hash SHA-256 lama → wajib di-hash ulang.
  matchLegacy,

  /// Tidak cocok.
  mismatch,
}

class Hash {
  Hash._();

  static const int _iterations = 100000;
  static const int _keyLength = 32;
  static const int _saltLength = 16;

  // ─── Generate salt (secure random, 16 byte) ───
  static String generateSalt() {
    final rnd = Random.secure();
    final salt = List<int>.generate(_saltLength, (_) => rnd.nextInt(256));
    return base64Encode(salt);
  }

  // ─── PBKDF2-HMAC-SHA256 (100.000 iterasi, key 32 byte) ───
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

  /// Hash password baru: PBKDF2 dengan salt acak per user.
  static HashedPassword hashPassword(String password) {
    final salt = generateSalt();
    return HashedPassword(hash: pbkdf2(password, salt), salt: salt);
  }

  /// Cek password terhadap hash + salt tersimpan.
  ///
  /// Mendukung dua format:
  /// - PBKDF2 + salt per user (format sekarang)
  /// - SHA-256 dengan salt statis (data lama sebelum migrasi)
  ///
  /// Kasus `matchLegacy` juga mencakup data yang sempat tersimpan sebagai
  /// SHA-256 namun salt-nya tertinggal, sehingga akun lama tetap bisa login
  /// dan langsung dimigrasi.
  static PasswordCheck checkPassword(
    String password, {
    required String hash,
    required String salt,
  }) {
    if (salt.isNotEmpty && verify(password, salt, hash)) {
      return PasswordCheck.match;
    }
    if (hash.isNotEmpty && hash == sha256(password)) {
      return PasswordCheck.matchLegacy;
    }
    return PasswordCheck.mismatch;
  }

  // ─── Legacy SHA-256 (salt statis) ───
  // HANYA untuk memverifikasi data lama & PIN perangkat (belum dimigrasi).
  // Jangan dipakai untuk menyimpan password baru.
  static const _legacySalt = 'pos_v2_static_salt_2026';
  static String sha256(String input) {
    final bytes = utf8.encode('$_legacySalt|$input');
    return crypto.sha256.convert(bytes).toString();
  }
}
