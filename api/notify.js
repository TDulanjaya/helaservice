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
  price_proposed: {
    en: { title: 'Price Proposal', body: 'The technician sent a price confirmation for the job.' },
    si: { title: 'මිල යෝජනාවක්', body: 'කාර්මික ශිල්පියා කාර්යය සඳහා මිල තහවුරු කිරීමක් එවා ඇත.' },
    ta: { title: 'விலை முன்மொழிவு', body: 'தொழில்நுட்ப வல்லுநர் பணிக்கான விலை உறுதிப்படுத்தலை அனுப்பியுள்ளார்.' },
  },
  price_responded: {
    en: { title: 'Price Response', body: 'The customer responded to your price proposal.' },
    si: { title: 'මිල ප්‍රතිචාරය', body: 'පාරිභෝගිකයා ඔබේ මිල යෝජනාවට ප්‍රතිචාර දැක්වීය.' },
    ta: { title: 'விலை பதில்', body: 'வாடிக்கையாளர் உங்கள் விலை முன்மொழிவுக்கு பதிலளித்துள்ளார்.' },
  },
  extra_requested: {
    en: { title: 'Extra Work Requested', body: 'The technician requested approval for extra work.' },
    si: { title: 'අමතර වැඩ ඉල්ලීමක්', body: 'කාර්මික ශිල්පියා අමතර කාර්යයක් සඳහා අනුමැතිය ඉල්ලා ඇත.' },
    ta: { title: 'கூடுதல் பணி கோரப்பட்டது', body: 'தொழில்நுட்ப வல்லுநர் கூடுதல் பணிக்கு ஒப்புதல் கோரியுள்ளார்.' },
  },
  extra_responded: {
    en: { title: 'Extra Work Response', body: 'The customer responded to the extra work request.' },
    si: { title: 'අමතර වැඩ ප්‍රතිචාරය', body: 'පාරිභෝගිකයා අමතර කාර්යයේ ඉල්ලීමට ප්‍රතිචාර දැක්වීය.' },
    ta: { title: 'கூடுதல் பணி பதில்', body: 'வாடிக்கையாளர் கூடுதல் பணி கோரிக்கைக்கு பதிலளித்துள்ளார்.' },
  },
  arrival_claimed: {
    en: { title: 'Provider Arrived', body: 'Technician is at your location. Please confirm their arrival.' },
    si: { title: 'සේවා ශිල්පියා පැමිණ ඇත', body: 'සේවා ශිල්පියා ඔබගේ ස්ථානයට පැමිණ ඇත. කරුණාකර තහවුරු කරන්න.' },
    ta: { title: 'தொழில்நுட்ப வல்லுநர் வந்துவிட்டார்', body: 'தொழில்நுட்ப வல்லுநர் உங்கள் இடத்தில் உள்ளார். வருகையை உறுதிப்படுத்தவும்.' },
  },
  arrival_confirmed: {
    en: { title: 'Arrival Confirmed', body: 'Customer confirmed you have arrived. You may start work.' },
    si: { title: 'පැමිණීම තහවුරු විය', body: 'පාරිභෝගිකයා ඔබගේ පැමිණීම තහවුරු කළේය. වැඩ ආරම්භ කළ හැක.' },
    ta: { title: 'வருகை உறுதிப்படுத்தப்பட்டது', body: 'வாடிக்கையாளர் உங்கள் வருகையை உறுதிப்படுத்தினார்.' },
  },
  arrival_denied: {
    en: { title: 'Arrival Denied', body: 'Customer stated you have not arrived yet. Please call them.' },
    si: { title: 'පැමිණීම ප්‍රතික්ෂේප විය', body: 'ඔබ තවමත් පැමිණ නැති බව පාරිභෝගිකයා ප්‍රකාශ කර ඇත. කරුණාකර ඔවුන් අමතන්න.' },
    ta: { title: 'வருகை மறுக்கப்பட்டது', body: 'நீங்கள் இன்னும் வரவில்லை என்று வாடிக்கையாளர் தெரிவித்துள்ளார்.' },
  },
  arrival_auto_started: {
    en: { title: 'Job Started', body: 'Job started automatically after arrival GPS verification.' },
    si: { title: 'වැඩ ආරම්භ විය', body: 'GPS තහවුරු කිරීමෙන් පසු කාර්යය ස්වයංක්‍රීයව ආරම්භ විය.' },
    ta: { title: 'பணி தொடங்கியது', body: 'GPS சரிபார்ப்பிற்குப் பிறகு பணி தானாகவே தொடங்கியது.' },
  },
  no_show_reported: {
    en: { title: 'Booking Cancelled', body: 'Customer reported you did not arrive and cancelled the booking.' },
    si: { title: 'සේවාව අවලංගු විය', body: 'ඔබ පැමිණියේ නැති බව වාර්තා කර පාරිභෝගිකයා සේවාව අවලංගු කළේය.' },
    ta: { title: 'முன்பதிவு ரத்து செய்யப்பட்டது', body: 'நீங்கள் வரவில்லை என்று வாடிக்கையாளர் முன்பதிவை ரத்து செய்தார்.' },
  },
  support_ticket_created: {
    en: { title: 'New Support Ticket', body: 'A customer or provider submitted a support request.' },
    si: { title: 'නව සහාය ඉල්ලීමක්', body: 'පාරිභෝගිකයෙකු හෝ ශිල්පියෙකු සහාය ඉල්ලීමක් යොමු කර ඇත.' },
    ta: { title: 'புதிய ஆதரவு கோரிக்கை', body: 'ஒரு புதிய ஆதரவு கோரிக்கை சமர்ப்பிக்கப்பட்டுள்ளது.' },
  },
  support_admin_reply: {
    en: { title: 'Support Reply', body: 'Support replied to your ticket.' },
    si: { title: 'සහාය පිළිතුරක්', body: 'ඔබගේ සහාය ඉල්ලීමට පිළිතුරක් ලැබී ඇත.' },
    ta: { title: 'ஆதரவு பதில்', body: 'உங்கள் ஆதரவு கோரிக்கைக்கு ஒரு பதில் வந்துள்ளது.' },
  },
  support_ticket_resolved: {
    en: { title: 'Ticket Resolved', body: 'Your support ticket has been resolved.' },
    si: { title: 'ඉල්ලීම විසඳන ලදී', body: 'ඔබගේ සහාය ඉල්ලීම සාර්ථකව විසඳා ඇත.' },
    ta: { title: 'கோரிக்கை தீர்க்கப்பட்டது', body: 'உங்கள் ஆதரவு கோரிக்கை தீர்க்கப்பட்டது.' },
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
      event.startsWith('reschedule_') ||
      event.startsWith('price_') ||
      event.startsWith('extra_') ||
      event.startsWith('arrival_') ||
      event === 'no_show_reported'
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
      } else if (event === 'price_proposed') {
        if (callerUid !== provId) return res.status(403).json({ error: 'Unauthorized event actor' });
        recipientUid = custId;
      } else if (event === 'price_responded') {
        if (callerUid !== custId) return res.status(403).json({ error: 'Unauthorized event actor' });
        recipientUid = provId;
      } else if (event === 'extra_requested') {
        if (callerUid !== provId) return res.status(403).json({ error: 'Unauthorized event actor' });
        recipientUid = custId;
      } else if (event === 'extra_responded') {
        if (callerUid !== custId) return res.status(403).json({ error: 'Unauthorized event actor' });
        recipientUid = provId;
      } else if (event === 'arrival_claimed' || event === 'arrival_auto_started') {
        if (callerUid !== provId) return res.status(403).json({ error: 'Unauthorized event actor' });
        recipientUid = custId;
      } else if (event === 'arrival_confirmed' || event === 'arrival_denied' || event === 'no_show_reported') {
        if (callerUid !== custId) return res.status(403).json({ error: 'Unauthorized event actor' });
        recipientUid = provId;
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
    } else if (event === 'support_ticket_created') {
      const ticketSnap = await db.collection('complaints').doc(docId).get();
      if (!ticketSnap.exists) {
        return res.status(404).json({ error: 'Support ticket not found' });
      }
      const ticket = ticketSnap.data() || {};
      if (callerUid !== ticket.reporterUid && callerUid !== ticket.customerId) {
        return res.status(403).json({ error: 'Unauthorized event actor' });
      }
      metadata.complaintId = docId;
      metadata.ticketType = ticket.type || 'help';

      // find active admins with handle_support or super admins (up to 20)
      const adminList = [];
      const superSnap = await db.collection('superAdmins').limit(10).get();
      superSnap.forEach((d) => adminList.push(d.id));

      const staffSnap = await db.collection('admins').where('status', '==', 'active').limit(20).get();
      staffSnap.forEach((d) => {
        const dData = d.data() || {};
        const perms = Array.isArray(dData.permissions) ? dData.permissions : [];
        if (perms.includes('handle_support') && !adminList.includes(d.id)) {
          adminList.push(d.id);
        }
      });

      const targets = adminList.slice(0, 20);
      let sentCount = 0;
      for (const aUid of targets) {
        const notifRef = db.collection('users').doc(aUid).collection('notifications').doc();
        await notifRef.set({
          id: notifRef.id,
          recipientUid: aUid,
          eventType: event,
          title: templates[event].en.title,
          body: templates[event].en.body,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          ...metadata,
        });
        sentCount++;
      }

      return res.status(200).json({
        success: true,
        sentToAdmins: sentCount,
      });
    } else if (event === 'support_admin_reply' || event === 'support_ticket_resolved') {
      const ticketSnap = await db.collection('complaints').doc(docId).get();
      if (!ticketSnap.exists) {
        return res.status(404).json({ error: 'Support ticket not found' });
      }
      const ticket = ticketSnap.data() || {};

      // verify caller is authorized admin
      const isSuper = (await db.collection('superAdmins').doc(callerUid).get()).exists;
      let isAuthorized = isSuper;
      if (!isAuthorized) {
        const aDoc = await db.collection('admins').doc(callerUid).get();
        if (aDoc.exists && aDoc.data()?.status === 'active') {
          const perms = Array.isArray(aDoc.data().permissions) ? aDoc.data().permissions : [];
          if (perms.includes('handle_support')) isAuthorized = true;
        }
      }
      if (!isAuthorized) {
        return res.status(403).json({ error: 'Admin handle_support permission required' });
      }

      recipientUid = ticket.reporterUid || ticket.customerId;
      metadata.complaintId = docId;
      metadata.ticketType = ticket.type || 'help';
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
      const userLang = data?.language || data?.preferredLanguage;
      if (userLang) {
        const rawLang = String(userLang).toLowerCase();
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
