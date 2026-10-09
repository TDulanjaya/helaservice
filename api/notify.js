const { admin, db } = require('./_firebase');
const { verifyFirebaseToken } = require('./_auth');

// localized templates for notifications
const templates = {
  booking_created: {
    en: { title: 'New Booking Request', body: 'A customer sent you a new service booking request.' },
    si: { title: 'නව සේවා ඉල්ලීමක්', body: 'පාරිභෝගිකයෙකු ඔබට නව සේවා වෙන්කිරීමක් යොමු කර ඇත.' },
    ta: { title: 'புதிய முன்பதிவு கோரிக்கை', body: 'ஒரு வாடிக்கையாளர் புதிய சேவை முன்பதிவு கோரிக்கையை அனுப்பியுள்ளார்.' },
  },
  booking_confirmed: {
    en: { title: 'Booking Confirmed', body: 'Your service provider confirmed the appointment.' },
    si: { title: 'සේවාව තහවුරු විය', body: 'ඔබගේ සේවා ශිල්පියා සේවා ඇණවුම තහවුරු කර ඇත.' },
    ta: { title: 'முன்பதிவு உறுதிப்படுத்தப்பட்டது', body: 'உங்கள் சேவை வழங்குநர் முன்பதிவை உறுதிப்படுத்தினார்.' },
  },
  booking_declined: {
    en: { title: 'Booking Declined', body: 'The provider is unavailable for this booking.' },
    si: { title: 'ඉල්ලීම ප්‍රතික්ෂේප විය', body: 'ශිල්පියා මෙම අවස්ථාවේ ලබාගත නොහැක.' },
    ta: { title: 'முன்பதிவு நிராகரிக்கப்பட்டது', body: 'வழங்குநர் தற்போது கிடைக்கவில்லை.' },
  },
  booking_en_route: {
    en: { title: 'Technician En Route', body: 'Your service provider is travelling to your location.' },
    si: { title: 'සේවා ශිල්පියා පැමිණෙමින් සිටී', body: 'ඔබගේ සේවා ශිල්පියා ඔබගේ ස්ථානයට පැමිණෙමින් සිටී.' },
    ta: { title: 'தொழில்நுட்ப வல்லுநர் வழியில் உள்ளார்', body: 'உங்கள் சேவை வழங்குநர் உங்கள் இருப்பிடத்திற்கு வழியில் உள்ளார்.' },
  },
  booking_arrived: {
    en: { title: 'Technician Arrived', body: 'Your service provider has arrived on site.' },
    si: { title: 'සේවා ශිල්පියා පැමිණ ඇත', body: 'ඔබගේ සේවා ශිල්පියා ඔබගේ ස්ථානයට පැමිණ ඇත.' },
    ta: { title: 'தொழில்நுட்ப வல்லுநர் வந்துவிட்டார்', body: 'உங்கள் சேவை வழங்குநர் வந்துவிட்டார்.' },
  },
  booking_completed: {
    en: { title: 'Job Completed', body: 'Service has been marked completed. Please rate the provider.' },
    si: { title: 'සේවාව නිම කරන ලදී', body: 'සේවාව සාර්ථකව අවසන් විය. කරුණාකර ශිල්පියාව අගයන්න.' },
    ta: { title: 'பணி முடிந்தது', body: 'சேவை முடிந்தது. வழங்குநரை மதிப்பிடவும்.' },
  },
  booking_cancelled: {
    en: { title: 'Booking Cancelled', body: 'The booking was cancelled.' },
    si: { title: 'සේවාව අවලංගු විය', body: 'සේවා වෙන්කිරීම අවලංගු කරන ලදී.' },
    ta: { title: 'முன்பதிவு ரத்து செய்யப்பட்டது', body: 'முன்பதிவு ரத்து செய்யப்பட்டது.' },
  },
  payment_recorded: {
    en: { title: 'Payment Recorded', body: 'Provider recorded payment. Please confirm in app.' },
    si: { title: 'ගෙවීම සටහන් විය', body: 'ගෙවීම් මුදල සටහන් කර ඇත. කරුණාකර තහවුරු කරන්න.' },
    ta: { title: 'கட்டணம் பதிவு செய்யப்பட்டது', body: 'கட்டணம் பதிவு செய்யப்பட்டது. உறுதிப்படுத்தவும்.' },
  },
  payment_confirmed: {
    en: { title: 'Payment Confirmed', body: 'Customer confirmed the cash payment.' },
    si: { title: 'ගෙවීම තහවුරු විය', body: 'පාරිභෝගිකයා මුදල් ගෙවීම තහවුරු කළේය.' },
    ta: { title: 'கட்டணம் உறுதிப்படுத்தப்பட்டது', body: 'வாடிக்கையாளர் கட்டணத்தை உறுதிப்படுத்தினார்.' },
  },
  payment_disputed: {
    en: { title: 'Payment Disputed', body: 'Customer disputed the payment amount.' },
    si: { title: 'ගෙවීම පිළිබඳ ගැටළුවක්', body: 'පාරිභෝගිකයා ගෙවීම් මුදල පිළිබඳ ගැටළුවක් යොමු කළේය.' },
    ta: { title: 'கட்டணம் சர்ச்சை', body: 'வாடிக்கையாளர் கட்டணத் தொகையை மறுத்துள்ளார்.' },
  },
  reschedule_requested: {
    en: { title: 'Reschedule Requested', body: 'A new appointment time was proposed.' },
    si: { title: 'වේලාව වෙනස් කිරීමේ ඉල්ලීමක්', body: 'නව සේවා වේලාවක් යෝජනා කර ඇත.' },
    ta: { title: 'மறுஅட்டவணை கோரிக்கை', body: 'புதிய நேரம் முன்மொழியப்பட்டது.' },
  },
  reschedule_accepted: {
    en: { title: 'Reschedule Accepted', body: 'The proposed appointment time was accepted.' },
    si: { title: 'යෝජිත වේලාව පිළිගැනිණි', body: 'යෝජිත නව වේලාව පිළිගන්නා ලදී.' },
    ta: { title: 'மறுஅட்டவணை ஏற்றுக்கொள்ளப்பட்டது', body: 'முன்மொழியப்பட்ட நேரம் ஏற்றுக்கொள்ளப்பட்டது.' },
  },
  reschedule_declined: {
    en: { title: 'Reschedule Declined', body: 'The proposed appointment time was declined.' },
    si: { title: 'යෝජිත වේලාව ප්‍රතික්ෂේප විය', body: 'යෝජිත නව වේලාව ප්‍රතික්ෂේප විය.' },
    ta: { title: 'மறுஅட்டවணை நிராகரிக்கப்பட்டது', body: 'முன்மொழியப்பட்ட நேரம் நிராகரிக்கப்பட்டது.' },
  },
  quote_received: {
    en: { title: 'New Quote Received', body: 'A technician submitted a quote for your request.' },
    si: { title: 'නව මිල ගණන් ලැබුණි', body: 'කාර්මික ශිල්පියෙකු ඔබේ රැකියාව සඳහා මිලක් ඉදිරිපත් කර ඇත.' },
    ta: { title: 'புதிய விலைப்புள்ளி பெறப்பட்டது', body: 'தொழில்நுட்ப வல்லுநர் ஒரு விலைப்புள்ளியை சமர்ப்பித்துள்ளார்.' },
  },
  quote_accepted: {
    en: { title: 'Quote Accepted', body: 'The customer accepted your quote. Please proceed.' },
    si: { title: 'මිල ගණන් පිළිගැනිණි', body: 'පාරිභෝගිකයා ඔබේ මිල පිළිගෙන ඇත. කරුණාකර ඉදිරියට යන්න.' },
    ta: { title: 'விலைப்புள்ளி ஏற்றுக்கொள்ளப்பட்டது', body: 'வாடிக்கையாளர் உங்கள் விலைப்புள்ளியை ஏற்றுக்கொண்டார்.' },
  },
  chat_message: {
    en: { title: 'New Message', body: 'You received a new chat message.' },
    si: { title: 'නව පණිවිඩයක්', body: 'ඔබට නව පණිවිඩයක් ලැබී ඇත.' },
    ta: { title: 'புதிய செய்தி', body: 'உங்களுக்கு புதிய செய்தி வந்துள்ளது.' },
  },
};

// handle notification request with strict caller verification and server side templates
module.exports = async function handler(req, res) {
  // allow cors headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // require valid firebase auth session token
  const decodedUser = await verifyFirebaseToken(req, res);
  if (!decodedUser) return;
  const callerUid = decodedUser.uid;

  const { event, docId } = req.body || {};

  if (!event || !docId || typeof event !== 'string' || typeof docId !== 'string') {
    return res.status(400).json({ error: 'event and docId are required string fields' });
  }

  try {
    let recipientUid = null;
    let metadata = { docId, event };

    if (
      event.startsWith('booking_') ||
      event.startsWith('payment_') ||
      event.startsWith('reschedule_')
    ) {
      const bSnap = await db.collection('bookings').doc(docId).get();
      if (!bSnap.exists) {
        return res.status(404).json({ error: 'Booking not found' });
      }
      const b = bSnap.data() || {};
      const custId = b.customerId;
      const provId = b.providerId;

      if (event === 'booking_created') {
        if (callerUid !== custId) return res.status(403).json({ error: 'Unauthorized event actor' });
        recipientUid = provId;
      } else if (
        event === 'booking_confirmed' ||
        event === 'booking_declined' ||
        event === 'booking_en_route' ||
        event === 'booking_arrived' ||
        event === 'booking_completed' ||
        event === 'payment_recorded'
      ) {
        if (callerUid !== provId) return res.status(403).json({ error: 'Unauthorized event actor' });
        recipientUid = custId;
      } else if (event === 'booking_cancelled') {
        if (callerUid !== custId && callerUid !== provId) {
          return res.status(403).json({ error: 'Unauthorized event actor' });
        }
        recipientUid = callerUid === custId ? provId : custId;
      } else if (event === 'payment_confirmed' || event === 'payment_disputed') {
        if (callerUid !== custId) return res.status(403).json({ error: 'Unauthorized event actor' });
        recipientUid = provId;
      } else if (event === 'reschedule_requested') {
        if (callerUid !== b.rescheduleRequestedBy && callerUid !== custId && callerUid !== provId) {
          return res.status(403).json({ error: 'Unauthorized event actor' });
        }
        recipientUid = callerUid === custId ? provId : custId;
      } else if (event === 'reschedule_accepted' || event === 'reschedule_declined') {
        if (callerUid !== custId && callerUid !== provId) {
          return res.status(403).json({ error: 'Unauthorized event actor' });
        }
        recipientUid = callerUid === custId ? provId : custId;
      }
      metadata.bookingId = docId;
    } else if (event === 'quote_received') {
      const jobSnap = await db.collection('jobRequests').doc(docId).get();
      if (!jobSnap.exists) {
        return res.status(404).json({ error: 'Job request not found' });
      }
      const job = jobSnap.data() || {};
      recipientUid = job.customerId;
      metadata.jobRequestId = docId;
    } else if (event === 'quote_accepted') {
      const jobSnap = await db.collection('jobRequests').doc(docId).get();
      if (!jobSnap.exists) {
        return res.status(404).json({ error: 'Job request not found' });
      }
      const job = jobSnap.data() || {};
      if (callerUid !== job.customerId) {
        return res.status(403).json({ error: 'Unauthorized event actor' });
      }
      recipientUid = job.selectedProviderId;
      metadata.jobRequestId = docId;
    } else if (event === 'chat_message') {
      const chatSnap = await db.collection('chatRooms').doc(docId).get();
      if (!chatSnap.exists) {
        return res.status(404).json({ error: 'Chat room not found' });
      }
      const chat = chatSnap.data() || {};
      const parts = Array.isArray(chat.participants) ? chat.participants : [];
      if (!parts.includes(callerUid)) {
        return res.status(403).json({ error: 'Unauthorized event actor' });
      }
      recipientUid = parts.find((p) => p !== callerUid);
      metadata.chatRoomId = docId;
    } else {
      return res.status(400).json({ error: 'Unknown event type' });
    }

    if (!recipientUid) {
      return res.status(400).json({ error: 'Recipient could not be determined' });
    }

    // fetch recipient language preference
    let lang = 'en';
    const userDoc = await db.collection('users').doc(recipientUid).get();
    if (userDoc.exists) {
      const data = userDoc.data();
      if (data && data.preferredLanguage) {
        const rawLang = String(data.preferredLanguage).toLowerCase();
        if (rawLang === 'si' || rawLang === 'sinhala') lang = 'si';
        if (rawLang === 'ta' || rawLang === 'tamil') lang = 'ta';
      }
    }

    const entry = (templates[event] && (templates[event][lang] || templates[event].en)) || {
      title: 'HelaService Notification',
      body: 'You have a new update.',
    };

    const title = entry.title;
    const body = entry.body;

    // write notification document to user subcollection
    const notifRef = db.collection('users').doc(recipientUid).collection('notifications').doc();
    await notifRef.set({
      id: notifRef.id,
      recipientUid,
      eventType: event,
      title,
      body,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      ...metadata,
    });

    // deliver fcm push tokens
    const tokenSnap = await db.collection('users').doc(recipientUid).collection('fcmTokens').get();
    const tokens = [];
    tokenSnap.forEach((doc) => {
      const tData = doc.data();
      if (tData && tData.token) tokens.push(tData.token);
    });

    if (tokens.length > 0 && admin.messaging) {
      const payload = {
        notification: { title, body },
        data: {
          notificationId: notifRef.id,
          event,
          docId,
        },
        tokens,
      };

      try {
        const response = await admin.messaging().sendEachForMulticast(payload);
        const cleanupPromises = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success && resp.error) {
            const errCode = resp.error.code;
            if (
              errCode === 'messaging/invalid-registration-token' ||
              errCode === 'messaging/registration-token-not-registered'
            ) {
              cleanupPromises.push(tokenSnap.docs[idx].ref.delete());
            }
          }
        });
        if (cleanupPromises.length > 0) {
          await Promise.all(cleanupPromises);
        }
      } catch (fcmErr) {
        console.error('fcm note:', fcmErr);
      }
    }

    return res.status(200).json({
      success: true,
      notificationId: notifRef.id,
      title,
      body,
      language: lang,
    });
  } catch (err) {
    console.error('Notification error:', err);
    return res.status(500).json({ error: err.message || 'Notification error' });
  }
};
