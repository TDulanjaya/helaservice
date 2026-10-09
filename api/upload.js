const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const busboy = require('busboy');
const { verifyFirebaseToken } = require('./_auth');

// initialize storage client
function getS3Client(isPrivate = false) {
  const keyId = (isPrivate
    ? (process.env.B2_PRIVATE_KEY_ID || '')
    : (process.env.B2_APPLICATION_KEY_ID || process.env.AWS_ACCESS_KEY_ID || '')).trim();
  const appKey = (isPrivate
    ? (process.env.B2_PRIVATE_KEY || '')
    : (process.env.B2_APPLICATION_KEY || process.env.AWS_SECRET_ACCESS_KEY || '')).trim();
  if (!keyId || !appKey) return null;

  let rawEndpoint = (isPrivate
    ? (process.env.B2_PRIVATE_ENDPOINT || process.env.B2_ENDPOINT || 'https://s3.us-west-004.backblazeb2.com')
    : (process.env.B2_ENDPOINT || 'https://s3.us-west-004.backblazeb2.com')).trim();
  if (!rawEndpoint.startsWith('http://') && !rawEndpoint.startsWith('https://')) {
    rawEndpoint = `https://${rawEndpoint}`;
  }

  let region = (isPrivate
    ? (process.env.B2_PRIVATE_REGION || process.env.B2_REGION || '')
    : (process.env.B2_REGION || '')).trim();
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

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
const MIME_TO_EXT = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'application/pdf': 'pdf',
};

module.exports = async (req, res) => {
  // allow cross origin
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // require valid firebase token
  const decodedToken = await verifyFirebaseToken(req, res);
  if (!decodedToken) {
    return;
  }
  const authUid = decodedToken.uid;

  const purpose = (req.query && req.query.purpose ? req.query.purpose : '').toLowerCase();
  const isNicPurpose = purpose === 'nic';

  if (isNicPurpose) {
    if (!process.env.B2_PRIVATE_BUCKET || !process.env.B2_PRIVATE_KEY_ID || !process.env.B2_PRIVATE_KEY) {
      return res.status(500).json({ error: 'private_storage_not_configured' });
    }
  }

  const s3 = getS3Client(isNicPurpose);
  if (!s3) {
    if (isNicPurpose) {
      return res.status(500).json({ error: 'private_storage_not_configured' });
    }
    return res.status(500).json({
      error: 'B2 storage credentials are not configured in environment variables.',
    });
  }

  const bucketName = (isNicPurpose
    ? process.env.B2_PRIVATE_BUCKET
    : (process.env.B2_BUCKET_NAME || 'helaservice-storage')).trim();

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
    let unsupportedMedia = false;

    // parse file stream
    bb.on('file', (name, file, info) => {
      const { filename, mimeType } = info;

      if (!mimeType || !ALLOWED_MIME_TYPES.includes(mimeType.toLowerCase())) {
        file.resume(); // drain file stream
        unsupportedMedia = true;
        return;
      }

      const normalizedMime = mimeType.toLowerCase();
      const rawExt = (filename && filename.includes('.'))
        ? filename.split('.').pop().toLowerCase()
        : MIME_TO_EXT[normalizedMime];

      const cleanExt = (rawExt === 'jpeg' || rawExt === 'jpg')
        ? 'jpg'
        : (rawExt === 'png'
          ? 'png'
          : (rawExt === 'webp'
            ? 'webp'
            : (rawExt === 'pdf' ? 'pdf' : MIME_TO_EXT[normalizedMime])));

      const randomStr = Math.random().toString(36).substring(2, 9);
      const key = isNicPurpose
        ? `nic/${authUid}/${Date.now()}_${randomStr}.${cleanExt}`
        : `uploads/${authUid}/${Date.now()}_${randomStr}.${cleanExt}`;

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
              ContentType: normalizedMime,
            })
          )
          .then(() => {
            if (isNicPurpose) {
              return { key };
            }
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
      if (unsupportedMedia) {
        return res.status(415).json({
          error: 'Unsupported Media Type: Allowed types are image/jpeg, image/png, image/webp, application/pdf.',
        });
      }

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
