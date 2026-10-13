const crypto = require('crypto');
const nodemailer = require('nodemailer');
const { admin, db } = require('./_firebase');
const { verifyApiKey, verifyFirebaseToken } = require('./_auth');

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 465,
  secure: true,
  auth: {
    user: (process.env.GMAIL_USER || '').trim(),
    pass: (process.env.GMAIL_APP_PASSWORD || '').replace(/\s+/g, ''),
  },
});

function getEmailTemplates({ otp, purpose, language }) {
  const isEn = language !== 'si' && language !== 'ta';
  const isSi = language === 'si';
  const isTa = language === 'ta';

  let subject = '';
  let title = '';
  let subtitle = '';
  let purposeDescription = '';
  let securityNote = '';
  let footer = '';

  if (purpose === 'admin_login') {
    if (isSi) {
      subject = `ඔබගේ HelaService පරිපාලක පිවිසුම් කේතය: ${otp}`;
      title = 'පරිපාලක පිවිසුම තහවුරු කරන්න';
      purposeDescription = 'මෙම කේතය ඔබගේ පරිපාලක ගිණුමට (Admin 2FA) පිවිසීම තහවුරු කිරීම සඳහා වේ.';
      subtitle = 'මෙම කේතය <strong>විනාඩි 10ක්</strong> සඳහා වලංගු වේ.';
      securityNote = 'මෙම කේතය කිසිවෙකු සමඟ බෙදා නොගන්න. HelaService කාර්ය මණ්ඩලය කිසි විටෙකත් ඔබෙන් මෙම කේතය ඉල්ලන්නේ නැත.';
      footer = 'ඔබ මෙම පිවිසුම ඉල්ලා නොසිටියේ නම්, වහාම ඔබගේ මුරපදය වෙනස් කරන්න.';
    } else if (isTa) {
      subject = `உங்கள் HelaService நிர்வாகி உள்நுழைவு குறியீடு: ${otp}`;
      title = 'நிர்வாகி உள்நுழைவை சரிபார்க்கவும்';
      purposeDescription = 'இந்தக் குறியீடு உங்கள் நிர்வாகி கணக்கு (Admin 2FA) உள்நுழைவைச் சரிபார்க்கும்.';
      subtitle = 'இந்த குறியீடு <strong>10 நிமிடங்களுக்கு</strong> செல்லுபடியாகும்.';
      securityNote = 'இந்தக் குறியீட்டை யாருடனும் பகிர வேண்டாம். HelaService ஊழியர்கள் ஒருபோதும் உங்கள் குறியீட்டைக் கேட்க மாட்டார்கள்.';
      footer = 'நீங்கள் இந்த உள்நுழைவைக் கோரவில்லை என்றால், உடனடியாக உங்கள் கடவுச்சொல்லை மாற்றவும்.';
    } else {
      subject = `Your HelaService admin login code: ${otp}`;
      title = 'Admin Two-Factor Authentication';
      purposeDescription = 'This code is required to verify your administrator account login.';
      subtitle = 'This code is valid for <strong>10 minutes</strong>.';
      securityNote = 'Never share this code with anyone. HelaService staff will never ask for your code.';
      footer = 'If this wasn\'t you, your password may be compromised. Please change it immediately.';
    }
  } else {
    // signup mode
    if (isSi) {
      subject = `ඔබගේ HelaService තහවුරු කිරීමේ කේතය: ${otp}`;
      title = 'ඔබගේ විද්‍යුත් තැපෑල තහවුරු කරන්න';
      purposeDescription = 'නව HelaService ගිණුම සක්‍රිය කිරීම සඳහා මෙම කේතය භාවිතා කරන්න.';
      subtitle = 'මෙම කේතය <strong>විනාඩි 10ක්</strong> සඳහා වලංගු වේ.';
      securityNote = 'මෙම කේතය කිසිවෙකු සමඟ බෙදා නොගන්න. HelaService කාර්ය මණ්ඩලය කිසි විටෙකත් ඔබෙන් මෙම කේතය ඉල්ලන්නේ නැත.';
      footer = 'ඔබ මෙම ගිණුම ඉල්ලා නොසිටියේ නම්, ඔබට මෙම පණිවිඩය නොසලකා හැරිය හැක.';
    } else if (isTa) {
      subject = `உங்கள் HelaService சரிபார்ப்புக் குறியீடு: ${otp}`;
      title = 'உங்கள் மின்னஞ்சலை சரிபார்க்கவும்';
      purposeDescription = 'புதிய HelaService கணக்கைச் செயல்படுத்த இந்தக் குறியீட்டைப் பயன்படுத்தவும்.';
      subtitle = 'இந்த குறியீடு <strong>10 நிமிடங்களுக்கு</strong> செல்லுபடியாகும்.';
      securityNote = 'இந்தக் குறியீட்டை யாருடனும் பகிர வேண்டாம். HelaService ஊழியர்கள் ஒருபோதும் உங்கள் குறியீட்டைக் கேட்க மாட்டார்கள்.';
      footer = 'நீங்கள் இந்தக் கோரிக்கையை விடுக்கவில்லை என்றால், இந்தப் பதிவை புறக்கணிக்கலாம்.';
    } else {
      subject = `Your HelaService verification code: ${otp}`;
      title = 'Verify Your Email Address';
      purposeDescription = 'Use this verification code to complete your new account registration.';
      subtitle = 'This code is valid for <strong>10 minutes</strong>.';
      securityNote = 'Never share this code with anyone. HelaService staff will never ask for your code.';
      footer = 'If you didn\'t request this verification code, you can safely ignore this email.';
    }
  }

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #FAF9F5; margin: 0; padding: 24px; }
        .container { max-width: 480px; margin: 0 auto; background: #FFFFFF; border: 1px solid #ECE6D9; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.03); }
        .header { background: #D6900F; padding: 24px; text-align: center; }
        .header h1 { color: #17140F; margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.5px; }
        .content { padding: 32px 28px; text-align: center; }
        .title { font-size: 18px; font-weight: 700; color: #17140F; margin: 0 0 10px 0; }
        .desc { font-size: 14px; color: #4A453A; margin: 0 0 8px 0; }
        .subtitle { font-size: 13px; color: #6B665B; line-height: 1.5; margin: 0 0 24px 0; }
        .otp-box { background: #FBF0DA; border: 2px dashed #D6900F; border-radius: 12px; padding: 18px; font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #17140F; margin: 0 auto 24px auto; display: inline-block; min-width: 240px; }
        .security { font-size: 12px; color: #6B665B; line-height: 1.5; margin: 0 0 16px 0; }
        .footer { font-size: 12px; color: #9A6206; line-height: 1.5; border-top: 1px solid #ECE6D9; padding-top: 16px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>HelaService</h1>
        </div>
        <div class="content">
          <h2 class="title">${title}</h2>
          <p class="desc">${purposeDescription}</p>
          <p class="subtitle">${subtitle}</p>
          <div class="otp-box">${otp}</div>
          <p class="security">${securityNote}</p>
          <div class="footer">${footer}</div>
        </div>
      </div>
    </body>
    </html>
  `;

  const text = `${purposeDescription}\n\nYour code: ${otp}\nValid for 10 minutes.\n\n${securityNote}\n${footer}`;

  return { subject, html, text };
}

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-helaservice-key');

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

  if (!userEmail) {
    return res.status(400).json({
      error: 'Authenticated account has no email address.',
      code: 'no_email',
    });
  }

  try {
    const { purpose = 'signup', language = 'en' } = req.body || {};

    if (purpose !== 'signup' && purpose !== 'admin_login') {
      return res.status(400).json({
        error: 'Invalid purpose. Must be "signup" or "admin_login".',
        code: 'invalid_purpose',
      });
    }

    // check if admin
    if (purpose === 'admin_login') {
      const superDoc = await db.collection('superAdmins').doc(callerUid).get();
      let isAdmin = superDoc.exists;
      if (!isAdmin) {
        const adminDoc = await db.collection('admins').doc(callerUid).get();
        if (adminDoc.exists && adminDoc.data() && adminDoc.data().status === 'active') {
          isAdmin = true;
        }
      }
      if (!isAdmin) {
        return res.status(403).json({
          error: 'Unauthorized: admin_login is only permitted for registered administrators.',
          code: 'not_admin',
        });
      }
    }

    const now = Date.now();
    const oneHourMs = 60 * 60 * 1000;

    // ip rate limit
    const forwardedHeader = req.headers['x-forwarded-for'];
    const clientIp = (typeof forwardedHeader === 'string' && forwardedHeader.trim().length > 0)
      ? forwardedHeader.split(',')[0].trim()
      : (req.socket?.remoteAddress || '127.0.0.1');

    const ipHash = crypto.createHash('sha256').update(clientIp).digest('hex');
    const ipRateLimitRef = db.collection('otp_rate_limits').doc(ipHash);
    const ipRateLimitDoc = await ipRateLimitRef.get();

    let ipCount = 0;
    let ipWindowStart = now;
    if (ipRateLimitDoc.exists) {
      const data = ipRateLimitDoc.data() || {};
      const win = data.windowStart || 0;
      if (now - win < oneHourMs) {
        ipCount = data.count || 0;
        ipWindowStart = win;
      }
    }

    if (ipCount >= 5) {
      const retryAfter = Math.ceil((ipWindowStart + oneHourMs - now) / 1000);
      return res.status(429).json({
        error: 'Too many OTP requests from this IP address. Please try again later.',
        code: 'rate_limited_ip',
        retryAfter,
      });
    }

    // user rate limit
    const uidRateLimitRef = db.collection('otp_rate_limits').doc(`uid_${callerUid}`);
    const uidRateLimitDoc = await uidRateLimitRef.get();

    let uidCount = 0;
    let uidWindowStart = now;
    if (uidRateLimitDoc.exists) {
      const data = uidRateLimitDoc.data() || {};
      const win = data.windowStart || 0;
      if (now - win < oneHourMs) {
        uidCount = data.count || 0;
        uidWindowStart = win;
      }
    }

    if (uidCount >= 5) {
      const retryAfter = Math.ceil((uidWindowStart + oneHourMs - now) / 1000);
      return res.status(429).json({
        error: 'Too many OTP requests for this account. Please wait before requesting another code.',
        code: 'rate_limited_uid',
        retryAfter,
      });
    }

    // check cooldown
    const sessionDocId = `otp_${callerUid}_${purpose}`;
    const sessionDocRef = db.collection('otp_verifications').doc(sessionDocId);
    const existingSession = await sessionDocRef.get();

    if (existingSession.exists) {
      const data = existingSession.data() || {};
      const timeSinceLast = now - (data.createdAt || 0);
      if (timeSinceLast < 60000) {
        const remainingSeconds = Math.ceil((60000 - timeSinceLast) / 1000);
        return res.status(429).json({
          error: `Please wait ${remainingSeconds} seconds before requesting a new verification code.`,
          code: 'cooldown',
          retryAfter: remainingSeconds,
        });
      }
    }

    // make code and salt
    const otp = crypto.randomInt(100000, 1000000).toString();
    const salt = crypto.randomBytes(16).toString('hex');
    const hashedOtp = crypto.createHash('sha256').update(salt + otp).digest('hex');
    const expiresAt = now + 10 * 60 * 1000; // ten minutes

    // save session doc
    await sessionDocRef.set({
      uid: callerUid,
      email: userEmail,
      purpose,
      salt,
      hashedOtp,
      createdAt: now,
      expiresAt,
      attempts: 0,
    });

    // update limits
    await Promise.all([
      ipRateLimitRef.set({ count: ipCount + 1, windowStart: ipWindowStart, updatedAt: now }),
      uidRateLimitRef.set({ count: uidCount + 1, windowStart: uidWindowStart, updatedAt: now }),
    ]);

    // track quota
    const todayStr = new Date().toISOString().slice(0, 10);
    const dailyQuotaRef = db.collection('system_metrics').doc(`gmail_${todayStr}`);
    const dailyQuotaDoc = await dailyQuotaRef.get();
    const sentToday = (dailyQuotaDoc.exists ? (dailyQuotaDoc.data().count || 0) : 0) + 1;
    await dailyQuotaRef.set({ count: sentToday, updatedAt: now }, { merge: true }).catch(() => {});

    if (sentToday >= 450) {
      console.warn(`[Gmail Quota Warning] Sent ${sentToday} emails on ${todayStr}. Approaching Gmail 500/day limit.`);
    }

    // send email
    const templates = getEmailTemplates({ otp, purpose, language });

    try {
      await transporter.sendMail({
        from: `"HelaService" <${process.env.GMAIL_USER}>`,
        to: userEmail,
        subject: templates.subject,
        text: templates.text,
        html: templates.html,
      });
    } catch (mailErr) {
      console.error('[send-otp Mail Error]', mailErr);
      return res.status(500).json({
        error: 'Failed to send verification email. Please try again.',
        code: 'email_send_failed',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'OTP sent successfully',
      expiresAt,
      expiresInSeconds: 600,
      resendAfterSeconds: 60,
    });
  } catch (error) {
    console.error('[send-otp Error]', error);
    return res.status(500).json({
      error: 'Failed to process verification code request.',
      code: 'server_error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};
