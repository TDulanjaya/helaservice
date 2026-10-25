const { S3Client, DeleteObjectsCommand } = require('@aws-sdk/client-s3');
const { admin, db } = require('./_firebase');

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

module.exports = async function handler(req, res) {
  if (req.method !== 'GET' && req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const expectedSecret = (process.env.CRON_SECRET || '').trim();
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7).trim() : '';
  const altSecret = (req.headers['x-cron-secret'] || '').trim();

  if (!expectedSecret || (token !== expectedSecret && altSecret !== expectedSecret)) {
    return res.status(401).json({ error: 'Unauthorized: Invalid or missing cron secret' });
  }

  const bucketName = (process.env.B2_BUCKET_NAME || '').trim();
  if (!bucketName) {
    console.error('B2_BUCKET_NAME is not configured');
    return res.status(500).json({ error: 'storage_not_configured' });
  }

  const s3 = getS3Client();
  if (!s3) {
    return res.status(500).json({ error: 'B2 storage credentials not configured' });
  }

    // read retention settings from app_config/cleanup with defaults
    const configDoc = await db.collection('app_config').doc('cleanup').get();
    const config = configDoc.exists ? configDoc.data() || {} : {};
    const mediaRetentionDays = typeof config.mediaRetentionDays === 'number' ? config.mediaRetentionDays : 30;
    const deletedPostGraceDays = typeof config.deletedPostGraceDays === 'number' ? config.deletedPostGraceDays : 1;
    const mediaWarningDays = typeof config.mediaWarningDays === 'number' ? config.mediaWarningDays : 3;

    const retentionCutoff = new Date(Date.now() - mediaRetentionDays * 24 * 60 * 60 * 1000);
    const retentionTimestamp = admin.firestore.Timestamp.fromDate(retentionCutoff);

    // 1. Send advance media warning before deletion
    const warningMs = (mediaRetentionDays - mediaWarningDays) * 24 * 60 * 60 * 1000;
    const warningCutoff = new Date(Date.now() - warningMs);
    const warningTimestamp = admin.firestore.Timestamp.fromDate(warningCutoff);

    const warningSnap = await db
      .collection('jobRequests')
      .where('status', '==', 'expired')
      .where('expiresAt', '<=', warningTimestamp)
      .get();

    let warningsSentCount = 0;
    for (const wDoc of warningSnap.docs) {
      const wData = wDoc.data() || {};
      if (wData.mediaDeletedAt || wData.mediaWarningSentAt) continue;

      // skip if linked to a booking
      const bSnap = await db.collection('bookings').where('jobRequestId', '==', wDoc.id).limit(1).get();
      if (!bSnap.empty) continue;

      const custUid = wData.customerId;
      if (custUid) {
        try {
          const uSnap = await db.collection('users').doc(custUid).get();
          const uData = uSnap.exists ? uSnap.data() || {} : {};
          const lang = uData.language || 'en';

          const title = lang === 'si' ? 'ඡායාරූප ඉවත් කිරීමේ දැනුම්දීම' : (lang === 'ta' ? 'புகைப்படங்கள் நீக்கல் அறிவிப்பு' : 'Media Removal Notice');
          const body = lang === 'si'
            ? `ඔබගේ කල් ඉකුත් වූ වැඩයේ ඡායාරූප දින ${mediaWarningDays} කින් ඉවත් කරනු ලැබේ. ඒවා තබා ගැනීමට අලුත් කරන්න හෝ නැවත දමන්න.`
            : (lang === 'ta'
              ? `உங்கள் காலாவதியான வேலையின் புகைப்படங்கள் ${mediaWarningDays} நாட்களில் நீக்கப்படும். அவற்றை வைத்திருக்க புதுப்பிக்கவும் அல்லது மீண்டும் பதிவிடவும்.`
              : `Your expired post's photos will be removed in ${mediaWarningDays} days. Renew or post again to keep them.`);

          const notifRef = db.collection('users').doc(custUid).collection('notifications').doc();
          await notifRef.set({
            id: notifRef.id,
            recipientUid: custUid,
            eventType: 'media_cleanup_warning',
            title,
            body,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            jobRequestId: wDoc.id,
          });

          const tokensSnap = await db.collection('users').doc(custUid).collection('fcmTokens').get();
          const tokens = [];
          tokensSnap.forEach((t) => {
            const td = t.data();
            if (td && td.token) tokens.push(td.token);
          });
          if (tokens.length > 0 && admin.messaging) {
            await admin.messaging().sendEachForMulticast({
              notification: { title, body },
              data: { eventType: 'media_cleanup_warning', jobRequestId: wDoc.id },
              tokens,
            }).catch(() => {});
          }

          await wDoc.ref.update({
            mediaWarningSentAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          warningsSentCount++;
        } catch (warnErr) {
          console.error('[cleanup-media] Error sending warning:', warnErr.message);
        }
      }
    }

    // 2. Query expired or cancelled posts older than mediaRetentionDays
    const cancelledSnap = await db
      .collection('jobRequests')
      .where('status', '==', 'cancelled')
      .where('cancelledAt', '<=', retentionTimestamp)
      .get();

    const expiredSnap = await db
      .collection('jobRequests')
      .where('status', '==', 'expired')
      .where('expiresAt', '<=', retentionTimestamp)
      .get();

    const jobDocsMap = new Map();
    cancelledSnap.forEach((doc) => {
      const data = doc.data() || {};
      if (!data.mediaDeletedAt && data.status === 'cancelled') jobDocsMap.set(doc.id, doc);
    });
    expiredSnap.forEach((doc) => {
      const data = doc.data() || {};
      if (!data.mediaDeletedAt && data.status === 'expired') jobDocsMap.set(doc.id, doc);
    });

    let processedJobsCount = 0;
    let deletedFilesCount = 0;

    for (const [jobId, jobDoc] of jobDocsMap.entries()) {
      const data = jobDoc.data() || {};

      // verify post status is still expired or cancelled (never clean renewed posts)
      if (data.status !== 'expired' && data.status !== 'cancelled') continue;

      // verify never linked to a booking
      const bookingsSnap = await db
        .collection('bookings')
        .where('jobRequestId', '==', jobId)
        .limit(1)
        .get();
      if (!bookingsSnap.empty) continue;

      const keysToDelete = [];

      // get photo keys
      if (Array.isArray(data.photos)) {
        for (const item of data.photos) {
          if (item && typeof item.key === 'string' && item.key.trim().length > 0) {
            keysToDelete.push(item.key.trim());
          }
        }
      }

      // get video key
      if (data.video && typeof data.video.key === 'string' && data.video.key.trim().length > 0) {
        keysToDelete.push(data.video.key.trim());
      }

      // legacy urls
      if (Array.isArray(data.photoUrls)) {
        for (const url of data.photoUrls) {
          if (typeof url === 'string') {
            const match = url.match(/uploads\/[^?&]+/);
            if (match) keysToDelete.push(match[0]);
          }
        }
      }

      if (keysToDelete.length === 0) {
        await jobDoc.ref.update({
          mediaDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        processedJobsCount++;
        continue;
      }

      if (keysToDelete.length > 0) {
        const deleteCmd = new DeleteObjectsCommand({
          Bucket: bucketName,
          Delete: {
            Objects: keysToDelete.map((key) => ({ Key: key })),
            Quiet: true,
          },
        });
        await s3.send(deleteCmd);
        deletedFilesCount += keysToDelete.length;
      }

      await jobDoc.ref.update({
        mediaDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      processedJobsCount++;
    }

    console.log(`[cleanup-media] Completed: ${processedJobsCount} jobs processed, ${deletedFilesCount} files deleted.`);

    // 3. Purge soft-deleted posts older than deletedPostGraceDays
    let permanentlyDeletedJobsCount = 0;
    try {
      const graceCutoff = new Date(Date.now() - deletedPostGraceDays * 24 * 60 * 60 * 1000);
      const graceTimestamp = admin.firestore.Timestamp.fromDate(graceCutoff);

      const deletedSnap = await db
        .collection('jobRequests')
        .where('status', '==', 'deleted')
        .where('deletedAt', '<=', graceTimestamp)
        .get();

      for (const dDoc of deletedSnap.docs) {
        const dData = dDoc.data() || {};
        const delKeys = [];

        if (Array.isArray(dData.photos)) {
          for (const item of dData.photos) {
            if (item && typeof item.key === 'string' && item.key.trim().length > 0) {
              delKeys.push(item.key.trim());
            }
          }
        }
        if (dData.video && typeof dData.video.key === 'string' && dData.video.key.trim().length > 0) {
          delKeys.push(dData.video.key.trim());
        }
        if (Array.isArray(dData.photoUrls)) {
          for (const url of dData.photoUrls) {
            if (typeof url === 'string') {
              const match = url.match(/uploads\/[^?&]+/);
              if (match) delKeys.push(match[0]);
            }
          }
        }

        if (delKeys.length > 0) {
          try {
            const deleteCmd = new DeleteObjectsCommand({
              Bucket: bucketName,
              Delete: {
                Objects: delKeys.map((key) => ({ Key: key })),
                Quiet: true,
              },
            });
            await s3.send(deleteCmd);
            deletedFilesCount += delKeys.length;
          } catch (s3Err) {
            console.error(`[cleanup-media] s3 delete error for deleted job ${dDoc.id}:`, s3Err.message);
          }
        }

        const privateSnap = await dDoc.ref.collection('private').get();
        const quotesSnap = await dDoc.ref.collection('quotes').get();
        const delBatch = db.batch();
        privateSnap.forEach((pDoc) => delBatch.delete(pDoc.ref));
        quotesSnap.forEach((qDoc) => delBatch.delete(qDoc.ref));
        delBatch.delete(dDoc.ref);
        await delBatch.commit();
        permanentlyDeletedJobsCount++;
      }
    } catch (delErr) {
      console.error('[cleanup-media] error removing deleted jobs:', delErr.message);
    }

    // --- Cleanup unverified accounts (Auth users > 7 days old) ---
    const isDryRun = process.env.CLEANUP_UNVERIFIED_DRY_RUN !== 'false';
    let unverifiedCandidatesCount = 0;
    let deletedUnverifiedCount = 0;

    try {
      const sevenDaysAgoMs = Date.now() - 7 * 24 * 60 * 60 * 1000;
      let pageToken;

      do {
        const listUsersResult = await admin.auth().listUsers(100, pageToken);
        for (const userRecord of listUsersResult.users) {
          const creationMs = new Date(userRecord.metadata.creationTime).getTime();
          if (creationMs > sevenDaysAgoMs) {
            continue; // Created within last 7 days
          }

          // If emailOtp claim is already true, skip
          if (userRecord.customClaims && userRecord.customClaims.emailOtp === true) {
            continue;
          }

          const uid = userRecord.uid;

          // Check users collection for emailOtpVerified
          const userDoc = await db.collection('users').doc(uid).get();
          if (userDoc.exists && userDoc.data() && userDoc.data().emailOtpVerified === true) {
            continue;
          }

          // NEVER delete superAdmins or admins
          const isSuperAdmin = (await db.collection('superAdmins').doc(uid).get()).exists;
          if (isSuperAdmin) continue;

          const isAdminDoc = (await db.collection('admins').doc(uid).get()).exists;
          if (isAdminDoc) continue;

          // NEVER delete technicians
          const isTech = (await db.collection('technicians').doc(uid).get()).exists;
          if (isTech) continue;

          // NEVER delete users with bookings
          const custBooking = await db.collection('bookings').where('customerId', '==', uid).limit(1).get();
          if (!custBooking.empty) continue;
          const provBooking = await db.collection('bookings').where('providerId', '==', uid).limit(1).get();
          if (!provBooking.empty) continue;

          // NEVER delete users with job requests
          const custJob = await db.collection('jobRequests').where('customerId', '==', uid).limit(1).get();
          if (!custJob.empty) continue;

          // NEVER delete users with complaints / tickets
          const custTicket = await db.collection('complaints').where('customerId', '==', uid).limit(1).get();
          if (!custTicket.empty) continue;
          const repTicket = await db.collection('complaints').where('reporterUid', '==', uid).limit(1).get();
          if (!repTicket.empty) continue;

          // NEVER delete users with chat rooms
          const userChats = await db.collection('chatRooms').where('participants', 'array-contains', uid).limit(1).get();
          if (!userChats.empty) continue;

          // Candidate identified
          unverifiedCandidatesCount++;

          if (!isDryRun) {
            await admin.auth().deleteUser(uid);
            if (userDoc.exists) {
              await userDoc.ref.delete();
            }
            deletedUnverifiedCount++;
          }
        }
        pageToken = listUsersResult.pageToken;
      } while (pageToken);

      console.log(`[cleanup-unverified] Finished. DryRun: ${isDryRun}, Candidates: ${unverifiedCandidatesCount}, Deleted: ${deletedUnverifiedCount}`);
    } catch (unverifiedErr) {
      console.error('[cleanup-unverified] Error checking unverified accounts:', unverifiedErr.message);
    }

    return res.status(200).json({
      success: true,
      warningsSent: warningsSentCount,
      processedJobs: processedJobsCount,
      permanentlyDeletedJobs: permanentlyDeletedJobsCount,
      deletedFiles: deletedFilesCount,
      unverifiedCleanup: {
        dryRun: isDryRun,
        candidatesCount: unverifiedCandidatesCount,
        deletedCount: deletedUnverifiedCount,
      },
    });
  } catch (err) {
    console.error('[cleanup-media] Cron execution error:', err.message);
    return res.status(500).json({ error: 'Failed to cleanup media' });
  }
};
