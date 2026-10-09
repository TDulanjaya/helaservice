const crypto = require('crypto');
const https = require('https');
const { db } = require('./_firebase');
const { verifyApiKey } = require('./_auth');

// send sms via notifylk gateway
function sendNotifyLkSms({ to, message }) {
  return new Promise((resolve, reject) => {
    const userId = (process.env.NOTIFYLK_USER_ID || process.env.NOTIFY_LK_USER_ID || '').trim();
    const apiKey = (process.env.NOTIFYLK_API_KEY || process.env.NOTIFY_LK_API_KEY || '').trim();
    const senderId = (process.env.NOTIFYLK_SENDER_ID || process.env.NOTIFY_LK_SENDER_ID || '').trim();

    if (!userId || !apiKey || !senderId) {
      const err = new Error('sms_not_configured');
      err.code = 'sms_not_configured';
      return reject(err);
    }

    const payload = JSON.stringify({
      user_id: userId,
      api_key: apiKey,
      sender_id: senderId,
      to,
      message,
    });

    const req = https.request(
      'https://app.notify.lk/api/v1/send',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(payload),
        },
      },
      (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve({ status: 'success', data: body });
          } else {
            console.error('NotifyLK API error:', res.statusCode, body);
            resolve({ status: 'error', data: body });
          }
        });
      }
    );

    req.on('error', (e) => {
      console.error('NotifyLK request error:', e);
      reject(e);
    });

    req.write(payload);
    req.end();
  });
}

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
    const { phone } = req.body || {};
    if (!phone || typeof phone !== 'string') {
      return res.status(400).json({ error: 'Phone number is required.' });
    }

    const cleanPhone = normalizeSriLankanPhone(phone);
    if (cleanPhone.length !== 11 || !cleanPhone.startsWith('947')) {
      return res.status(400).json({ error: 'Invalid Sri Lankan mobile phone number.' });
    }

    const now = Date.now();

    // check phone cooldown
    const docRef = db.collection('otp_verifications').doc(cleanPhone);
    const existingDoc = await docRef.get();

    if (existingDoc.exists) {
      const data = existingDoc.data() || {};
      const timeSinceLast = now - (data.createdAt || 0);
      if (timeSinceLast < 60000) {
        const remainingSeconds = Math.ceil((60000 - timeSinceLast) / 1000);
        return res.status(429).json({
          error: `Please wait ${remainingSeconds} seconds before requesting a new code.`,
          retryAfter: remainingSeconds,
        });
      }
    }

    // generate otp code
    const otp = crypto.randomInt(100000, 1000000).toString();
    const hashedOtp = crypto.createHash('sha256').update(otp).digest('hex');

    // save to firestore with 10 minute expiry
    await docRef.set({
      phone: cleanPhone,
      otpHash: hashedOtp,
      createdAt: now,
      expiresAt: now + 10 * 60 * 1000,
      attempts: 0,
      verified: false,
    });

    const smsText = `Your HelaService verification code is: ${otp}. Valid for 10 minutes.`;
    await sendNotifyLkSms({ to: cleanPhone, message: smsText });

    return res.status(200).json({
      success: true,
      message: 'Verification code sent successfully via SMS.',
    });
  } catch (err) {
    console.error('Error sending SMS OTP:', err);
    if (err.code === 'sms_not_configured' || err.message === 'sms_not_configured') {
      return res.status(503).json({
        error: 'sms_not_configured',
        message: 'SMS gateway is not configured.',
      });
    }
    return res.status(500).json({ error: 'Internal server error. Failed to send SMS code.' });
  }
};
