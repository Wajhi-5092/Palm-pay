/**
 * Palm biometric API primary deployment: **cloud-run/palm-api** (HTTPS + Bearer token).
 * Deploy Firebase Functions only if you intentionally duplicate these endpoints.
 *
 * ---
 * PayPalm — Palm biometric Cloud Functions (v2 + Secret Manager).
 *
 * No functions.config() — use Secret Manager only:
 *   firebase functions:secrets:set PALM_MASTER_KEY
 *
 * Deploy:
 *   firebase deploy --only functions
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

const ALGO = "aes-256-gcm";
const IV_LEN = 12;
const AUTH_TAG_LEN = 16;
const DEFAULT_THRESHOLD = 0.95;

const PALM_MASTER_KEY_SECRET = defineSecret("PALM_MASTER_KEY");

const palmCallable = {
  secrets: [PALM_MASTER_KEY_SECRET],
  region: "us-central1",
};

function masterKeyBytesFromMaterial(raw) {
  if (!raw || String(raw).trim().length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "PALM_MASTER_KEY secret is not set. Run: firebase functions:secrets:set PALM_MASTER_KEY"
    );
  }
  return crypto.createHash("sha256").update(String(raw), "utf8").digest();
}

function encryptFloatVector(embedding, keyMaterial) {
  const key = masterKeyBytesFromMaterial(keyMaterial);
  const iv = crypto.randomBytes(IV_LEN);
  const cipher = crypto.createCipheriv(ALGO, key, iv, {
    authTagLength: AUTH_TAG_LEN,
  });
  const plain = Buffer.from(new Float32Array(embedding).buffer);
  const enc = Buffer.concat([cipher.update(plain), cipher.final()]);
  const tag = cipher.getAuthTag();
  return {
    ciphertext: enc.toString("base64"),
    iv: iv.toString("base64"),
    authTag: tag.toString("base64"),
  };
}

function decryptFloatVector(ciphertextB64, ivB64, tagB64, keyMaterial) {
  const key = masterKeyBytesFromMaterial(keyMaterial);
  const iv = Buffer.from(ivB64, "base64");
  const tag = Buffer.from(tagB64, "base64");
  const decipher = crypto.createDecipheriv(ALGO, key, iv, {
    authTagLength: AUTH_TAG_LEN,
  });
  decipher.setAuthTag(tag);
  const dec = Buffer.concat([
    decipher.update(Buffer.from(ciphertextB64, "base64")),
    decipher.final(),
  ]);
  return new Float32Array(dec.buffer, dec.byteOffset, dec.length / 4);
}

function cosineSimilarity(a, b) {
  const n = Math.min(a.length, b.length);
  let dot = 0;
  let na = 0;
  let nb = 0;
  for (let i = 0; i < n; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  const denom = Math.sqrt(na) * Math.sqrt(nb) + 1e-10;
  return dot / denom;
}

function assertAuthed(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  return request.auth.uid;
}

async function assertMerchant(uid) {
  const doc = await admin.firestore().collection("merchants").doc(uid).get();
  if (!doc.exists) {
    throw new HttpsError(
      "permission-denied",
      "Merchant profile required for this action."
    );
  }
  return doc;
}

exports.registerPalmTemplate = onCall(palmCallable, async (request) => {
  const uid = assertAuthed(request);
  const data = request.data || {};
  const embedding = data.embedding;
  if (!Array.isArray(embedding) || embedding.length < 32) {
    throw new HttpsError("invalid-argument", "Invalid embedding payload.");
  }

  const biometricHash =
    typeof data.biometricHash === "string" ? data.biometricHash : "";
  const deviceInfo =
    data.deviceInfo && typeof data.deviceInfo === "object"
      ? data.deviceInfo
      : {};

  const keyMaterial = PALM_MASTER_KEY_SECRET.value();
  const enc = encryptFloatVector(embedding, keyMaterial);
  const ref = admin.firestore().collection("users").doc(uid);

  await ref.set(
    {
      palmBiometric: {
        biometricHash,
        embeddingVector: enc.ciphertext,
        iv: enc.iv,
        authTag: enc.authTag,
        algorithm: "aes-256-gcm-v1",
        dim: embedding.length,
        registeredAt: admin.firestore.FieldValue.serverTimestamp(),
        lastVerified: null,
        deviceInfo,
      },
      palmRegistered: true,
    },
    { merge: true }
  );

  await admin.firestore().collection("palmAuditLogs").add({
    type: "register",
    userId: uid,
    at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true };
});

exports.verifyOwnPalm = onCall(palmCallable, async (request) => {
  const uid = assertAuthed(request);
  const data = request.data || {};
  const probe = data.embedding;
  if (!Array.isArray(probe) || probe.length < 32) {
    throw new HttpsError("invalid-argument", "Invalid embedding payload.");
  }

  const threshold =
    typeof data.threshold === "number" ? data.threshold : DEFAULT_THRESHOLD;
  const doc = await admin.firestore().collection("users").doc(uid).get();
  const pb = doc.data() && doc.data().palmBiometric;
  if (!pb || !pb.embeddingVector) {
    return { matched: false, message: "No palm template registered." };
  }

  const keyMaterial = PALM_MASTER_KEY_SECRET.value();
  let refVec;
  try {
    refVec = decryptFloatVector(pb.embeddingVector, pb.iv, pb.authTag, keyMaterial);
  } catch (e) {
    throw new HttpsError("internal", "Template decrypt failed.");
  }

  const sim = cosineSimilarity(probe, refVec);
  if (sim < threshold) {
    return { matched: false, confidence: Math.round(sim * 1000) / 10 };
  }

  await admin.firestore().collection("users").doc(uid).update({
    "palmBiometric.lastVerified": admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    matched: true,
    confidence: Math.round(sim * 1000) / 10,
    message: "Palm verified.",
  };
});

exports.matchPalmTemplate = onCall(palmCallable, async (request) => {
  const merchantUid = assertAuthed(request);
  await assertMerchant(merchantUid);

  const data = request.data || {};
  const probe = data.embedding;
  if (!Array.isArray(probe) || probe.length < 32) {
    throw new HttpsError("invalid-argument", "Invalid embedding payload.");
  }

  const threshold =
    typeof data.threshold === "number" ? data.threshold : DEFAULT_THRESHOLD;
  const keyMaterial = PALM_MASTER_KEY_SECRET.value();

  const snap = await admin
    .firestore()
    .collection("users")
    .where("palmRegistered", "==", true)
    .get();

  let best = { id: null, sim: -1, data: null };

  for (const doc of snap.docs) {
    const row = doc.data();
    const pb = row.palmBiometric;
    if (!pb || !pb.embeddingVector) continue;
    try {
      const refVec = decryptFloatVector(
        pb.embeddingVector,
        pb.iv,
        pb.authTag,
        keyMaterial
      );
      const sim = cosineSimilarity(probe, refVec);
      if (sim > best.sim) {
        best = { id: doc.id, sim, data: row };
      }
    } catch (_) {
      /* skip corrupted */
    }
  }

  if (best.id == null || best.sim < threshold) {
    return { matched: false, message: "Palm Not Recognized" };
  }

  const name =
    best.data.name || best.data.fullName || best.data.displayName || "Customer";

  return {
    matched: true,
    userId: best.id,
    confidence: Math.round(best.sim * 1000) / 10,
    displayName: name,
    walletBalance: Number(best.data.walletBalance || 0),
    profileImageUrl: best.data.profileImageUrl || null,
  };
});

exports.processPalmSale = onCall(palmCallable, async (request) => {
  const merchantUid = assertAuthed(request);
  const mSnap = await assertMerchant(merchantUid);

  const data = request.data || {};
  const amount = Number(data.amount);
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new HttpsError("invalid-argument", "Invalid payment amount.");
  }

  const probe = data.embedding;
  if (!Array.isArray(probe) || probe.length < 32) {
    throw new HttpsError("invalid-argument", "Invalid embedding payload.");
  }

  const clientRequestId =
    typeof data.clientRequestId === "string" ? data.clientRequestId : null;
  const threshold =
    typeof data.threshold === "number" ? data.threshold : DEFAULT_THRESHOLD;

  const keyMaterial = PALM_MASTER_KEY_SECRET.value();
  const db = admin.firestore();

  if (clientRequestId) {
    const idem = await db.collection("palmSaleRequests").doc(clientRequestId).get();
    if (idem.exists && idem.data().status === "completed") {
      return idem.data().resultPayload;
    }
  }

  const usersSnap = await db
    .collection("users")
    .where("palmRegistered", "==", true)
    .get();

  let best = { id: null, sim: -1, data: null };
  for (const doc of usersSnap.docs) {
    const row = doc.data();
    const pb = row.palmBiometric;
    if (!pb || !pb.embeddingVector) continue;
    try {
      const refVec = decryptFloatVector(
        pb.embeddingVector,
        pb.iv,
        pb.authTag,
        keyMaterial
      );
      const sim = cosineSimilarity(probe, refVec);
      if (sim > best.sim) {
        best = { id: doc.id, sim, data: row };
      }
    } catch (_) {}
  }

  if (best.id == null || best.sim < threshold) {
    return { matched: false, message: "Palm Not Recognized" };
  }

  const userId = best.id;
  const userName =
    best.data.name || best.data.fullName || best.data.displayName || "Customer";
  const merchantData = mSnap.data();
  const storeName = merchantData.storeName || "Merchant";

  let result;
  try {
    result = await db.runTransaction(async (tx) => {
      const userRef = db.collection("users").doc(userId);
      const merchantRef = db.collection("merchants").doc(merchantUid);
      const txRef = db.collection("transactions").doc();

      const userDoc = await tx.get(userRef);
      const merchantDoc = await tx.get(merchantRef);
      if (!userDoc.exists) throw new Error("User not found");
      if (!merchantDoc.exists) throw new Error("Merchant not found");

      let userBalance = Number(userDoc.data().walletBalance || 0);
      let merchantBalance = Number(merchantDoc.data().walletBalance || 0);
      if (userBalance < amount) {
        throw new Error("Customer has insufficient balance.");
      }

      userBalance -= amount;
      merchantBalance += amount;

      tx.update(userRef, { walletBalance: userBalance });
      tx.update(merchantRef, { walletBalance: merchantBalance });

      tx.set(txRef, {
        id: txRef.id,
        merchantId: merchantUid,
        merchantName: storeName,
        userId,
        userName,
        amount,
        fee: 0,
        netAmount: amount,
        type: "sale",
        status: "completed",
        paymentMethod: "palm_scan",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        description: "Payment via Palm Biometrics (Cloud Function)",
      });

      return {
        matched: true,
        userId,
        displayName: userName,
        confidence: Math.round(best.sim * 1000) / 10,
        walletBalance: userBalance,
        transactionId: txRef.id,
        message: `Charged PKR ${amount.toFixed(2)} to ${userName}.`,
      };
    });
  } catch (e) {
    const msg = e && e.message ? String(e.message) : "Transaction failed.";
    throw new HttpsError("failed-precondition", msg);
  }

  if (clientRequestId) {
    await db
      .collection("palmSaleRequests")
      .doc(clientRequestId)
      .set({
        status: "completed",
        merchantId: merchantUid,
        userId,
        amount,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        resultPayload: result,
      });
  }

  await db.collection("palmAuditLogs").add({
    type: "sale",
    merchantId: merchantUid,
    userId,
    amount,
    at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return result;
});

/** Smoke-test that Secret Manager key is mounted (same secret as crypto above). */
exports.verifyPalm = onCall(palmCallable, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const raw = PALM_MASTER_KEY_SECRET.value();
  if (!raw || String(raw).trim().length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "PALM_MASTER_KEY secret is empty or missing."
    );
  }

  return { success: true };
});

/** Palm pay using client [palmLookup] embedding: re-verifies probe server-side, one atomic transfer. */
const paymentOnlyCallable = { region: "us-central1" };

exports.finalizePalmPayment = onCall(paymentOnlyCallable, async (request) => {
  const merchantUid = assertAuthed(request);
  const mSnap = await assertMerchant(merchantUid);

  const data = request.data || {};
  const customerUid =
    typeof data.customerUid === "string" ? data.customerUid.trim() : "";
  const amount = Number(data.amount);
  const probe = data.embedding;
  const threshold =
    typeof data.threshold === "number" ? data.threshold : 0.85;
  const handId =
    typeof data.handId === "string" ? data.handId.trim() : null;
  const clientRequestId =
    typeof data.clientRequestId === "string"
      ? data.clientRequestId.trim()
      : null;
  const checkoutSessionId =
    typeof data.checkoutSessionId === "string"
      ? data.checkoutSessionId.trim()
      : "";

  if (!customerUid) {
    throw new HttpsError(
      "invalid-argument",
      "Customer reference missing."
    );
  }
  if (merchantUid === customerUid) {
    throw new HttpsError(
      "invalid-argument",
      "Cannot charge your own account."
    );
  }
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new HttpsError("invalid-argument", "Invalid payment amount.");
  }
  if (!Array.isArray(probe) || probe.length < 8) {
    throw new HttpsError("invalid-argument", "Invalid palm embedding.");
  }

  const db = admin.firestore();

  if (clientRequestId) {
    const idem = await db
      .collection("palmPaymentIntents")
      .doc(clientRequestId)
      .get();
    if (idem.exists && idem.data().status === "completed") {
      return idem.data().resultPayload;
    }
  }

  const lookupSnap = await db.collection("palmLookup").doc(customerUid).get();
  if (!lookupSnap.exists) {
    throw new HttpsError(
      "not-found",
      "Customer palm is not enrolled."
    );
  }
  const lookup = lookupSnap.data();
  if (handId && lookup.handId && lookup.handId !== handId) {
    throw new HttpsError(
      "permission-denied",
      "Hand ID does not match this customer."
    );
  }
  const refEmb = lookup.embedding;
  if (!Array.isArray(refEmb) || refEmb.length !== probe.length) {
    throw new HttpsError(
      "failed-precondition",
      "Palm template length mismatch."
    );
  }
  const refArr = refEmb.map((x) => Number(x));
  const probeArr = probe.map((x) => Number(x));
  const sim = cosineSimilarity(probeArr, refArr);
  if (sim < threshold) {
    throw new HttpsError(
      "failed-precondition",
      "Palm verification failed. Ask the customer to scan again."
    );
  }

  const userSnap = await db.collection("users").doc(customerUid).get();
  if (!userSnap.exists) {
    throw new HttpsError("not-found", "Customer account not found.");
  }
  const userRow = userSnap.data();
  const displayName =
    userRow.name || userRow.fullName || lookup.displayName || "Customer";
  const merchantData = mSnap.data();
  const storeName = merchantData.storeName || "Merchant";

  let result;
  const duplicateCheckoutMsg =
    "Your hand scan has already been completed for this ID; you cannot scan again on this ID.";

  try {
    result = await db.runTransaction(async (tx) => {
      const userRef = db.collection("users").doc(customerUid);
      const merchantRef = db.collection("merchants").doc(merchantUid);
      const txRef = db.collection("transactions").doc();

      let completionRef = null;
      if (checkoutSessionId.length > 0) {
        completionRef = db
          .collection("merchants")
          .doc(merchantUid)
          .collection("palmCheckoutSessions")
          .doc(checkoutSessionId)
          .collection("completedCustomerIds")
          .doc(customerUid);
        const compSnap = await tx.get(completionRef);
        if (compSnap.exists) {
          throw new Error(duplicateCheckoutMsg);
        }
      }

      const userDoc = await tx.get(userRef);
      const merchantDoc = await tx.get(merchantRef);
      if (!userDoc.exists) throw new Error("User not found");
      if (!merchantDoc.exists) throw new Error("Merchant not found");

      let userBalance = Number(userDoc.data().walletBalance || 0);
      let merchantBalance = Number(merchantDoc.data().walletBalance || 0);
      if (userBalance < amount) {
        throw new Error("Customer has insufficient wallet balance.");
      }

      userBalance -= amount;
      merchantBalance += amount;

      tx.update(userRef, { walletBalance: userBalance });
      tx.update(merchantRef, { walletBalance: merchantBalance });

      tx.set(txRef, {
        id: txRef.id,
        merchantId: merchantUid,
        merchantName: storeName,
        userId: customerUid,
        userName: displayName,
        amount,
        fee: 0,
        netAmount: amount,
        type: "palm_sale",
        status: "completed",
        paymentMethod: "palm_lookup_verify",
        final: true,
        irreversible: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        description: "Palm payment (finalizePalmPayment)",
        ...(checkoutSessionId.length > 0 ? { checkoutSessionId } : {}),
      });

      if (completionRef) {
        tx.set(completionRef, {
          customerUid,
          checkoutSessionId,
          transactionId: txRef.id,
          amount,
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return {
        success: true,
        userId: customerUid,
        displayName,
        confidence: Math.round(sim * 1000) / 10,
        walletBalance: userBalance,
        merchantWalletBalance: merchantBalance,
        transactionId: txRef.id,
        amount,
        message: `Charged PKR ${amount.toFixed(2)} to ${displayName}.`,
      };
    });
  } catch (e) {
    const msg = e && e.message ? String(e.message) : "Transaction failed.";
    throw new HttpsError("failed-precondition", msg);
  }

  if (clientRequestId) {
    await db.collection("palmPaymentIntents").doc(clientRequestId).set({
      status: "completed",
      merchantId: merchantUid,
      customerUid,
      amount,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      resultPayload: result,
    });
  }

  return result;
});

// --- Account lifecycle: keep Firebase Auth and Firestore profiles in sync ---
const functionsV1 = require("firebase-functions/v1");
const { onDocumentDeleted } = require("firebase-functions/v2/firestore");

/** When `users/{uid}` is deleted (Console or app), remove the Auth user so login fails. */
exports.deleteAuthWhenUserProfileDeleted = onDocumentDeleted(
  "users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    try {
      await admin.auth().deleteUser(uid);
    } catch (e) {
      if (e.code !== "auth/user-not-found") {
        console.error("deleteAuthWhenUserProfileDeleted", uid, e);
      }
    }
  }
);

/** When an Auth user is deleted, remove consumer Firestore profile + palm index (Admin SDK). */
exports.deleteUserDataWhenAuthRemoved = functionsV1.auth
  .user()
  .onDelete(async (user) => {
    const uid = user.uid;
    const db = admin.firestore();
    await db.collection("users").doc(uid).delete().catch(() => {});
    await db.collection("palmLookup").doc(uid).delete().catch(() => {});
  });
