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

  try {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const sevenDaysTimestamp = admin.firestore.Timestamp.fromDate(sevenDaysAgo);

    const cancelledSnap = await db
      .collection('jobRequests')
      .where('status', '==', 'cancelled')
      .where('cancelledAt', '<=', sevenDaysTimestamp)
      .get();

    const expiredSnap = await db
      .collection('jobRequests')
      .where('status', '==', 'expired')
      .where('expiresAt', '<=', sevenDaysTimestamp)
      .get();

    const jobDocsMap = new Map();
    cancelledSnap.forEach((doc) => {
      if (!doc.data().mediaDeletedAt) jobDocsMap.set(doc.id, doc);
    });
    expiredSnap.forEach((doc) => {
      if (!doc.data().mediaDeletedAt) jobDocsMap.set(doc.id, doc);
    });

    let processedJobsCount = 0;
    let deletedFilesCount = 0;

    for (const [jobId, jobDoc] of jobDocsMap.entries()) {
      const data = jobDoc.data() || {};
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

      // skip photos kept in bookings
      const bookingsSnap = await db
        .collection('bookings')
        .where('jobRequestId', '==', jobId)
        .get();

      const bookingReferencedKeys = new Set();
      bookingsSnap.forEach((bDoc) => {
        const bData = bDoc.data() || {};
        if (Array.isArray(bData.beforePhotos)) {
          bData.beforePhotos.forEach((k) => bookingReferencedKeys.add(k));
        }
        if (Array.isArray(bData.afterPhotos)) {
          bData.afterPhotos.forEach((k) => bookingReferencedKeys.add(k));
        }
      });

      for (const bDoc of bookingsSnap.docs) {
        const extrasSnap = await bDoc.ref.collection('extras').get();
        extrasSnap.forEach((eDoc) => {
          const eData = eDoc.data() || {};
          if (Array.isArray(eData.photos)) {
            eData.photos.forEach((k) => bookingReferencedKeys.add(k));
          }
        });
      }

      const finalKeysToDelete = keysToDelete.filter((k) => !bookingReferencedKeys.has(k));

      if (finalKeysToDelete.length > 0) {
        const deleteCmd = new DeleteObjectsCommand({
          Bucket: bucketName,
          Delete: {
            Objects: finalKeysToDelete.map((key) => ({ Key: key })),
            Quiet: true,
          },
        });
        await s3.send(deleteCmd);
        deletedFilesCount += finalKeysToDelete.length;
      }

      await jobDoc.ref.update({
        mediaDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      processedJobsCount++;
    }

    console.log(`[cleanup-media] Completed: ${processedJobsCount} jobs processed, ${deletedFilesCount} files deleted.`);

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
      processedJobs: processedJobsCount,
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
