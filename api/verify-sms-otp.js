const crypto = require('crypto');
const { admin, db } = require('./_firebase');
const { verifyApiKey } = require('./_auth');

// normalize sl phone number to 94 format
function normalizeSriLankanPhone(phone) {
  let clean = phone.replace(/[^0-9]/g, '');
  if (clean.startsWith('0')) {
    clean = '94' + clean.substring(1);
  } else if (!clean.startsWith('94') && clean.length === 9) {
    clean = '94' + clean;
  }
  return clean;
}

module.exports = async function handler(req, res) {
  // allow cross origin
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-helaservice-key');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  if (!verifyApiKey(req, res)) {
    return;
  }

  try {
    const { phone, otp } = req.body || {};

    if (!phone || typeof phone !== 'string') {
      return res.status(400).json({ error: 'Phone number is required.' });
    }

    if (!otp || typeof otp !== 'string' || otp.trim().length !== 6) {
      return res.status(400).json({ error: 'A 6-digit verification code is required.' });
    }

    const cleanPhone = normalizeSriLankanPhone(phone);
    const cleanOtp = otp.trim();
    const docRef = db.collection('otp_verifications').doc(cleanPhone);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      return res.status(400).json({
        error: 'No verification code was sent to this phone number, or it has expired.',
      });
    }

    const data = docSnap.data() || {};
    const now = Date.now();

    if (now > (data.expiresAt || 0)) {
      await docRef.delete();
      return res.status(400).json({
        error: 'Verification code has expired. Please request a new one.',
      });
    }

    const currentAttempts = data.attempts || 0;
    if (currentAttempts >= 5) {
      await docRef.delete();
      return res.status(400).json({
        error: 'Too many incorrect attempts. Please request a new verification code.',
      });
    }

    const hashedInput = crypto.createHash('sha256').update(cleanOtp).digest('hex');
    if (hashedInput !== data.otpHash) {
      await docRef.update({ attempts: currentAttempts + 1 });
      const remaining = 5 - (currentAttempts + 1);
      return res.status(400).json({
        error: `Incorrect verification code. ${remaining} attempt(s) remaining.`,
      });
    }

    // code is correct, delete otp record
    await docRef.delete();

    // create or find user by phone in firebase auth
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByPhoneNumber('+' + cleanPhone);
    } catch (lookupErr) {
      if (lookupErr.code === 'auth/user-not-found') {
        userRecord = await admin.auth().createUser({
          phoneNumber: '+' + cleanPhone,
        });
      } else {
        throw lookupErr;
      }
    }

    // create custom token for client sign in
    const customToken = await admin.auth().createCustomToken(userRecord.uid);

    // set users/{uid}.phone (+94 normalized) and phoneVerified = true with Admin SDK
    await db.collection('users').doc(userRecord.uid).set(
      {
        phone: '+' + cleanPhone,
        phoneVerified: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return res.status(200).json({
      success: true,
      customToken,
      uid: userRecord.uid,
      message: 'Phone number verified successfully.',
    });
  } catch (err) {
    console.error('Error verifying SMS OTP:', err);
    return res.status(500).json({ error: 'Internal server error during verification.' });
  }
};
