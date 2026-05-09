/**
 * PayPalm Palm API — Google Cloud Run
 *
 * Env (Secret Manager → PALM_MASTER_KEY mapped to env var PALM_MASTER_KEY):
 *   PALM_MASTER_KEY   — AES key material (same as Firebase Functions migration)
 *
 * Firebase Admin uses Application Default Credentials on Cloud Run (service account).
 *
 * Deploy (example):
 *   gcloud run deploy paypalm-palm-api --source . --region us-central1 \
 *     --set-secrets PALM_MASTER_KEY=PALM_MASTER_KEY:latest \
 *     --service-account YOUR_RUNTIME_SA@...iam.gserviceaccount.com
 *
 * Flutter:
 *   --dart-define=PALM_API_BASE_URL=https://YOUR_SERVICE.run.app
 */

const express = require("express");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

const ALGO = "aes-256-gcm";
const IV_LEN = 12;
const AUTH_TAG_LEN = 16;
const DEFAULT_THRESHOLD = 0.95;

class ApiError extends Error {
  constructor(code, message, httpStatus = 400) {
    super(message);
    this.code = code;
    this.httpStatus = httpStatus;
  }
}

function masterKeyMaterial() {
  const raw = process.env.PALM_MASTER_KEY;
  if (!raw || String(raw).trim().length === 0) {
    throw new ApiError(
      "failed-precondition",
      "PALM_MASTER_KEY is not set (mount Secret Manager as env on Cloud Run).",
      412
    );
  }
  return raw;
}

function masterKeyBytesFromMaterial(raw) {
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

async function assertMerchant(uid) {
  const doc = await admin.firestore().collection("merchants").doc(uid).get();
  if (!doc.exists) {
    throw new ApiError(
      "permission-denied",
      "Merchant profile required for this action.",
      403
    );
  }
  return doc;
}

const app = express();
app.disable("x-powered-by");
app.use(express.json({ limit: "4mb" }));

app.use((req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
  if (req.method === "OPTIONS") return res.sendStatus(204);
  next();
});

async function requireAuth(req, res, next) {
  const h = req.headers.authorization || "";
  const m = h.match(/^Bearer\s+(.+)$/i);
  if (!m) {
    return res.status(401).json({
      code: "unauthenticated",
      message: "Missing Authorization: Bearer <Firebase ID token>.",
    });
  }
  try {
    const decoded = await admin.auth().verifyIdToken(m[1]);
    req.uid = decoded.uid;
    next();
  } catch (e) {
    return res.status(401).json({
      code: "unauthenticated",
      message: "Invalid or expired Firebase ID token.",
    });
  }
}

function handleError(err, res) {
  if (err instanceof ApiError) {
    return res.status(err.httpStatus).json({
      code: err.code,
      message: err.message,
    });
  }
  console.error(err);
  return res.status(500).json({
    code: "internal",
    message: err.message || "Internal error",
  });
}

app.get("/health", (_req, res) => {
  res.status(200).json({ ok: true, service: "paypalm-palm-api" });
});

app.post("/v1/registerPalmTemplate", requireAuth, async (req, res) => {
  try {
    const uid = req.uid;
    const data = req.body || {};
    const embedding = data.embedding;
    if (!Array.isArray(embedding) || embedding.length < 32) {
      throw new ApiError("invalid-argument", "Invalid embedding payload.", 400);
    }

    const biometricHash =
      typeof data.biometricHash === "string" ? data.biometricHash : "";
    const deviceInfo =
      data.deviceInfo && typeof data.deviceInfo === "object"
        ? data.deviceInfo
        : {};

    const keyMaterial = masterKeyMaterial();
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

    res.json({ ok: true });
  } catch (e) {
    handleError(e, res);
  }
});

app.post("/v1/verifyOwnPalm", requireAuth, async (req, res) => {
  try {
    const uid = req.uid;
    const data = req.body || {};
    const probe = data.embedding;
    if (!Array.isArray(probe) || probe.length < 32) {
      throw new ApiError("invalid-argument", "Invalid embedding payload.", 400);
    }

    const threshold =
      typeof data.threshold === "number" ? data.threshold : DEFAULT_THRESHOLD;
    const doc = await admin.firestore().collection("users").doc(uid).get();
    const pb = doc.data() && doc.data().palmBiometric;
    if (!pb || !pb.embeddingVector) {
      return res.json({
        matched: false,
        message: "No palm template registered.",
      });
    }

    const keyMaterial = masterKeyMaterial();
    let refVec;
    try {
      refVec = decryptFloatVector(
        pb.embeddingVector,
        pb.iv,
        pb.authTag,
        keyMaterial
      );
    } catch (e) {
      throw new ApiError("internal", "Template decrypt failed.", 500);
    }

    const sim = cosineSimilarity(probe, refVec);
    if (sim < threshold) {
      return res.json({
        matched: false,
        confidence: Math.round(sim * 1000) / 10,
      });
    }

    await admin.firestore().collection("users").doc(uid).update({
      "palmBiometric.lastVerified": admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({
      matched: true,
      confidence: Math.round(sim * 1000) / 10,
      message: "Palm verified.",
    });
  } catch (e) {
    handleError(e, res);
  }
});

app.post("/v1/matchPalmTemplate", requireAuth, async (req, res) => {
  try {
    const merchantUid = req.uid;
    await assertMerchant(merchantUid);

    const data = req.body || {};
    const probe = data.embedding;
    if (!Array.isArray(probe) || probe.length < 32) {
      throw new ApiError("invalid-argument", "Invalid embedding payload.", 400);
    }

    const threshold =
      typeof data.threshold === "number" ? data.threshold : DEFAULT_THRESHOLD;
    const keyMaterial = masterKeyMaterial();

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
      } catch (_) {}
    }

    if (best.id == null || best.sim < threshold) {
      return res.json({ matched: false, message: "Palm Not Recognized" });
    }

    const name =
      best.data.name ||
      best.data.fullName ||
      best.data.displayName ||
      "Customer";

    res.json({
      matched: true,
      userId: best.id,
      confidence: Math.round(best.sim * 1000) / 10,
      displayName: name,
      walletBalance: Number(best.data.walletBalance || 0),
      profileImageUrl: best.data.profileImageUrl || null,
    });
  } catch (e) {
    handleError(e, res);
  }
});

app.post("/v1/processPalmSale", requireAuth, async (req, res) => {
  try {
    const merchantUid = req.uid;
    const mSnap = await assertMerchant(merchantUid);

    const data = req.body || {};
    const amount = Number(data.amount);
    if (!Number.isFinite(amount) || amount <= 0) {
      throw new ApiError("invalid-argument", "Invalid payment amount.", 400);
    }

    const probe = data.embedding;
    if (!Array.isArray(probe) || probe.length < 32) {
      throw new ApiError("invalid-argument", "Invalid embedding payload.", 400);
    }

    const clientRequestId =
      typeof data.clientRequestId === "string" ? data.clientRequestId : null;
    const threshold =
      typeof data.threshold === "number" ? data.threshold : DEFAULT_THRESHOLD;

    const keyMaterial = masterKeyMaterial();
    const db = admin.firestore();

    if (clientRequestId) {
      const idem = await db
        .collection("palmSaleRequests")
        .doc(clientRequestId)
        .get();
      if (idem.exists && idem.data().status === "completed") {
        return res.json(idem.data().resultPayload);
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
      return res.json({ matched: false, message: "Palm Not Recognized" });
    }

    const userId = best.id;
    const userName =
      best.data.name ||
      best.data.fullName ||
      best.data.displayName ||
      "Customer";
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
          description: "Payment via Palm Biometrics (Cloud Run)",
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
      throw new ApiError("failed-precondition", msg, 412);
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

    res.json(result);
  } catch (e) {
    handleError(e, res);
  }
});

app.post("/v1/verifyPalm", requireAuth, async (_req, res) => {
  try {
    masterKeyMaterial();
    res.json({ success: true });
  } catch (e) {
    handleError(e, res);
  }
});

const port = Number(process.env.PORT) || 8080;
app.listen(port, () => {
  console.log(`paypalm-palm-api listening on ${port}`);
});
