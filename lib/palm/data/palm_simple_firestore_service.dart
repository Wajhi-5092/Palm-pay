import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paypalm/palm/data/palm_customer_match.dart';
import 'package:paypalm/palm/services/palm_cosine.dart';
import 'package:paypalm/palm/services/palm_embedding_service.dart';
import 'package:paypalm/palm/services/palm_hand_id_service.dart';

/// Direct Firestore palm scan (no Cloud Run). Types are JSON-safe for Web + Android.
class PalmSimpleFirestoreService {
  PalmSimpleFirestoreService._();

  /// Minimum cosine similarity to treat a palm as matching a registered customer.
  static const double merchantMatchThreshold = 0.85;

  static List<double> _safeEmbeddingList(Float32List f) {
    return List<double>.generate(f.length, (i) {
      final v = f[i];
      if (!v.isFinite) return 0.0;
      return v.toDouble();
    });
  }

  static Future<void> saveUserPalmScan({
    required Float32List embedding,
    required String biometricHash,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');

    final emb = _safeEmbeddingList(embedding);
    final hand = PalmHandIdService.issueForAccount(
      accountUid: uid,
      biometricHash: biometricHash,
    );

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'palmRegistered': true,
        'handId': hand.handId,
        'palmScan': {
          'biometricHash': biometricHash,
          'embedding': emb,
          'savedAt': FieldValue.serverTimestamp(),
          'dim': emb.length,
          'handId': hand.handId,
          'handBindingTag': hand.bindingTag,
          'handEncryptedEnvelope': hand.encryptedEnvelope,
          'handIvBase64': hand.ivBase64,
          'handEnvelopeAlgo': 'aes-256-cbc-v1',
        },
      },
      SetOptions(merge: true),
    );

    final profile =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final d = profile.data();
    final authUser = FirebaseAuth.instance.currentUser;
    final name = (d?['name'] as String?)?.trim();
    final displayName = (name != null && name.isNotEmpty)
        ? name
        : (authUser?.displayName?.trim().isNotEmpty == true
            ? authUser!.displayName!
            : 'Customer');

    await FirebaseFirestore.instance.collection('palmLookup').doc(uid).set(
      {
        'embedding': emb,
        'handId': hand.handId,
        'handBindingTag': hand.bindingTag,
        'displayName': displayName,
        'phone': d?['phone'] as String?,
        'email': d?['email'] as String?,
        'photoUrl': authUser?.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// True when this user already saved a palm scan (enrollment complete).
  static Future<bool> hasRegisteredPalm() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snap.data();
    if (data == null) return false;
    if (data['palmRegistered'] == true) return true;
    final scan = data['palmScan'];
    return scan is Map;
  }

  static Future<List<double>?> loadStoredEmbedding() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final scan = snap.data()?['palmScan'];
    if (scan is! Map) return null;
    final raw = scan['embedding'];
    if (raw is! List) return null;
    return raw.map((e) => (e as num).toDouble()).toList();
  }

  static Future<bool> verifyLocally({
    required Float32List probe,
    double threshold = 0.85,
  }) async {
    final ref = await loadStoredEmbedding();
    if (ref == null || ref.isEmpty) return false;
    final p = _safeEmbeddingList(probe);
    if (p.length != ref.length) return false;
    final sim = palmCosineSimilarity(p, ref);
    return sim >= threshold;
  }

  /// Finds the enrolled customer whose stored palm best matches [probe].
  /// Call from the merchant app (must be signed in as a merchant).
  static Future<PalmCustomerMatch?> findBestCustomerMatch(
    Float32List probe, {
    double threshold = merchantMatchThreshold,
    String? excludeUid,
  }) async {
    final p = _safeEmbeddingList(probe);
    final qs =
        await FirebaseFirestore.instance.collection('palmLookup').get();

    PalmCustomerMatch? best;
    var bestSim = threshold;

    for (final doc in qs.docs) {
      if (excludeUid != null && doc.id == excludeUid) continue;
      final data = doc.data();
      final raw = data['embedding'];
      if (raw is! List) continue;
      final ref = raw.map((e) => (e as num).toDouble()).toList();
      if (ref.length != p.length) continue;
      final sim = palmCosineSimilarity(p, ref);
      if (sim > bestSim) {
        bestSim = sim;
        final dn = (data['displayName'] as String?)?.trim();
        best = PalmCustomerMatch(
          uid: doc.id,
          displayName:
              (dn != null && dn.isNotEmpty) ? dn : 'Customer',
          phone: data['phone'] as String?,
          email: data['email'] as String?,
          photoUrl: data['photoUrl'] as String?,
          similarity: sim,
          handId: data['handId'] as String?,
        );
      }
    }
    return best;
  }

  /// Demo merchant log (no wallet movement). Returns new document id when created.
  static Future<String> saveMerchantDemoScan({
    required double amount,
    required Float32List embedding,
    String? customerUid,
    String? customerDisplayName,
    double? matchSimilarity,
    String? customerHandId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');

    final hash = PalmEmbeddingService.biometricHash(embedding);
    final emb = _safeEmbeddingList(embedding);

    final doc =
        await FirebaseFirestore.instance.collection('palmMerchantDemo').add({
      'merchantId': uid,
      'amount': amount,
      'biometricHash': hash,
      'embeddingDim': emb.length,
      'createdAt': FieldValue.serverTimestamp(),
      if (customerUid != null) 'customerUid': customerUid,
      if (customerDisplayName != null) 'customerDisplayName': customerDisplayName,
      if (matchSimilarity != null) 'matchSimilarity': matchSimilarity,
      if (customerHandId != null) 'customerHandId': customerHandId,
    });
    return doc.id;
  }
}
