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
        isAuthorizedAdmin = true;
      }
    }

    if (!isAuthorizedAdmin) {
      return res.status(403).json({ error: 'Admin access required' });
    }

    const payload = req.method === 'POST' ? (req.body || {}) : (req.query || {});
    const { providerId, side } = payload;

    if (!providerId || (side !== 'front' && side !== 'back')) {
      return res.status(400).json({ error: 'providerId and side are required' });
    }

    // find document key
    let key = null;
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
      action: 'nic_viewed',
      adminUid: callerUid,
      providerId,
      side,
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
