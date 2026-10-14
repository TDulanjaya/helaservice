const crypto = require('crypto');
const { admin, db } = require('./_firebase');
const { verifyApiKey, verifyFirebaseToken } = require('./_auth');

// clean nic string helper
function cleanNic(raw) {
  if (!raw) return '';
  const trimmed = String(raw).trim();
  if (!trimmed) return '';
  const last = trimmed[trimmed.length - 1];
  if (last === 'v' || last === 'x') {
    return trimmed.slice(0, -1) + last.toUpperCase();
  }
  return trimmed;
}

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-helaservice-key');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // verify api key
  if (!verifyApiKey(req, res)) {
    return;
  }

  // verify firebase auth token
  const decodedToken = await verifyFirebaseToken(req, res);
  if (!decodedToken) {
    return;
  }

  // check required salt from env
  const salt = (process.env.NIC_HASH_SALT || '').trim();
  if (!salt) {
    return res.status(500).json({ error: 'nic_hash_not_configured' });
  }

  const uid = decodedToken.uid;

  try {
    // read caller's own nic from private/kyc using admin sdk
    const kycDoc = await db
      .collection('technicians')
      .doc(uid)
      .collection('private')
      .doc('kyc')
      .get();

    if (!kycDoc.exists) {
      return res.status(404).json({ error: 'kyc_not_found' });
    }

    const kycData = kycDoc.data() || {};
    const rawNic = kycData.nic || kycData.nicNumber || '';
    const cleaned = cleanNic(rawNic);

    if (!cleaned) {
      return res.status(400).json({ error: 'nic_not_found' });
    }

    // compute sha256 hash using secret salt
    const nicHash = crypto
      .createHash('sha256')
      .update(`${cleaned}:${salt}`)
      .digest('hex');

    // write nicHash to verificationQueue/{uid} using admin sdk
    await db.collection('verificationQueue').doc(uid).set({
      nicHash,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // return success without exposing the hash
    return res.status(200).json({ ok: true });
  } catch (err) {
    console.error('[nic-hash error]', err);
    return res.status(500).json({ error: 'internal_error' });
  }
};
