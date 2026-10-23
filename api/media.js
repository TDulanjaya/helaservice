const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const auth = require('./_auth');

// s3 client
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
    requestChecksumCalculation: 'WHEN_REQUIRED',
    responseChecksumValidation: 'WHEN_REQUIRED',
  });
}

// rate limiter
const rateLimitMap = new Map();
const RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000; // 10 minutes
const RATE_LIMIT_MAX_REQUESTS = 600;

function checkRateLimit(uid) {
  const now = Date.now();
  let userRate = rateLimitMap.get(uid);

  if (!userRate || now - userRate.windowStart > RATE_LIMIT_WINDOW_MS) {
    userRate = { count: 1, windowStart: now };
    rateLimitMap.set(uid, userRate);
    return { allowed: true };
  }

  if (userRate.count >= RATE_LIMIT_MAX_REQUESTS) {
    const retryAfter = Math.ceil((userRate.windowStart + RATE_LIMIT_WINDOW_MS - now) / 1000);
    return { allowed: false, retryAfter };
  }

  userRate.count++;
  return { allowed: true };
}

// allowed keys
const KEY_REGEX = /^uploads\/[A-Za-z0-9_-]+(\/(jobs|profile|portfolio))?\/[A-Za-z0-9._-]+$/;

module.exports = async function handler(req, res) {
  // cors
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // check auth
  const decodedToken = await auth.verifyFirebaseToken(req, res);
  if (!decodedToken) {
    return;
  }
  const callerUid = decodedToken.uid;

  // check rate limit
  const rateLimit = checkRateLimit(callerUid);
  if (!rateLimit.allowed) {
    res.setHeader('Retry-After', rateLimit.retryAfter);
    return res.status(429).json({
      error: 'Too many media requests. Please try again later.',
      retryAfter: rateLimit.retryAfter,
    });
  }

  const key = (req.query && typeof req.query.key === 'string' ? req.query.key : '').trim();

  // validate key
  if (!key || key.includes('..') || !KEY_REGEX.test(key)) {
    return res.status(400).json({ error: 'Invalid or disallowed media key' });
  }

  const s3 = getS3Client();
  if (!s3) {
    return res.status(500).json({ error: 'Storage credentials not configured' });
  }

  const bucketName = (process.env.B2_BUCKET_NAME || '').trim();
  if (!bucketName) {
    console.error('B2_BUCKET_NAME is not configured');
    return res.status(500).json({ error: 'storage_not_configured' });
  }

  try {
    const command = new GetObjectCommand({
      Bucket: bucketName,
      Key: key,
    });

    const presignedUrl = await getSignedUrl(s3, command, { expiresIn: 600 });

    if (req.query && req.query.mode === 'json') {
      return res.status(200).json({ url: presignedUrl, expiresIn: 600 });
    }

    res.setHeader('Cache-Control', 'private, max-age=300');
    return res.redirect(302, presignedUrl);
  } catch (err) {
    console.error('[media] presign error:', err.message);
    return res.status(500).json({ error: 'Failed to generate media url' });
  }
};
