const crypto = require('crypto');
const { admin, db } = require('./_firebase');

module.exports = async function handler(req, res) {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    const { email, otp } = req.body || {};

    if (!email || !otp) {
      return res.status(400).json({ error: 'Email and OTP are both required.' });
    }

    const cleanEmail = email.trim().toLowerCase();
    const cleanOtp = String(otp).trim();

    const docRef = db.collection('otp_verifications').doc(cleanEmail);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(400).json({
        error: 'No active verification session found. Please request a new code.',
      });
    }

    const data = doc.data();

    // Check expiration (5 minutes TTL)
    if (Date.now() > data.expiresAt) {
      await docRef.delete();
      return res.status(400).json({
        error: 'Verification code has expired. Please request a new code.',
      });
    }

    // Check brute-force attempts
    if (data.attempts >= 5) {
      await docRef.delete();
      return res.status(403).json({
        error: 'Maximum attempts exceeded. This verification session has been terminated.',
      });
    }

    // Compare SHA-256 hashes using timingSafeEqual
    const incomingHash = crypto.createHash('sha256').update(cleanOtp).digest('hex');
    const storedHash = data.hashedOtp || '';

    const bufIncoming = Buffer.from(incomingHash, 'utf8');
    const bufStored = Buffer.from(storedHash, 'utf8');

    const isValid =
      bufIncoming.length === bufStored.length &&
      crypto.timingSafeEqual(bufIncoming, bufStored);

    if (!isValid) {
      const updatedAttempts = (data.attempts || 0) + 1;
      if (updatedAttempts >= 5) {
        await docRef.delete();
        return res.status(403).json({
          error: 'Maximum attempts exceeded. Please request a new verification code.',
        });
      } else {
        await docRef.update({
          attempts: admin.firestore.FieldValue.increment(1),
        });
        const remaining = 5 - updatedAttempts;
        return res.status(401).json({
          error: `Incorrect verification code. ${remaining} attempt(s) remaining.`,
        });
      }
    }

    // Success: Delete the OTP record immediately
    await docRef.delete();

    return res.status(200).json({
      success: true,
      message: 'OTP verified successfully',
    });
  } catch (error) {
    console.error('[verify-otp Error]', error);
    return res.status(500).json({
      error: 'Verification failed due to a server error. Please try again.',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};
