const crypto = require('crypto');
const { admin, db } = require('./_firebase');
const { verifyApiKey, verifyFirebaseToken } = require('./_auth');

module.exports = async function handler(req, res) {
  // Allow cross origin
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-helaservice-key');

  // Handle preflight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  // check api key
  if (!verifyApiKey(req, res)) {
    return;
  }

  // check user token
  const decodedToken = await verifyFirebaseToken(req, res);
  if (!decodedToken) {
    return;
  }

  const callerUid = decodedToken.uid;
  const userEmail = (decodedToken.email || '').trim().toLowerCase();

  try {
    const { otp, purpose = 'signup' } = req.body || {};

    if (!otp) {
      return res.status(400).json({ error: 'OTP is required.', code: 'otp_required' });
    }

    if (purpose !== 'signup' && purpose !== 'admin_login') {
      return res.status(400).json({
        error: 'Invalid purpose. Must be "signup" or "admin_login".',
        code: 'invalid_purpose',
      });
    }

    const cleanOtp = String(otp).trim();
    const sessionDocId = `otp_${callerUid}_${purpose}`;
    const sessionDocRef = db.collection('otp_verifications').doc(sessionDocId);
    const sessionDoc = await sessionDocRef.get();

    if (!sessionDoc.exists) {
      return res.status(400).json({
        error: 'No active verification session found. Please request a new code.',
        code: 'otp_no_session',
      });
    }

    const data = sessionDoc.data() || {};

    // check if expired
    if (Date.now() > (data.expiresAt || 0)) {
      await sessionDocRef.delete();
      return res.status(400).json({
        error: 'Verification code has expired. Please request a new code.',
        code: 'otp_expired',
      });
    }

    // check attempts
    if ((data.attempts || 0) >= 5) {
      await sessionDocRef.delete();
      return res.status(403).json({
        error: 'Maximum attempts exceeded. This verification session has been terminated.',
        code: 'otp_max_attempts',
      });
    }

    // compare hash with salt
    const storedSalt = data.salt || '';
    const storedHash = data.hashedOtp || '';
    const computedHash = crypto.createHash('sha256').update(storedSalt + cleanOtp).digest('hex');

    const bufComputed = Buffer.from(computedHash, 'utf8');
    const bufStored = Buffer.from(storedHash, 'utf8');

    const isValid =
      bufComputed.length === bufStored.length &&
      crypto.timingSafeEqual(bufComputed, bufStored);

    if (!isValid) {
      const updatedAttempts = (data.attempts || 0) + 1;
      if (updatedAttempts >= 5) {
        // remove after five tries
        await sessionDocRef.delete();
        return res.status(403).json({
          error: 'Maximum attempts exceeded. Please request a new verification code.',
          code: 'otp_max_attempts',
        });
      } else {
        await sessionDocRef.update({
          attempts: admin.firestore.FieldValue.increment(1),
        });
        const remaining = 5 - updatedAttempts;
        return res.status(401).json({
          error: `Incorrect verification code. ${remaining} attempt(s) remaining.`,
          code: 'otp_incorrect',
          attemptsRemaining: remaining,
        });
      }
    }

    // remove session on success
    await sessionDocRef.delete();

    // get current claims
    const userRecord = await admin.auth().getUser(callerUid);
    const currentClaims = userRecord.customClaims || {};

    if (purpose === 'signup') {
      // set verified claim
      const newClaims = { ...currentClaims, emailOtp: true };
      await admin.auth().setCustomUserClaims(callerUid, newClaims);

      // update user doc
      await db.collection('users').doc(callerUid).set(
        {
          emailOtpVerified: true,
          emailOtpVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return res.status(200).json({
        success: true,
        message: 'Email OTP verified successfully.',
        purpose,
      });
    }

    if (purpose === 'admin_login') {
      // check if admin
      const superDoc = await db.collection('superAdmins').doc(callerUid).get();
      let role = superDoc.exists ? 'super_admin' : null;

      if (!role) {
        const adminDoc = await db.collection('admins').doc(callerUid).get();
        if (adminDoc.exists && adminDoc.data() && adminDoc.data().status === 'active') {
          role = adminDoc.data().role || 'admin';
        }
      }

      if (!role) {
        return res.status(403).json({
          error: 'Unauthorized: caller is not an active administrator.',
          code: 'not_admin',
        });
      }

      // valid for twelve hours
      const nowSec = Math.floor(Date.now() / 1000);
      const admin2faUntil = nowSec + 12 * 3600;

      // save admin claim
      const newClaims = { ...currentClaims, admin2faUntil };
      await admin.auth().setCustomUserClaims(callerUid, newClaims);

      // write audit log
      const forwardedHeader = req.headers['x-forwarded-for'];
      const clientIp = (typeof forwardedHeader === 'string' && forwardedHeader.trim().length > 0)
        ? forwardedHeader.split(',')[0].trim()
        : (req.socket?.remoteAddress || '127.0.0.1');

      await db.collection('adminLogs').add({
        action: 'admin_login_verified',
        adminId: callerUid,
        adminEmail: userEmail,
        role,
        ip: clientIp,
        expiresAt: admin2faUntil,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.status(200).json({
        success: true,
        message: 'Admin 2FA verified successfully.',
        purpose,
        admin2faUntil,
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Verified successfully.',
    });
  } catch (error) {
    console.error('[verify-otp Error]', error);
    return res.status(500).json({
      error: 'Verification failed due to a server error. Please try again.',
      code: 'server_error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};
