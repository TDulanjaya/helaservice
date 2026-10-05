const crypto = require('crypto');
const nodemailer = require('nodemailer');
const { db } = require('./_firebase');

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 465,
  secure: true,
  auth: {
    user: (process.env.GMAIL_USER || '').trim(),
    pass: (process.env.GMAIL_APP_PASSWORD || '').replace(/\s+/g, ''),
  },
});

module.exports = async function handler(req, res) {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    const { email } = req.body || {};

    if (!email || typeof email !== 'string') {
      return res.status(400).json({ error: 'Email address is required.' });
    }

    const cleanEmail = email.trim().toLowerCase();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(cleanEmail)) {
      return res.status(400).json({ error: 'Invalid email address format.' });
    }

    const docRef = db.collection('otp_verifications').doc(cleanEmail);
    const existingDoc = await docRef.get();

    // Enforce 60-second rate limiting cooldown
    if (existingDoc.exists) {
      const data = existingDoc.data();
      const timeSinceLast = Date.now() - (data.createdAt || 0);
      if (timeSinceLast < 60000) {
        const remainingSeconds = Math.ceil((60000 - timeSinceLast) / 1000);
        return res.status(429).json({
          error: `Please wait ${remainingSeconds} seconds before requesting a new verification code.`,
          retryAfter: remainingSeconds,
        });
      }
    }

    // Generate secure 6-digit OTP and SHA-256 hash
    const otp = crypto.randomInt(100000, 1000000).toString();
    const hashedOtp = crypto.createHash('sha256').update(otp).digest('hex');
    const now = Date.now();
    const expiresAt = now + 5 * 60 * 1000; // 5 minutes TTL

    // Save hash and metadata to Firestore
    await docRef.set({
      hashedOtp,
      createdAt: now,
      expiresAt,
      attempts: 0,
    });

    // Send branded HTML email via Gmail SMTP
    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #FAF9F5; margin: 0; padding: 24px; }
          .container { max-width: 480px; margin: 0 auto; background: #FFFFFF; border: 1px solid #ECE6D9; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.03); }
          .header { background: #D6900F; padding: 28px 24px; text-align: center; }
          .header h1 { color: #17140F; margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.5px; }
          .content { padding: 32px 28px; text-align: center; }
          .title { font-size: 18px; font-weight: 700; color: #17140F; margin: 0 0 12px 0; }
          .subtitle { font-size: 14px; color: #6B665B; line-height: 1.5; margin: 0 0 24px 0; }
          .otp-box { background: #FBF0DA; border: 2px dashed #D6900F; border-radius: 12px; padding: 18px; font-size: 32px; font-weight: 800; letter-spacing: 8px; color: #17140F; margin: 0 auto 24px auto; display: inline-block; min-width: 240px; }
          .footer { font-size: 12px; color: #9A6206; line-height: 1.5; border-top: 1px solid #ECE6D9; padding-top: 16px; margin-top: 24px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>HelaService</h1>
          </div>
          <div class="content">
            <h2 class="title">Verify Your Email Address</h2>
            <p class="subtitle">Use the verification code below to complete your authentication. This code is valid for <strong>5 minutes</strong>.</p>
            <div class="otp-box">${otp}</div>
            <p style="font-size: 13px; color: #6B665B; margin: 0;">Never share this code with anyone. HelaService staff will never ask for your code.</p>
            <div class="footer">
              If you didn't request this email, you can safely ignore it.
            </div>
          </div>
        </div>
      </body>
      </html>
    `;

    await transporter.sendMail({
      from: `"HelaService" <${process.env.GMAIL_USER}>`,
      to: cleanEmail,
      subject: `Your HelaService Verification Code: ${otp}`,
      text: `Your HelaService verification code is: ${otp}. It expires in 5 minutes.`,
      html: htmlContent,
    });

    return res.status(200).json({
      success: true,
      message: 'OTP sent successfully',
    });
  } catch (error) {
    console.error('[send-otp Error]', error);
    return res.status(500).json({
      error: 'Failed to send verification code. Please try again later.',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};
