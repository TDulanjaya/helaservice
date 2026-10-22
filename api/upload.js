const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const busboy = require('busboy');
const { verifyFirebaseToken } = require('./_auth');
const { admin, db } = require('./_firebase');

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

  // Caller must be verified (emailOtp claim) or an admin
  const isEmailOtpVerified = decodedToken.emailOtp === true;
  const isAdmin = !!(decodedToken.admin2faUntil || decodedToken.admin || decodedToken.superAdmin);
  if (!isEmailOtpVerified && !isAdmin) {
    const superDoc = await db.collection('superAdmins').doc(authUid).get();
    let adminAuthorized = superDoc.exists;
    if (!adminAuthorized) {
      const adminDoc = await db.collection('admins').doc(authUid).get();
      adminAuthorized = adminDoc.exists && adminDoc.data() && adminDoc.data().status === 'active';
    }
    if (!adminAuthorized) {
      return res.status(403).json({ error: 'email_otp_required', message: 'Email OTP verification is required.' });
    }
  }

  const purpose = (req.query && req.query.purpose ? req.query.purpose : '').toLowerCase();
  const isPrivatePurpose = purpose === 'nic' || purpose === 'cert';

  if (isPrivatePurpose) {
    if (!process.env.B2_PRIVATE_BUCKET || !process.env.B2_PRIVATE_KEY_ID || !process.env.B2_PRIVATE_KEY) {
      return res.status(500).json({ error: 'private_storage_not_configured' });
    }
  } else {
    if (!process.env.B2_BUCKET_NAME || !process.env.B2_BUCKET_NAME.trim()) {
      console.error('B2_BUCKET_NAME is not configured');
      return res.status(500).json({ error: 'storage_not_configured' });
    }
    if (!process.env.MEDIA_URL_BASE || !process.env.MEDIA_URL_BASE.trim()) {
      console.error('MEDIA_URL_BASE is not configured');
      return res.status(500).json({ error: 'storage_not_configured' });
    }
  }

  const s3 = getS3Client(isPrivatePurpose);
  if (!s3) {
    if (isPrivatePurpose) {
      return res.status(500).json({ error: 'private_storage_not_configured' });
    }
    return res.status(500).json({
      error: 'B2 storage credentials are not configured in environment variables.',
    });
  }

  const bucketName = (isPrivatePurpose
    ? process.env.B2_PRIVATE_BUCKET
    : process.env.B2_BUCKET_NAME).trim();

  // JSON mode: presigned URL generation for job media uploads
  let body = req.body;
  if (typeof body === 'string') {
    try {
      body = JSON.parse(body);
    } catch (_) {}
  }

  if (body && body.mode === 'presign') {
    const presignPurpose = (body.purpose || '').toLowerCase();
    if (presignPurpose !== 'job_media') {
      return res.status(400).json({ error: 'Invalid purpose for presign. Expected job_media.' });
    }
    const contentType = (body.contentType || '').toLowerCase();
    const ALLOWED_PRESIGN_TYPES = ['image/jpeg', 'video/mp4'];
    if (!ALLOWED_PRESIGN_TYPES.includes(contentType)) {
      return res.status(415).json({
        error: 'Unsupported Media Type for presign. Allowed types are image/jpeg, video/mp4.',
      });
    }
    const sizeBytes = Number(body.sizeBytes);
    if (!sizeBytes || isNaN(sizeBytes) || sizeBytes <= 0) {
      return res.status(400).json({ error: 'Valid sizeBytes is required.' });
    }
    const isVideo = contentType === 'video/mp4';
    const maxSize = isVideo ? 60 * 1024 * 1024 : 3 * 1024 * 1024;
    if (sizeBytes > maxSize) {
      return res.status(400).json({
        error: `File size exceeds limit (${isVideo ? '60 MB' : '3 MB'}).`,
      });
    }

    // Rate limiting: 40 presigns per user per hour
    const now = Date.now();
    const oneHourMs = 60 * 60 * 1000;
    const rateRef = db.collection('upload_rate_limits').doc(authUid);
    const rateDoc = await rateRef.get();
    let count = 0;
    let windowStart = now;
    if (rateDoc.exists) {
      const data = rateDoc.data() || {};
      const docWindowStart = data.windowStart || 0;
      if (now - docWindowStart < oneHourMs) {
        count = data.count || 0;
        windowStart = docWindowStart;
      }
    }
    if (count >= 40) {
      const remainingSeconds = Math.ceil((windowStart + oneHourMs - now) / 1000);
      return res.status(429).json({
        error: 'Too many presign requests. Limit is 40 per hour.',
        retryAfter: remainingSeconds,
      });
    }
    await rateRef.set({
      count: count + 1,
      windowStart,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const ext = isVideo ? 'mp4' : 'jpg';
    const randomStr = Math.random().toString(36).substring(2, 9);
    const key = `uploads/${authUid}/jobs/${Date.now()}_${randomStr}.${ext}`;

    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: key,
      ContentType: contentType,
      ContentLength: sizeBytes,
    });

    try {
      const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 600 });
      const mediaBase = process.env.MEDIA_URL_BASE.trim().replace(/\/+$/, '');
      const publicUrl = `${mediaBase}/api/media?key=${key}`;
      return res.status(200).json({ uploadUrl, key, publicUrl });
    } catch (err) {
      return res.status(500).json({ error: `Presign generation failed: ${err.message}` });
    }
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
      const key = purpose === 'nic'
        ? `nic/${authUid}/${Date.now()}_${randomStr}.${cleanExt}`
        : purpose === 'cert'
          ? `certs/${authUid}/${Date.now()}_${randomStr}.${cleanExt}`
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
            if (isPrivatePurpose) {
              return { key };
            }
            const mediaBase = process.env.MEDIA_URL_BASE.trim().replace(/\/+$/, '');
            const publicUrl = `${mediaBase}/api/media?key=${key}`;
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
