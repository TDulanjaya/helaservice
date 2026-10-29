const { admin, db } = require('./_firebase');
const { verifyFirebaseToken } = require('./_auth');

// localized templates for notifications
const templates = {
  booking_created: {
    en: { title: 'New Booking Request', body: 'A customer sent you a new service booking request.' },
    si: { title: 'නව සේවා ඉල්ලීමක්', body: 'පාරිභෝගිකයෙකු ඔබට නව වෙන්කිරීමක් එවා ඇත.' },
    ta: { title: 'புதிய முன்பதிவு கோரிக்கை', body: 'ஒரு வாடிக்கையாளர் புதிய சேவை முன்பதிவு கோரிக்கையை அனுப்பியுள்ளார்.' },
  },
  booking_confirmed: {
    en: { title: 'Booking Confirmed', body: 'Your service provider confirmed the appointment.' },
    si: { title: 'වෙන්කිරීම තහවුරුයි', body: 'ඔබගේ සේවා සපයන්නා වෙන්කිරීම තහවුරු කළා.' },
    ta: { title: 'முன்பதிவு உறுதிப்படுத்தப்பட்டது', body: 'உங்கள் சேவை வழங்குநர் முன்பதிவை உறுதிப்படுத்தினார்.' },
  },
  booking_declined: {
    en: { title: 'Booking Declined', body: 'The provider is unavailable for this booking.' },
    si: { title: 'ඉල්ලීම ප්‍රතික්ෂේප විය', body: 'සේවා සපයන්නාට මෙම වෙලාවට පැමිණිය නොහැක.' },
    ta: { title: 'முன்பதிவு நிராகரிக்கப்பட்டது', body: 'வழங்குநர் தற்போது கிடைக்கவில்லை.' },
  },
  booking_en_route: {
    en: { title: 'Technician En Route', body: 'Your service provider is travelling to your location.' },
    si: { title: 'සේවා සපයන්නා එමින් සිටී', body: 'ඔබගේ සේවා සපයන්නා ඔබගේ ස්ථානයට එමින් සිටී.' },
    ta: { title: 'தொழில்நுட்ப வல்லுநர் வழியில் உள்ளார்', body: 'உங்கள் சேவை வழங்குநர் உங்கள் இருப்பிடத்திற்கு வழியில் உள்ளார்.' },
  },
  booking_completed: {
    en: { title: 'Job Completed', body: 'Service has been marked completed. Please rate the provider.' },
    si: { title: 'වැඩය අවසන්', body: 'වැඩය අවසන් කළා. සේවා සපයන්නා අගයන්න.' },
    ta: { title: 'பணி முடிந்தது', body: 'சேவை முடிந்தது. வழங்குநரை மதிப்பிடவும்.' },
  },
  booking_cancelled: {
    en: { title: 'Booking Cancelled', body: 'The booking was cancelled.' },
    si: { title: 'සේවාව අවලංගු විය', body: 'සේවා වෙන්කිරීම අවලංගු කරන ලදී.' },
    ta: { title: 'முன்பதிவு ரத்து செய்யப்பட்டது', body: 'முன்பதிவு ரத்து செய்யப்பட்டது.' },
  },
  payment_recorded: {
    en: { title: 'Payment Recorded', body: 'Provider recorded payment. Please confirm in app.' },
    si: { title: 'ගෙවීම සටහන් විය', body: 'සේවා සපයන්නා ගෙවීම සටහන් කළා. යෙදුමේ තහවුරු කරන්න.' },
    ta: { title: 'கட்டணம் பதிவு செய்யப்பட்டது', body: 'கட்டணம் பதிவு செய்யப்பட்டது. உறுதிப்படுத்தவும்.' },
  },
  payment_confirmed: {
    en: { title: 'Payment Confirmed', body: 'Customer confirmed the cash payment.' },
    si: { title: 'ගෙවීම තහවුරු විය', body: 'පාරිභෝගිකයා මුදල් ගෙවීම තහවුරු කළේය.' },
    ta: { title: 'கட்டணம் உறுதிப்படுத்தப்பட்டது', body: 'வாடிக்கையாளர் கட்டணத்தை உறுதிப்படுத்தினார்.' },
  },
  payment_disputed: {
    en: { title: 'Payment Disputed', body: 'Customer disputed the payment amount.' },
    si: { title: 'ගෙවීම පිළිබඳ ගැටළුවක්', body: 'පාරිභෝගිකයා ගෙවීමේ මුදල ගැන ගැටලුවක් කීවා.' },
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
    si: { title: 'නව මිල ගණන් ලැබුණි', body: 'සේවා සපයන්නෙකු ඔබේ වැඩයට මිලක් එවා ඇත.' },
    ta: { title: 'புதிய விலைப்புள்ளி பெறப்பட்டது', body: 'தொழில்நுட்ப வல்லுநர் ஒரு விலைப்புள்ளியை சமர்ப்பித்துள்ளார்.' },
  },
  quote_accepted: {
    en: { title: 'Quote Accepted', body: 'The customer accepted your quote. Please proceed.' },
    si: { title: 'මිල පිළිගත්තා', body: 'පාරිභෝගිකයා ඔබේ මිල පිළිගත්තා.' },
    ta: { title: 'விலைப்புள்ளி ஏற்றுக்கொள்ளப்பட்டது', body: 'வாடிக்கையாளர் உங்கள் விலைப்புள்ளியை ஏற்றுக்கொண்டார்.' },
  },
  quote_not_selected: {
    en: { title: 'Quote Not Selected', body: 'The customer selected another quote for this job.' },
    si: { title: 'මිල ගණන් තෝරා නොගැනුණි', body: 'පාරිභෝගිකයා මෙම වැඩය සඳහා වෙනත් මිල ගණන් තෝරාගන්නා ලදී.' },
    ta: { title: 'மதிப்பீடு தேர்ந்தெடுக்கப்படவில்லை', body: 'வாடிக்கையாளர் இந்த வேலைக்கு மற்றொரு மதிப்பீட்டைத் தேர்ந்தெடுத்துள்ளார்.' },
  },
  job_closed: {
    en: { title: 'Job no longer available', body: 'The job request has been closed or cancelled.' },
    si: { title: 'වැඩය තවදුරටත් ලබා ගත නොහැක', body: 'මෙම වැඩය අවලංගු කර හෝ අවසන් කරන ලදී.' },
    ta: { title: 'வேலை இனி கிடைக்காது', body: 'வேலை கோரிக்கை மூடப்பட்டது அல்லது ரத்து செய்யப்பட்டது.' },
  },
  job_updated: {
    en: { title: 'Job Updated', body: 'The customer updated the job details. Review your quote.' },
    si: { title: 'වැඩය යාවත්කාලීන විය', body: 'පාරිභෝගිකයා වැඩයේ විස්තර යාවත්කාලීන කළේය. ඔබගේ මිල පරීක්ෂා කරන්න.' },
    ta: { title: 'வேலை புதுப்பிக்கப்பட்டது', body: 'வாடிக்கையாளர் வேலை விவரங்களை மாற்றியுள்ளார். உங்கள் மதிப்பீட்டை மதிப்பாய்வு செய்யவும்.' },
  },
  chat_message: {
    en: { title: 'New Message', body: 'You received a new chat message.' },
    si: { title: 'නව පණිවිඩයක්', body: 'ඔබට නව පණිවිඩයක් ලැබී ඇත.' },
    ta: { title: 'புதிய செய்தி', body: 'உங்களுக்கு புதிய செய்தி வந்துள்ளது.' },
  },
  price_proposed: {
    en: { title: 'Price Proposal', body: 'The technician sent a price confirmation for the job.' },
    si: { title: 'මිල යෝජනාවක්', body: 'සේවා සපයන්නා වැඩයේ අවසන් මිල එවා ඇත.' },
    ta: { title: 'விலை முன்மொழிவு', body: 'தொழில்நுட்ப வல்லுநர் பணிக்கான விலை உறுதிப்படுத்தலை அனுப்பியுள்ளார்.' },
  },
  price_responded: {
    en: { title: 'Price Response', body: 'The customer responded to your price proposal.' },
    si: { title: 'මිල ප්‍රතිචාරය', body: 'පාරිභෝගිකයා ඔබේ මිල යෝජනාවට ප්‍රතිචාර දැක්වීය.' },
    ta: { title: 'விலை பதில்', body: 'வாடிக்கையாளர் உங்கள் விலை முன்மொழிவுக்கு பதிலளித்துள்ளார்.' },
  },
  extra_requested: {
    en: { title: 'Extra Work Requested', body: 'The technician requested approval for extra work.' },
    si: { title: 'අමතර වැඩ ඉල්ලීමක්', body: 'සේවා සපයන්නා අමතර වැඩකට අනුමැතිය ඉල්ලා ඇත.' },
    ta: { title: 'கூடுதல் பணி கோரப்பட்டது', body: 'தொழில்நுட்ப வல்லுநர் கூடுதல் பணிக்கு ஒப்புதல் கோரியுள்ளார்.' },
  },
  extra_responded: {
    en: { title: 'Extra Work Response', body: 'The customer responded to the extra work request.' },
    si: { title: 'අමතර වැඩ ප්‍රතිචාරය', body: 'පාරිභෝගිකයා අමතර වැඩ ඉල්ලීමට පිළිතුරු දුන්නා.' },
    ta: { title: 'கூடுதல் பணி பதில்', body: 'வாடிக்கையாளர் கூடுதல் பணி கோரிக்கைக்கு பதிலளித்துள்ளார்.' },
  },
  arrival_claimed: {
    en: { title: 'Provider Arrived', body: 'Technician is at your location. Please confirm their arrival.' },
    si: { title: 'සේවා සපයන්නා පැමිණියා', body: 'සේවා සපයන්නා ඔබගේ ස්ථානයට පැමිණියා. තහවුරු කරන්න.' },
    ta: { title: 'தொழில்நுட்ப வல்லுநர் வந்துவிட்டார்', body: 'தொழில்நுட்ப வல்லுநர் உங்கள் இடத்தில் உள்ளார். வருகையை உறுதிப்படுத்தவும்.' },
  },
  arrival_confirmed: {
    en: { title: 'Arrival Confirmed', body: 'Customer confirmed you have arrived. You may start work.' },
    si: { title: 'පැමිණීම තහවුරු විය', body: 'පාරිභෝගිකයා ඔබගේ පැමිණීම තහවුරු කළේය. වැඩ ආරම්භ කළ හැක.' },
    ta: { title: 'வருகை உறுதிப்படுத்தப்பட்டது', body: 'வாடிக்கையாளர் உங்கள் வருகையை உறுதிப்படுத்தினார்.' },
  },
  arrival_denied: {
    en: { title: 'Arrival Denied', body: 'Customer stated you have not arrived yet. Please call them.' },
    si: { title: 'පැමිණීම ප්‍රතික්ෂේප විය', body: 'ඔබ තවම පැමිණ නැති බව පාරිභෝගිකයා කීවා. ඔවුන් අමතන්න.' },
    ta: { title: 'வருகை மறுக்கப்பட்டது', body: 'நீங்கள் இன்னும் வரவில்லை என்று வாடிக்கையாளர் தெரிவித்துள்ளார்.' },
  },
  arrival_auto_started: {
    en: { title: 'Job Started', body: 'Job started automatically after arrival GPS verification.' },
    si: { title: 'වැඩ ආරම්භ විය', body: 'GPS තහවුරු වූ පසු වැඩය ස්වයංක්රීයව ආරම්භ විය.' },
    ta: { title: 'பணி தொடங்கியது', body: 'GPS சரிபார்ப்பிற்குப் பிறகு பணி தானாகவே தொடங்கியது.' },
  },
  no_show_reported: {
    en: { title: 'Booking Cancelled', body: 'Customer reported you did not arrive and cancelled the booking.' },
    si: { title: 'සේවාව අවලංගු විය', body: 'ඔබ පැමිණියේ නැති බව වාර්තා කර පාරිභෝගිකයා සේවාව අවලංගු කළේය.' },
    ta: { title: 'முன்பதிவு ரத்து செய்யப்பட்டது', body: 'நீங்கள் வரவில்லை என்று வாடிக்கையாளர் முன்பதிவை ரத்து செய்தார்.' },
  },
  support_ticket_created: {
    en: { title: 'New Support Ticket', body: 'A customer or provider submitted a support request.' },
    si: { title: 'නව සහාය ඉල්ලීමක්', body: 'පාරිභෝගිකයෙකු හෝ සේවා සපයන්නෙකු සහාය ඉල්ලීමක් එවා ඇත.' },
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
  job_posted: {
    en: { title: 'New Job in Your Area', body: 'A new job matching your trade is available near you.' },
    si: { title: 'ඔබගේ ප්‍රදේශයේ නව වැඩක්', body: 'ඔබගේ සේවාවට ගැළපෙන නව වැඩක් ඔබගේ ප්‍රදේශයේ ඇත.' },
    ta: { title: 'உங்கள் பகுதியில் புதிய வேலை', body: 'உங்கள் துறைக்கு பொருந்தக்கூடிய புதிய வேலை உங்கள் பகுதியில் உள்ளது.' },
  },
  provider_cancelled: {
    en: { title: 'Provider Cancelled', body: 'The provider cancelled the booking.' },
    si: { title: 'සේවා සපයන්නා අවලංගු කළා', body: 'සේවා සපයන්නා වෙන්කිරීම අවලංගු කළේය.' },
    ta: { title: 'வழங்குநர் ரத்து செய்தார்', body: 'சேவை வழங்குநர் முன்பதிவை ரத்து செய்தார்.' },
  },
  job_reopened: {
    en: { title: 'Job Available Again', body: 'The job is open again. Your bid is active.' },
    si: { title: 'වැඩය නැවත විවෘතයි', body: 'වැඩය නැවත විවෘත විය. ඔබගේ ලංසුව සක්‍රීයයි.' },
    ta: { title: 'வேலை மீண்டும் கிடைக்கிறது', body: 'வேலை மீண்டும் திறக்கப்பட்டுள்ளது. உங்கள் ஏலம் செயலில் உள்ளது.' },
  },
};

function calculateDistanceKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

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

  // caller must be verified or an admin
  const isEmailOtpVerified = decodedUser.emailOtp === true;
  const isAdmin = !!(decodedUser.admin2faUntil || decodedUser.admin || decodedUser.superAdmin);
  if (!isEmailOtpVerified && !isAdmin) {
    const superDoc = await db.collection('superAdmins').doc(callerUid).get();
    let adminAuthorized = superDoc.exists;
    if (!adminAuthorized) {
      const adminDoc = await db.collection('admins').doc(callerUid).get();
      adminAuthorized = adminDoc.exists && adminDoc.data() && adminDoc.data().status === 'active';
    }
    if (!adminAuthorized) {
      return res.status(403).json({ error: 'email_otp_required', message: 'Email OTP verification is required.' });
    }
  }

  const { event, docId } = req.body || {};

  if (!event || !docId || typeof event !== 'string' || typeof docId !== 'string') {
    return res.status(400).json({ error: 'event and docId are required string fields' });
  }

  try {
    let recipientUid = null;
    let metadata = { docId, event };

    if (event === 'provider_cancelled') {
      const bSnap = await db.collection('bookings').doc(docId).get();
      if (!bSnap.exists) {
        return res.status(404).json({ error: 'Booking not found' });
      }
      const b = bSnap.data() || {};
      if (b.status !== 'cancelled' && b.status !== 'declined') {
        return res.status(400).json({ error: 'Booking is not cancelled or declined' });
      }
      if (b.cancelledByRole && b.cancelledByRole !== 'provider') {
        return res.status(403).json({ error: 'Cancellation was not performed by provider' });
      }
      if (callerUid !== b.providerId) {
        return res.status(403).json({ error: 'Caller is not the booking provider' });
      }

      // idempotency check
      if (b.providerCancellationProcessed) {
        return res.status(200).json({ success: true, alreadyProcessed: true });
      }

      await bSnap.ref.update({
        providerCancellationProcessed: true,
      });

      // increment technician cancellationCount
      const provUid = b.providerId || callerUid;
      await db.collection('technicians').doc(provUid).set({
        cancellationCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      const custId = b.customerId;
      const jobId = b.jobRequestId;
      let jobStatus = 'open';
      const restoredProviders = [];

      if (jobId) {
        const jobSnap = await db.collection('jobRequests').doc(jobId).get();
        if (jobSnap.exists) {
          jobStatus = jobSnap.data()?.status || 'open';
        }

        // restore other not_selected quotes to pending (skip withdrawn)
        const quotesSnap = await db.collection('jobRequests').doc(jobId).collection('quotes').get();
        const batch = db.batch();
        quotesSnap.forEach((qDoc) => {
          const qData = qDoc.data() || {};
          if (qData.status === 'not_selected' && qData.providerId !== provUid && qDoc.id !== provUid) {
            batch.update(qDoc.ref, {
              status: 'pending',
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            if (qData.providerId) restoredProviders.push(qData.providerId);
          }
        });
        await batch.commit();
      }

      // notify customer
      if (custId) {
        try {
          const custUserSnap = await db.collection('users').doc(custId).get();
          const custUser = custUserSnap.exists ? custUserSnap.data() || {} : {};
          const lang = custUser.language || 'en';

          const provName = b.providerName || 'Provider';
          let notifBody = '';
          if (jobStatus === 'expired') {
            notifBody = lang === 'si'
              ? `${provName} අවලංගු කළා. අලුත් කරන්න හෝ නැවත දමන්න.`
              : (lang === 'ta'
                ? `${provName} ரத்து செய்தார். புதுப்பிக்கவும் அல்லது மீண்டும் பதிவிடவும்.`
                : `${provName} cancelled. Renew or post again.`);
          } else {
            notifBody = lang === 'si'
              ? `${provName} අවලංගු කළා. ඔබගේ ලංසු වලින් වෙනත් සපයන්නෙකු තෝරන්න හෝ නැවත දමන්න.`
              : (lang === 'ta'
                ? `${provName} ரத்து செய்தார். உங்கள் ஏலங்களிலிருந்து மற்றொரு வழங்குநரைத் தேர்ந்தெடுக்கவும் அல்லது மீண்டும் பதிவிடவும்.`
                : `${provName} cancelled. Choose another provider from your bids or post again.`);
          }

          const notifTitle = lang === 'si' ? 'සේවා සපයන්නා අවලංගු කළා' : (lang === 'ta' ? 'வழங்குநர் ரத்து செய்தார்' : 'Provider Cancelled');

          const notifRef = db.collection('users').doc(custId).collection('notifications').doc();
          await notifRef.set({
            id: notifRef.id,
            recipientUid: custId,
            eventType: 'provider_cancelled',
            title: notifTitle,
            body: notifBody,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            jobRequestId: jobId,
            bookingId: docId,
          });

          // send FCM push
          const tokenSnap = await db.collection('users').doc(custId).collection('fcmTokens').get();
          const tokens = [];
          tokenSnap.forEach((d) => {
            const td = d.data();
            if (td && td.token) tokens.push(td.token);
          });
          if (tokens.length > 0 && admin.messaging) {
            await admin.messaging().sendEachForMulticast({
              notification: { title: notifTitle, body: notifBody },
              data: {
                eventType: 'provider_cancelled',
                jobRequestId: jobId || '',
                bookingId: docId,
              },
              tokens,
            }).catch(() => {});
          }
        } catch (cErr) {
          console.error('[provider_cancelled] Error notifying customer:', cErr);
        }
      }

      // notify other restored bidders
      for (const pUid of restoredProviders) {
        try {
          const pUserSnap = await db.collection('users').doc(pUid).get();
          const pUser = pUserSnap.exists ? pUserSnap.data() || {} : {};
          const lang = pUser.language || 'en';
          const tmpl = templates.job_reopened[lang] || templates.job_reopened.en;

          const notifRef = db.collection('users').doc(pUid).collection('notifications').doc();
          await notifRef.set({
            id: notifRef.id,
            recipientUid: pUid,
            eventType: 'job_reopened',
            title: tmpl.title,
            body: tmpl.body,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            jobRequestId: jobId,
          });

          const pTokensSnap = await db.collection('users').doc(pUid).collection('fcmTokens').get();
          const pTokens = [];
          pTokensSnap.forEach((d) => {
            const td = d.data();
            if (td && td.token) pTokens.push(td.token);
          });
          if (pTokens.length > 0 && admin.messaging) {
            await admin.messaging().sendEachForMulticast({
              notification: { title: tmpl.title, body: tmpl.body },
              data: {
                eventType: 'job_reopened',
                jobRequestId: jobId || '',
              },
              tokens: pTokens,
            }).catch(() => {});
          }
        } catch (pErr) {
          console.error('[provider_cancelled] Error notifying restored bidder:', pErr);
        }
      }

      return res.status(200).json({
        success: true,
        restoredQuotesCount: restoredProviders.length,
      });
    }

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
      if (event === 'booking_cancelled' && b.cancellationReason) {
        metadata.cancellationReason = b.cancellationReason;
      }
      if (event === 'booking_declined' && b.declineReason) {
        metadata.declineReason = b.declineReason;
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

      // mark other bids as not selected
      try {
        const quotesSnap = await db.collection('jobRequests').doc(docId).collection('quotes').get();
        const serverBatch = db.batch();
        const unselectedProviders = [];
        quotesSnap.forEach((qDoc) => {
          const qData = qDoc.data() || {};
          if (qDoc.id !== job.acceptedQuoteId && qData.status === 'pending') {
            serverBatch.update(qDoc.ref, {
              status: 'not_selected',
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            if (qData.providerId && !unselectedProviders.includes(qData.providerId)) {
              unselectedProviders.push(qData.providerId);
            }
          }
        });
        await serverBatch.commit();

        for (const pUid of unselectedProviders) {
          if (pUid !== recipientUid) {
            try {
              const pUserSnap = await db.collection('users').doc(pUid).get();
              const pUser = pUserSnap.exists ? pUserSnap.data() : {};
              const lang = (pUser && pUser.language) ? pUser.language : 'en';
              const tmpl = templates.quote_not_selected[lang] || templates.quote_not_selected.en;
              const notifRef = db.collection('users').doc(pUid).collection('notifications').doc();
              await notifRef.set({
                id: notifRef.id,
                recipientUid: pUid,
                eventType: 'quote_not_selected',
                title: tmpl.title,
                body: tmpl.body,
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                jobRequestId: docId,
              });
              if (pUser.fcmToken) {
                await admin.messaging().send({
                  token: pUser.fcmToken,
                  notification: { title: tmpl.title, body: tmpl.body },
                  data: { eventType: 'quote_not_selected', jobRequestId: docId },
                }).catch(() => {});
              }
            } catch (pErr) {
              console.error('Error notifying unselected provider:', pErr);
            }
          }
        }
      } catch (err) {
        console.error('Error updating unselected quotes:', err);
      }
    } else if (event === 'job_closed') {
      const jobSnap = await db.collection('jobRequests').doc(docId).get();
      if (!jobSnap.exists) {
        return res.status(404).json({ error: 'Job request not found' });
      }
      const job = jobSnap.data() || {};
      if (callerUid !== job.customerId) {
        return res.status(403).json({ error: 'Unauthorized event actor' });
      }
      metadata.jobRequestId = docId;

      try {
        const quotesSnap = await db.collection('jobRequests').doc(docId).collection('quotes').get();
        const notifiedProviders = [];
        for (const qDoc of quotesSnap.docs) {
          const qData = qDoc.data() || {};
          const pUid = qData.providerId;
          if (pUid && !notifiedProviders.includes(pUid) && pUid !== callerUid) {
            notifiedProviders.push(pUid);
            try {
              const pUserSnap = await db.collection('users').doc(pUid).get();
              const pUser = pUserSnap.exists ? pUserSnap.data() : {};
              const lang = (pUser && pUser.language) ? pUser.language : 'en';
              const tmpl = templates.job_closed[lang] || templates.job_closed.en;
              const notifRef = db.collection('users').doc(pUid).collection('notifications').doc();
              await notifRef.set({
                id: notifRef.id,
                recipientUid: pUid,
                eventType: 'job_closed',
                title: tmpl.title,
                body: tmpl.body,
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                jobRequestId: docId,
              });
              if (pUser.fcmToken) {
                await admin.messaging().send({
                  token: pUser.fcmToken,
                  notification: { title: tmpl.title, body: tmpl.body },
                  data: { eventType: 'job_closed', jobRequestId: docId },
                }).catch(() => {});
              }
            } catch (pErr) {
              console.error('Error notifying provider for job_closed:', pErr);
            }
          }
        }
        return res.status(200).json({ success: true, notifiedCount: notifiedProviders.length });
      } catch (err) {
        console.error('Error in job_closed notifications:', err);
        return res.status(500).json({ error: 'Internal server error' });
      }
    } else if (event === 'job_updated') {
      const jobSnap = await db.collection('jobRequests').doc(docId).get();
      if (!jobSnap.exists) {
        return res.status(404).json({ error: 'Job request not found' });
      }
      const job = jobSnap.data() || {};
      if (callerUid !== job.customerId) {
        return res.status(403).json({ error: 'Unauthorized event actor' });
      }
      metadata.jobRequestId = docId;

      try {
        const quotesSnap = await db.collection('jobRequests').doc(docId).collection('quotes').where('status', '==', 'pending').get();
        const notifiedProviders = [];
        const quoteBatch = db.batch();

        for (const qDoc of quotesSnap.docs) {
          quoteBatch.update(qDoc.ref, {
            jobUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          const qData = qDoc.data() || {};
          const pUid = qData.providerId;
          if (pUid && !notifiedProviders.includes(pUid) && pUid !== callerUid) {
            notifiedProviders.push(pUid);
          }
        }

        if (!quotesSnap.empty) {
          await quoteBatch.commit();
        }

        for (const pUid of notifiedProviders) {
          try {
            const pUserSnap = await db.collection('users').doc(pUid).get();
            const pUser = pUserSnap.exists ? pUserSnap.data() : {};
            const lang = (pUser && pUser.language) ? pUser.language : 'en';
            const tmpl = templates.job_updated[lang] || templates.job_updated.en;
            const notifRef = db.collection('users').doc(pUid).collection('notifications').doc();
            await notifRef.set({
              id: notifRef.id,
              recipientUid: pUid,
              eventType: 'job_updated',
              title: tmpl.title,
              body: tmpl.body,
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              jobRequestId: docId,
            });

            const tokenSnap = await db.collection('users').doc(pUid).collection('fcmTokens').get();
            const tokens = [];
            tokenSnap.forEach((tDoc) => {
              const tData = tDoc.data();
              if (tData && tData.token) tokens.push(tData.token);
            });

            if (tokens.length > 0 && admin.messaging) {
              const payload = {
                notification: { title: tmpl.title, body: tmpl.body },
                data: { eventType: 'job_updated', jobRequestId: docId },
                tokens,
              };
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
            }
          } catch (pErr) {
            console.error('[notify] error notifying provider for job_updated:', pErr);
          }
        }
        return res.status(200).json({ success: true, notifiedCount: notifiedProviders.length });
      } catch (err) {
        console.error('[notify] error in job_updated notifications:', err);
        return res.status(500).json({ error: 'Internal server error' });
      }
    } else if (event === 'job_posted') {
      const jobSnap = await db.collection('jobRequests').doc(docId).get();
      if (!jobSnap.exists) {
        return res.status(200).json({ success: true, skipped: 'not_found' });
      }
      const job = jobSnap.data() || {};
      if (callerUid !== job.customerId) {
        return res.status(200).json({ success: true, skipped: 'unauthorized_or_mismatch' });
      }
      if (job.status !== 'open') {
        return res.status(200).json({ success: true, skipped: 'not_open' });
      }
      const markerRef = db.collection('jobRequests').doc(docId).collection('private').doc('notified');
      const markerSnap = await markerRef.get();
      if (markerSnap.exists) {
        return res.status(200).json({ success: true, skipped: 'already_notified' });
      }
      await markerRef.set({ notifiedAt: admin.firestore.FieldValue.serverTimestamp() });

      try {
        const jobLat = job.latitude;
        const jobLng = job.longitude;
        if (typeof jobLat !== 'number' || typeof jobLng !== 'number') {
          return res.status(200).json({ success: true, skipped: 'missing_coords' });
        }

        const techsSnap = await db.collection('technicians')
          .where('category', '==', job.category)
          .where('nicVerified', '==', true)
          .get();

        const candidateTechs = [];
        const now = Date.now();
        const thirtyMinMs = 30 * 60 * 1000;

        for (const tDoc of techsSnap.docs) {
          const tData = tDoc.data() || {};
          if (tData.isBanned === true) continue;
          if (tDoc.id === callerUid) continue;

          let effectiveLat = typeof tData.baseLatitude === 'number' ? tData.baseLatitude : tData.latitude;
          let effectiveLng = typeof tData.baseLongitude === 'number' ? tData.baseLongitude : tData.longitude;

          try {
            const liveSnap = await db.collection('liveLocations').doc(tDoc.id).get();
            if (liveSnap.exists) {
              const liveData = liveSnap.data() || {};
              const liveTs = liveData.timestamp ? (liveData.timestamp.toMillis ? liveData.timestamp.toMillis() : new Date(liveData.timestamp).getTime()) : 0;
              if (now - liveTs <= thirtyMinMs && typeof liveData.latitude === 'number' && typeof liveData.longitude === 'number') {
                effectiveLat = liveData.latitude;
                effectiveLng = liveData.longitude;
              }
            }
          } catch (_) {}

          if (typeof effectiveLat !== 'number' || typeof effectiveLng !== 'number') continue;

          const dist = calculateDistanceKm(jobLat, jobLng, effectiveLat, effectiveLng);
          const radius = typeof tData.serviceRadiusKm === 'number' ? tData.serviceRadiusKm : 25;
          if (dist <= radius) {
            candidateTechs.push({
              uid: tDoc.id,
              distance: dist,
            });
          }
        }

        candidateTechs.sort((a, b) => a.distance - b.distance);
        const topTechs = candidateTechs.slice(0, 30);

        for (const t of topTechs) {
          try {
            const uSnap = await db.collection('users').doc(t.uid).get();
            const uData = uSnap.exists ? uSnap.data() : {};
            const lang = (uData && uData.language) ? uData.language : 'en';
            const tmpl = templates.job_posted[lang] || templates.job_posted.en;
            const notifRef = db.collection('users').doc(t.uid).collection('notifications').doc();
            await notifRef.set({
              id: notifRef.id,
              recipientUid: t.uid,
              eventType: 'job_posted',
              title: tmpl.title,
              body: tmpl.body,
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              jobRequestId: docId,
            });
            if (uData.fcmToken) {
              await admin.messaging().send({
                token: uData.fcmToken,
                notification: { title: tmpl.title, body: tmpl.body },
                data: { eventType: 'job_posted', jobRequestId: docId },
              }).catch(() => {});
            }
          } catch (tErr) {
            console.error('Error dispatching job_posted to tech:', tErr);
          }
        }

        return res.status(200).json({ success: true, notifiedCount: topTechs.length });
      } catch (err) {
        console.error('Error in job_posted dispatch:', err);
        return res.status(200).json({ success: true, error: err.message });
      }
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

      // find active support admins
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

      // verify admin has active session
      const nowSec = Math.floor(Date.now() / 1000);
      if (!decodedUser.admin2faUntil || typeof decodedUser.admin2faUntil !== 'number' || decodedUser.admin2faUntil <= nowSec) {
        return res.status(403).json({ error: 'admin_2fa_required', message: 'Admin 2FA verification required or expired.' });
      }

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
    let body = entry.body;

    if (event === 'booking_cancelled' && metadata.cancellationReason) {
      body = `${body}: ${metadata.cancellationReason}`;
    } else if (event === 'booking_declined' && metadata.declineReason) {
      body = `${body}: ${metadata.declineReason}`;
    }

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
