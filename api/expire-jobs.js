const { admin, db } = require('./_firebase');

// closed job templates
const closedTemplates = {
  en: (title) => ({
    title: 'Job Closed',
    body: `${title || 'The job'} is no longer available.`,
  }),
  si: (title) => ({
    title: 'වැඩය අවසන්',
    body: `${title || 'වැඩය'} තවදුරටත් ලබාගත නොහැක.`,
  }),
  ta: (title) => ({
    title: 'வேலை முடிந்தது',
    body: `${title || 'வேலை'} இனி கிடைக்காது.`,
  }),
};

// not selected templates
const notSelectedTemplates = {
  en: { title: 'Quote Not Selected', body: 'The customer selected another quote for this job.' },
  si: { title: 'මිල ගණන් තෝරා නොගැනුණි', body: 'පාරිභෝගිකයා මෙම වැඩය සඳහා වෙනත් මිල ගණන් තෝරාගන්නා ලදී.' },
  ta: { title: 'மதிப்பீடு தேர்ந்தெடுக்கப்படவில்லை', body: 'வாடிக்கையாளர் இந்த வேலைக்கு மற்றொரு மதிப்பீட்டைத் தேர்ந்தெடுத்துள்ளார்.' },
};

// colombo end of day calculation
function getColomboEndOfDay(dateObj) {
  const colomboTimeMs = dateObj.getTime() + 5.5 * 60 * 60 * 1000;
  const colomboDate = new Date(colomboTimeMs);
  const year = colomboDate.getUTCFullYear();
  const month = colomboDate.getUTCMonth();
  const day = colomboDate.getUTCDate();
  const endOfDayColomboUtcMs = Date.UTC(year, month, day, 23, 59, 59, 999) - 5.5 * 60 * 60 * 1000;
  return new Date(endOfDayColomboUtcMs);
}

module.exports = async function handler(req, res) {
  if (req.method !== 'GET' && req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const expectedSecret = (process.env.CRON_SECRET || '').trim();
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7).trim() : '';

  if (!expectedSecret || token !== expectedSecret) {
    return res.status(401).json({ error: 'Unauthorized: Invalid cron secret' });
  }

  try {
    const nowMs = Date.now();
    const nowTimestamp = admin.firestore.Timestamp.fromMillis(nowMs);

    // find active jobs
    const openSnap = await db
      .collection('jobRequests')
      .where('status', 'in', ['open', 'pending'])
      .get();

    let expiredJobsCount = 0;
    let closedQuotesCount = 0;

    const expiredJobsToProcess = [];

    openSnap.forEach((doc) => {
      const data = doc.data() || {};
      let isExpired = false;
      let calculatedExpiresAt = null;

      if (data.expiresAt && typeof data.expiresAt.toMillis === 'function') {
        if (data.expiresAt.toMillis() <= nowMs) {
          isExpired = true;
          calculatedExpiresAt = data.expiresAt;
        }
      } else {
        // fallback expiry for older jobs
        if (data.scheduledDate && typeof data.scheduledDate.toDate === 'function') {
          const sDate = data.scheduledDate.toDate();
          const endOfSched = getColomboEndOfDay(sDate);
          calculatedExpiresAt = admin.firestore.Timestamp.fromDate(endOfSched);
          if (endOfSched.getTime() <= nowMs) {
            isExpired = true;
          }
        } else if (data.createdAt && typeof data.createdAt.toDate === 'function') {
          const cDate = data.createdAt.toDate();
          const plus7Days = new Date(cDate.getTime() + 7 * 24 * 60 * 60 * 1000);
          calculatedExpiresAt = admin.firestore.Timestamp.fromDate(plus7Days);
          if (plus7Days.getTime() <= nowMs) {
            isExpired = true;
          }
        } else {
          isExpired = true;
          calculatedExpiresAt = nowTimestamp;
        }
      }

      if (isExpired) {
        expiredJobsToProcess.push({
          doc,
          data,
          calculatedExpiresAt,
        });
      }
    });

    // process in chunks
    const chunkSize = 200;
    for (let i = 0; i < expiredJobsToProcess.length; i += chunkSize) {
      const chunk = expiredJobsToProcess.slice(i, i + chunkSize);
      const batch = db.batch();
      const notificationsToSend = [];

      for (const item of chunk) {
        const { doc, data, calculatedExpiresAt } = item;
        const jobUpdate = {
          status: 'expired',
          expiredAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (!data.expiresAt && calculatedExpiresAt) {
          jobUpdate.expiresAt = calculatedExpiresAt;
        }

        batch.update(doc.ref, jobUpdate);
        expiredJobsCount++;

        // find pending quotes
        const quotesSnap = await doc.ref.collection('quotes').where('status', '==', 'pending').get();
        quotesSnap.forEach((qDoc) => {
          batch.update(qDoc.ref, {
            status: 'job_closed',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          closedQuotesCount++;

          const qData = qDoc.data() || {};
          if (qData.providerId) {
            notificationsToSend.push({
              recipientUid: qData.providerId,
              jobTitle: data.title || '',
              jobId: doc.id,
            });
          }
        });
      }

      await batch.commit();

      // send notifications
      for (const notif of notificationsToSend) {
        try {
          const userDoc = await db.collection('users').doc(notif.recipientUid).get();
          const lang = (userDoc.exists && userDoc.data() && (userDoc.data().language || userDoc.data().preferredLanguage)) || 'en';
          const templateFn = closedTemplates[lang] || closedTemplates.en;
          const { title, body } = templateFn(notif.jobTitle);

          const notifRef = db.collection('users').doc(notif.recipientUid).collection('notifications').doc();
          await notifRef.set({
            id: notifRef.id,
            recipientUid: notif.recipientUid,
            eventType: 'job_closed',
            title,
            body,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            jobRequestId: notif.jobId,
          });

          if (userDoc.exists && userDoc.data() && userDoc.data().fcmToken) {
            await admin.messaging().send({
              token: userDoc.data().fcmToken,
              notification: { title, body },
              data: {
                eventType: 'job_closed',
                jobRequestId: notif.jobId,
              },
            }).catch(() => {});
          }
        } catch (notifErr) {
          console.error('[expire-jobs] notification note:', notifErr.message);
        }
      }
    }

    // clean up leftover pending quotes on assigned jobs
    let safetyNetUpdatedBids = 0;
    try {
      const assignedSnap = await db
        .collection('jobRequests')
        .where('status', '==', 'assigned')
        .get();

      for (const aDoc of assignedSnap.docs) {
        const pendingSnap = await aDoc.ref.collection('quotes').where('status', '==', 'pending').get();
        if (!pendingSnap.empty) {
          const safetyBatch = db.batch();
          const unselectedProviders = [];
          pendingSnap.forEach((qDoc) => {
            safetyBatch.update(qDoc.ref, {
              status: 'not_selected',
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            safetyNetUpdatedBids++;
            const qData = qDoc.data() || {};
            if (qData.providerId && !unselectedProviders.includes(qData.providerId)) {
              unselectedProviders.push(qData.providerId);
            }
          });
          await safetyBatch.commit();

          for (const pUid of unselectedProviders) {
            try {
              const existingNotifSnap = await db
                .collection('users')
                .doc(pUid)
                .collection('notifications')
                .where('jobRequestId', '==', aDoc.id)
                .where('eventType', '==', 'quote_not_selected')
                .limit(1)
                .get();

              if (existingNotifSnap.empty) {
                const pUserDoc = await db.collection('users').doc(pUid).get();
                const pData = pUserDoc.exists ? pUserDoc.data() : {};
                const lang = (pData && (pData.language || pData.preferredLanguage)) || 'en';
                const tmpl = notSelectedTemplates[lang] || notSelectedTemplates.en;
                const notifRef = db.collection('users').doc(pUid).collection('notifications').doc();
                await notifRef.set({
                  id: notifRef.id,
                  recipientUid: pUid,
                  eventType: 'quote_not_selected',
                  title: tmpl.title,
                  body: tmpl.body,
                  isRead: false,
                  createdAt: admin.firestore.FieldValue.serverTimestamp(),
                  jobRequestId: aDoc.id,
                });

                if (pData && pData.fcmToken) {
                  await admin.messaging().send({
                    token: pData.fcmToken,
                    notification: { title: tmpl.title, body: tmpl.body },
                    data: { eventType: 'quote_not_selected', jobRequestId: aDoc.id },
                  }).catch(() => {});
                }
              }
            } catch (pErr) {
              console.error('[expire-jobs] safety net notify note:', pErr.message);
            }
          }
        }
      }
    } catch (snErr) {
      console.error('[expire-jobs] safety net error:', snErr.message);
    }

    return res.status(200).json({
      success: true,
      expiredCount: expiredJobsCount,
      closedQuotesCount,
      safetyNetUpdatedBids,
    });
  } catch (err) {
    console.error('[expire-jobs] error:', err.message);
    return res.status(500).json({ error: 'Failed to expire jobs' });
  }
};
