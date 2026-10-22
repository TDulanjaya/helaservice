const crypto = require('crypto');
const { admin } = require('./_firebase');

// check api key
function verifyApiKey(req, res) {
  const expectedKey = (process.env.HELASERVICE_API_KEY || '').trim();
  if (!expectedKey) {
    console.error('[Auth Error] Server misconfigured: HELASERVICE_API_KEY is missing or empty.');
    res.status(500).json({ error: 'Server misconfigured' });
    return false;
  }

  const clientKey = (req.headers['x-helaservice-key'] || '').trim();
  const bufClient = Buffer.from(clientKey, 'utf8');
  const bufExpected = Buffer.from(expectedKey, 'utf8');

  if (bufClient.length !== bufExpected.length || !crypto.timingSafeEqual(bufClient, bufExpected)) {
    res.status(401).json({ error: 'Unauthorized: Valid API key required.' });
    return false;
  }

  return true;
}

// check firebase token
async function verifyFirebaseToken(req, res, { requireLoginOtp = true } = {}) {
  const authHeader = (req.headers.authorization || '').trim();
  if (!authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized: Valid Firebase session token required.' });
    return null;
  }

  const idToken = authHeader.substring(7).trim();
  if (!idToken) {
    res.status(401).json({ error: 'Unauthorized: Valid Firebase session token required.' });
    return null;
  }

  try {
    const decoded = await admin.auth().verifyIdToken(idToken);

    if (requireLoginOtp) {
      const authTime = decoded.auth_time;
      const loginOtpTimes = Array.isArray(decoded.loginOtpTimes) ? decoded.loginOtpTimes : [];
      if (!authTime || !loginOtpTimes.includes(authTime)) {
        res.status(403).json({ error: 'login_otp_required' });
        return null;
      }
    }

    return decoded;
  } catch (err) {
    res.status(401).json({ error: 'Unauthorized: Invalid Firebase session token.' });
    return null;
  }
}

module.exports = {
  verifyApiKey,
  verifyFirebaseToken,
};
