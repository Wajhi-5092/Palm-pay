import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:uuid/uuid.dart';

/// Issues an opaque **hand ID** per enrollment and binds it to the Firebase account.
///
/// - [handId]: random UUID v4 — stable until the user replaces their palm scan.
/// - [bindingTag]: HMAC-SHA256 so the ID cannot be reassigned to another account without detection.
/// - [encryptedEnvelope]: AES-256-CBC payload sealing `handId|uid` for storage (not reversible without uid-derived key).
class PalmHandIdCredentials {
  PalmHandIdCredentials({
    required this.handId,
    required this.bindingTag,
    required this.encryptedEnvelope,
    required this.ivBase64,
  });

  final String handId;
  final String bindingTag;
  final String encryptedEnvelope;
  final String ivBase64;
}

/// Cryptographic helpers for palm enrollment IDs linked to user accounts.
class PalmHandIdService {
  PalmHandIdService._();

  static const _uuid = Uuid();

  static enc.Key _deriveKey(String accountUid) {
    final digest = sha256.convert(utf8.encode('paypalm.hand.aes.v1|$accountUid'));
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// One opaque ID per palm enrollment (regenerate when user replaces palm scan).
  static String generateHandId() => _uuid.v4();

  /// Binds [handId] to [accountUid] (anti‑swap integrity).
  static String computeBindingTag({
    required String handId,
    required String accountUid,
  }) {
    final key = utf8.encode('paypalm.hand.hmac.v1|$accountUid');
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(handId)).toString();
  }

  /// Creates encrypted envelope + binding for Firestore.
  static PalmHandIdCredentials issueForAccount({
    required String accountUid,
    required String biometricHash,
  }) {
    final handId = generateHandId();
    final bindingTag = computeBindingTag(handId: handId, accountUid: accountUid);

    final plaintext = '$handId|$accountUid|$biometricHash';
    final key = _deriveKey(accountUid);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return PalmHandIdCredentials(
      handId: handId,
      bindingTag: bindingTag,
      encryptedEnvelope: encrypted.base64,
      ivBase64: iv.base64,
    );
  }

  /// Display-safe masked token (e.g. `ABCD••••wxyz`).
  static String maskHandId(String handId) {
    final t = handId.trim();
    if (t.length <= 8) return '••••';
    return '${t.substring(0, 4)}••••${t.substring(t.length - 4)}';
  }
}
