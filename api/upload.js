const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const busboy = require('busboy');
const { admin } = require('./_firebase');

// init s3 client from env
function getS3Client() {
  const keyId = (process.env.B2_APPLICATION_KEY_ID || process.env.AWS_ACCESS_KEY_ID || '').trim();
  const appKey = (process.env.B2_APPLICATION_KEY || process.env.AWS_SECRET_ACCESS_KEY || '').trim();
  if (!keyId || !appKey) return null;

  let rawEndpoint = (process.env.B2_ENDPOINT || 'https://s3.us-west-004.backblazeb2.com').trim();
  if (!rawEndpoint.startsWith('http://') && !rawEndpoint.startsWith('https://')) {
    rawEndpoint = `https://${rawEndpoint}`;
  }

  let region = (process.env.B2_REGION || '').trim();
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

module.exports = async (req, res) => {
  // cors
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-helaservice-key');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // verify api key or firebase auth
  const expectedKey = (process.env.HELASERVICE_API_KEY || 'hela_app_sec_k9827x_prod').trim();
  const clientKey = (req.headers['x-helaservice-key'] || '').trim();

  let authUid = null;
  const authHeader = req.headers.authorization || '';
  if (authHeader.startsWith('Bearer ')) {
    const idToken = authHeader.split('Bearer ')[1].trim();
    try {
      const decoded = await admin.auth().verifyIdToken(idToken);
      authUid = decoded.uid;
    } catch (_) {
      // invalid firebase token
      return res.status(401).json({ error: 'Unauthorized: Invalid Firebase session token.' });
    }
  }

  if (!authUid && clientKey !== expectedKey) {
    return res.status(401).json({ error: 'Unauthorized: Valid API key or Firebase token required.' });
  }

  const s3 = getS3Client();
  if (!s3) {
    return res.status(500).json({
      error: 'B2 storage credentials (B2_APPLICATION_KEY_ID / B2_APPLICATION_KEY) are not configured in Vercel environment variables.',
    });
  }

  const bucketName = (process.env.B2_BUCKET_NAME || 'helaservice-storage').trim();
  let publicPrefix = (process.env.B2_PUBLIC_URL_PREFIX || '').trim();
  if (!publicPrefix) {
    const rawEndpoint = (process.env.B2_ENDPOINT || 's3.us-west-004.backblazeb2.com').trim();
    const clusterMatch = rawEndpoint.match(/00\d+/);
    const cluster = clusterMatch ? clusterMatch[0] : '004';
    publicPrefix = `https://f${cluster}.backblazeb2.com/file/${bucketName}`;
  }

  try {
    const bb = busboy({ headers: req.headers, limits: { fileSize: 10 * 1024 * 1024 } });
    let uploadPromise = null;

    // parse file stream
    bb.on('file', (name, file, info) => {
      const rawExt = (filename && filename.includes('.'))
          ? filename.split('.').pop().toLowerCase()
          : 'jpg';
      const allowedExts = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];
      const cleanExt = allowedExts.includes(rawExt) ? rawExt : 'jpg';
      const key = `uploads/${Date.now()}_${Math.random().toString(36).substring(2, 9)}.${cleanExt}`;

      const chunks = [];
      file.on('data', (data) => chunks.push(data));
      file.on('end', () => {
        const buffer = Buffer.concat(chunks);
        uploadPromise = s3
          .send(
            new PutObjectCommand({
              Bucket: bucketName,
              Key: key,
              Body: buffer,
              ContentType: mimeType || 'image/jpeg',
            })
          )
          .then(() => {
            const cleanPrefix = publicPrefix.replace(/\/+$/, '');
            const publicUrl = `${cleanPrefix}/${key}`;
            return { url: publicUrl, key };
          });
      });
    });

    bb.on('error', (err) => {
      res.status(500).json({ error: `Upload stream failed: ${err.message}` });
    });

    bb.on('finish', async () => {
      if (!uploadPromise) {
        return res.status(400).json({ error: 'No file found in request' });
      }
      try {
        const result = await uploadPromise;
        return res.status(200).json(result);
      } catch (err) {
        return res.status(500).json({ error: `B2 S3 put failed: ${err.message}` });
      }
    });

    req.pipe(bb);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};
