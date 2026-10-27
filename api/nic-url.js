const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { admin, db } = require('./_firebase');
const { verifyFirebaseToken } = require('./_auth');

// initialize private storage client
function getPrivateS3Client() {
  const keyId = (process.env.B2_PRIVATE_KEY_ID || '').trim();
  const appKey = (process.env.B2_PRIVATE_KEY || '').trim();
  if (!keyId || !appKey) return null;

  let rawEndpoint = (process.env.B2_PRIVATE_ENDPOINT || process.env.B2_ENDPOINT || 'https://s3.us-west-004.backblazeb2.com').trim();
  if (!rawEndpoint.startsWith('http://') && !rawEndpoint.startsWith('https://')) {
    rawEndpoint = `https://${rawEndpoint}`;
  }

  let region = (process.env.B2_PRIVATE_REGION || process.env.B2_REGION || '').trim();
  if (!region) {
    const match = rawEndpoint.match(/s3\.([a-z0-9-]+)\.backblazeb2\.com/i);
    region = match ? match[1] : 'us-west-004';
  }

  return new S3Client({
    endpoint: rawEndpoint,
    region,
    credentials: {
      accessKeyId: keyId,
      secretAccessKey: appKey,
    },
    requestChecksumCalculation: 'WHEN_REQUIRED',
    responseChecksumValidation: 'WHEN_REQUIRED',
  });
}

module.exports = async function handler(req, res) {
  // set cors headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-helaservice-key');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST' && req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // require firebase auth token
  const decodedToken = await verifyFirebaseToken(req, res);
  if (!decodedToken) {
    return;
  }
  const callerUid = decodedToken.uid;

  // Enforce active admin 2FA claim or active login OTP session
  const nowSec = Math.floor(Date.now() / 1000);
  const hasAdmin2fa = typeof decodedToken.admin2faUntil === 'number' && decodedToken.admin2faUntil > nowSec;
  const authTime = decodedToken.auth_time;
  const loginOtpTimes = Array.isArray(decodedToken.loginOtpTimes) ? decodedToken.loginOtpTimes : [];
  const hasLoginOtp = typeof authTime === 'number' && loginOtpTimes.includes(authTime);

  if (!hasAdmin2fa && !hasLoginOtp) {
    return res.status(403).json({ error: 'admin_2fa_required', message: 'Admin 2FA verification required or expired.' });
  }

  if (!process.env.B2_PRIVATE_BUCKET || !process.env.B2_PRIVATE_KEY_ID || !process.env.B2_PRIVATE_KEY) {
    return res.status(500).json({ error: 'private_storage_not_configured' });
  }

  try {
    // verify admin authorization
    const superAdminDoc = await db.collection('superAdmins').doc(callerUid).get();
    let isAuthorizedAdmin = superAdminDoc.exists;

    if (!isAuthorizedAdmin) {
      const adminDoc = await db.collection('admins').doc(callerUid).get();
      if (adminDoc.exists && adminDoc.data() && adminDoc.data().status === 'active') {
        const perms = Array.isArray(adminDoc.data().permissions) ? adminDoc.data().permissions : [];
        if (perms.includes('verify_nic')) {
          isAuthorizedAdmin = true;
        }
      }
    }

    if (!isAuthorizedAdmin) {
      await db.collection('adminLogs').add({
        action: 'nic_view_denied',
        adminUid: callerUid,
        reason: 'missing_verify_nic_permission',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: Date.now(),
      }).catch(() => {});
      return res.status(403).json({ error: 'Permission verify_nic required' });
    }

    const payload = req.method === 'POST' ? (req.body || {}) : (req.query || {});
    const { providerId, side, key: certKey } = payload;

    if (!providerId) {
      return res.status(400).json({ error: 'providerId is required' });
    }

    let key = null;

    if (certKey && typeof certKey === 'string') {
      if (!certKey.startsWith(`certs/${providerId}/`)) {
        return res.status(400).json({ error: 'invalid_cert_key' });
      }

      // verify that certificates doc with that key exists for this provider
      const certSnap = await db
        .collection('technicians')
        .doc(providerId)
        .collection('certificates')
        .where('key', '==', certKey)
        .limit(1)
        .get();

      if (certSnap.empty) {
        return res.status(404).json({ error: 'certificate_not_found' });
      }

      key = certKey;
    } else {
      if (side !== 'front' && side !== 'back') {
        return res.status(400).json({ error: 'providerId and valid side (front/back) or key are required' });
      }

      // find document key
      const kycDoc = await db
        .collection('technicians')
        .doc(providerId)
        .collection('private')
        .doc('kyc')
        .get();

      if (kycDoc.exists) {
        const data = kycDoc.data() || {};
        key = side === 'front'
          ? (data.nicFrontKey || data.nicFrontUrl)
          : (data.nicBackKey || data.nicBackUrl);
      }

      if (!key) {
        const queueDoc = await db.collection('verificationQueue').doc(providerId).get();
        if (queueDoc.exists) {
          const data = queueDoc.data() || {};
          key = side === 'front'
            ? (data.nicFrontKey || data.nicFrontUrl)
            : (data.nicBackKey || data.nicBackUrl);
        }
      }

      if (!key) {
        const techDoc = await db.collection('technicians').doc(providerId).get();
        if (techDoc.exists) {
          const data = techDoc.data() || {};
          key = side === 'front' ? data.nicFrontUrl : data.nicBackUrl;
        }
      }

      if (!key || typeof key !== 'string') {
        return res.status(404).json({ error: 'NIC key not found for provider' });
      }

      if (key.startsWith('http://') || key.startsWith('https://')) {
        return res.status(409).json({ error: 'legacy_nic_url' });
      }

      if (!key.startsWith(`nic/${providerId}/`)) {
        return res.status(400).json({ error: 'invalid_nic_key' });
      }
    }

    const s3 = getPrivateS3Client();
    if (!s3) {
      return res.status(500).json({ error: 'private_storage_not_configured' });
    }

    const bucketName = process.env.B2_PRIVATE_BUCKET.trim();

    const command = new GetObjectCommand({
      Bucket: bucketName,
      Key: key,
    });

    const presignedUrl = await getSignedUrl(s3, command, { expiresIn: 300 });

    // log view event to admin audit logs
    await db.collection('adminLogs').add({
      action: certKey ? 'cert_viewed' : 'nic_viewed',
      adminUid: callerUid,
      providerId,
      side: side || null,
      key,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: Date.now(),
    });

    return res.status(200).json({
      url: presignedUrl,
      expiresIn: 300,
    });
  } catch (err) {
    console.error('Error generating presigned nic url:', err);
    return res.status(500).json({ error: 'Failed to generate NIC url' });
  }
};
