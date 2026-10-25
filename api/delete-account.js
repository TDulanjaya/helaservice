const { S3Client, ListObjectVersionsCommand, DeleteObjectsCommand } = require('@aws-sdk/client-s3');
const { admin, db } = require('./_firebase');
const { verifyFirebaseToken } = require('./_auth');

// initialize s3 client
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
    requestChecksumCalculation: 'WHEN_REQUIRED',
    responseChecksumValidation: 'WHEN_REQUIRED',
  });
}

// delete all versions and delete markers under prefix with pagination and retries
async function deleteS3Prefix(s3, bucket, prefix) {
  if (!s3 || !bucket || !prefix) return 0;
  let keyMarker = undefined;
  let versionIdMarker = undefined;
  let isTruncated = true;
  let totalDeleted = 0;

  try {
    while (isTruncated) {
      const listParams = {
        Bucket: bucket,
        Prefix: prefix,
      };
      if (keyMarker) listParams.KeyMarker = keyMarker;
      if (versionIdMarker) listParams.VersionIdMarker = versionIdMarker;

      const listCmd = new ListObjectVersionsCommand(listParams);
      const listRes = await s3.send(listCmd);

      const objectsToDelete = [];
      if (Array.isArray(listRes.Versions)) {
        for (const v of listRes.Versions) {
          if (v && v.Key) objectsToDelete.push({ Key: v.Key, VersionId: v.VersionId });
        }
      }
      if (Array.isArray(listRes.DeleteMarkers)) {
        for (const m of listRes.DeleteMarkers) {
          if (m && m.Key) objectsToDelete.push({ Key: m.Key, VersionId: m.VersionId });
        }
      }

      if (objectsToDelete.length > 0) {
        // chunk up to 1000 per DeleteObjectsCommand
        for (let i = 0; i < objectsToDelete.length; i += 1000) {
          const chunk = objectsToDelete.slice(i, i + 1000);
          let retries = 3;
          let deletedOk = false;
          while (retries > 0 && !deletedOk) {
            try {
              const deleteCmd = new DeleteObjectsCommand({
                Bucket: bucket,
                Delete: {
                  Objects: chunk,
                  Quiet: true,
                },
              });
              await s3.send(deleteCmd);
              deletedOk = true;
              totalDeleted += chunk.length;
            } catch (delErr) {
              retries--;
              if (retries === 0) {
                console.error(`[deleteS3Prefix] Batch delete failed after 3 retries: ${delErr.message}`);
                throw delErr;
              }
              await new Promise((resolve) => setTimeout(resolve, 500 * (4 - retries)));
            }
          }
        }
      }

      isTruncated = listRes.IsTruncated || false;
      keyMarker = listRes.NextKeyMarker;
      versionIdMarker = listRes.NextVersionIdMarker;
    }

    console.log(`[deleteS3Prefix] Deleted ${totalDeleted} versions/markers under prefix`);
    return totalDeleted;
  } catch (err) {
    console.error(`[deleteS3Prefix] Error: ${err.message}`);
    throw err;
  }
}

// recursively delete collection
async function deleteCollection(colRef) {
  const snapshot = await colRef.get();
  if (snapshot.empty) return;
  const batch = db.batch();
  for (const doc of snapshot.docs) {
    batch.delete(doc.ref);
  }
  await batch.commit();
}

module.exports = async function handler(req, res) {
  // allow cross origin
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-helaservice-key');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  // require firebase id token
  const decodedToken = await verifyFirebaseToken(req, res);
  if (!decodedToken) {
    return;
  }

  const uid = decodedToken.uid;
  if (!uid) {
    return res.status(400).json({ error: 'Invalid user ID token' });
  }

  const bucketName = (process.env.B2_BUCKET_NAME || '').trim();
  if (!bucketName) {
    console.error('B2_BUCKET_NAME is not configured');
    return res.status(500).json({ error: 'storage_not_configured' });
  }

  try {
    // refuse deletion for administrators
    const superAdminDoc = await db.collection('superAdmins').doc(uid).get();
    const adminDoc = await db.collection('admins').doc(uid).get();
    if (superAdminDoc.exists || adminDoc.exists) {
      return res.status(403).json({
        error: 'Administrator accounts cannot be deleted via the client endpoint.',
      });
    }

    // refuse deletion if active bookings exist
    const activeCustomerBookings = await db
      .collection('bookings')
      .where('customerId', '==', uid)
      .where('status', 'in', ['en_route', 'in_progress'])
      .limit(1)
      .get();

    const activeProviderBookings = await db
      .collection('bookings')
      .where('providerId', '==', uid)
      .where('status', 'in', ['en_route', 'in_progress'])
      .limit(1)
      .get();

    if (!activeCustomerBookings.empty || !activeProviderBookings.empty) {
      return res.status(400).json({
        error: 'Cannot delete account while you have active en route or in progress bookings.',
      });
    }

    const failedSteps = [];

    async function runStep(stepName, fn) {
      try {
        await fn();
      } catch (err) {
        console.error(`Step ${stepName} failed:`, err.message);
        failedSteps.push(stepName);
      }
    }

    // cancel pending or confirmed customer bookings
    await runStep('cancel_customer_bookings', async () => {
      const pendingCustBookings = await db
        .collection('bookings')
        .where('customerId', '==', uid)
        .where('status', 'in', ['pending', 'confirmed'])
        .get();

      for (const bDoc of pendingCustBookings.docs) {
        await bDoc.ref.update({
          status: 'cancelled',
          cancellationReason: 'account_deleted',
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
          cancelledBy: uid,
        });
        await bDoc.ref.collection('timeline').add({
          action: 'cancelled',
          type: 'cancelled',
          title: 'Booking Cancelled',
          description: 'Cancelled due to account deletion',
          actorUid: uid,
          actorRole: 'customer',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          at: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });

    // cancel pending or confirmed provider bookings
    await runStep('cancel_provider_bookings', async () => {
      const pendingProvBookings = await db
        .collection('bookings')
        .where('providerId', '==', uid)
        .where('status', 'in', ['pending', 'confirmed'])
        .get();

      for (const bDoc of pendingProvBookings.docs) {
        await bDoc.ref.update({
          status: 'cancelled',
          cancellationReason: 'account_deleted',
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
          cancelledBy: uid,
        });
        await bDoc.ref.collection('timeline').add({
          action: 'cancelled',
          type: 'cancelled',
          title: 'Booking Cancelled',
          description: 'Cancelled due to account deletion',
          actorUid: uid,
          actorRole: 'provider',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          at: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });

    // delete storage files in backblaze (all versions and delete markers)
    await runStep('delete_public_storage', async () => {
      const publicS3 = getS3Client(false);
      await deleteS3Prefix(publicS3, bucketName, `uploads/${uid}/`);
    });

    await runStep('delete_private_storage', async () => {
      const privateS3 = getS3Client(true);
      const privateBucket = (process.env.B2_PRIVATE_BUCKET || '').trim();
      if (privateBucket) {
        await deleteS3Prefix(privateS3, privateBucket, `nic/${uid}/`);
        await deleteS3Prefix(privateS3, privateBucket, `certs/${uid}/`);
      }
    });

    // process customer job requests: delete private subcollection, anonymize or delete post
    await runStep('process_customer_job_requests', async () => {
      const custJobsSnap = await db
        .collection('jobRequests')
        .where('customerId', '==', uid)
        .get();

      for (const jDoc of custJobsSnap.docs) {
        // delete private subcollection docs
        const privSnap = await jDoc.ref.collection('private').get();
        for (const p of privSnap.docs) {
          await p.ref.delete();
        }

        // check if any booking or provider's quote depends on it
        const bSnap = await db.collection('bookings').where('jobRequestId', '==', jDoc.id).limit(1).get();
        const hasBooking = !bSnap.empty;

        const qSnap = await jDoc.ref.collection('quotes').get();
        const hasQuote = !qSnap.empty;

        if (hasBooking || hasQuote) {
          // anonymize job doc
          await jDoc.ref.update({
            status: 'cancelled',
            customerName: 'Deleted user',
            customerPhone: admin.firestore.FieldValue.delete(),
            address: admin.firestore.FieldValue.delete(),
            landmark: admin.firestore.FieldValue.delete(),
            houseNo: admin.firestore.FieldValue.delete(),
            street: admin.firestore.FieldValue.delete(),
            city: admin.firestore.FieldValue.delete(),
            directions: admin.firestore.FieldValue.delete(),
            accuracyMeters: admin.firestore.FieldValue.delete(),
            note: admin.firestore.FieldValue.delete(),
            photos: [],
            photoUrls: [],
            video: null,
            videoUrl: null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          // delete quotes subcollection docs and delete the job doc fully
          for (const q of qSnap.docs) {
            await q.ref.delete();
          }
          await jDoc.ref.delete();
        }
      }
    });

    // anonymize user in historical bookings
    await runStep('anonymize_customer_bookings', async () => {
      const custHistory = await db.collection('bookings').where('customerId', '==', uid).get();
      for (const doc of custHistory.docs) {
        const bData = doc.data() || {};
        const updates = {
          customerName: 'Deleted user',
          customerPhone: admin.firestore.FieldValue.delete(),
          customerAddress: admin.firestore.FieldValue.delete(),
          address: admin.firestore.FieldValue.delete(),
          entryInstructions: admin.firestore.FieldValue.delete(),
          directions: admin.firestore.FieldValue.delete(),
          houseNo: admin.firestore.FieldValue.delete(),
          street: admin.firestore.FieldValue.delete(),
          landmark: admin.firestore.FieldValue.delete(),
          accuracyMeters: admin.firestore.FieldValue.delete(),
          note: admin.firestore.FieldValue.delete(),
        };
        // round coordinates to keep area only (~1km)
        if (typeof bData.customerLatitude === 'number') {
          updates.customerLatitude = Math.round(bData.customerLatitude * 100) / 100;
        }
        if (typeof bData.customerLongitude === 'number') {
          updates.customerLongitude = Math.round(bData.customerLongitude * 100) / 100;
        }
        await doc.ref.update(updates);
      }
    });

    await runStep('anonymize_provider_bookings', async () => {
      const provHistory = await db.collection('bookings').where('providerId', '==', uid).get();
      for (const doc of provHistory.docs) {
        await doc.ref.update({
          providerName: 'Deleted user',
          providerPhone: admin.firestore.FieldValue.delete(),
        });
      }
    });

    // anonymize reviews
    await runStep('anonymize_reviews', async () => {
      const custReviews = await db.collection('reviews').where('customerId', '==', uid).get();
      for (const doc of custReviews.docs) {
        await doc.ref.update({ customerName: 'Deleted user' });
      }
      const provReviews = await db.collection('reviews').where('providerId', '==', uid).get();
      for (const doc of provReviews.docs) {
        await doc.ref.update({ providerName: 'Deleted user' });
      }
    });

    // anonymize chat rooms
    await runStep('anonymize_chat_rooms', async () => {
      const chatRoomsSnap = await db.collection('chatRooms').where('participants', 'array-contains', uid).get();
      for (const doc of chatRoomsSnap.docs) {
        const updates = {};
        updates[`participantNames.${uid}`] = 'Deleted user';
        updates[`participantPhones.${uid}`] = admin.firestore.FieldValue.delete();
        await doc.ref.update(updates);
      }
    });

    // anonymize complaints
    await runStep('anonymize_complaints', async () => {
      const complaintsSnap = await db.collection('complaints').where('reporterUid', '==', uid).get();
      for (const doc of complaintsSnap.docs) {
        await doc.ref.update({
          reporterName: 'Deleted user',
          reporterPhone: admin.firestore.FieldValue.delete(),
        });
      }
    });

    // anonymize call logs
    await runStep('anonymize_call_logs', async () => {
      const callerLogs = await db.collection('callLogs').where('callerUid', '==', uid).get();
      for (const doc of callerLogs.docs) {
        await doc.ref.update({
          callerName: 'Deleted user',
          callerPhone: admin.firestore.FieldValue.delete(),
        });
      }
      const calleeLogs = await db.collection('callLogs').where('calleeUid', '==', uid).get();
      for (const doc of calleeLogs.docs) {
        await doc.ref.update({
          calleeName: 'Deleted user',
          calleePhone: admin.firestore.FieldValue.delete(),
        });
      }
    });

    // delete subcollections of user profile
    await runStep('delete_user_profile', async () => {
      const userRef = db.collection('users').doc(uid);
      await deleteCollection(userRef.collection('savedAddresses'));
      await deleteCollection(userRef.collection('blocked'));
      await deleteCollection(userRef.collection('private'));
      await deleteCollection(userRef.collection('fcmTokens'));
      await deleteCollection(userRef.collection('notifications'));
      await userRef.delete();
    });

    // delete subcollections of technician profile
    await runStep('delete_technician_profile', async () => {
      const techRef = db.collection('technicians').doc(uid);
      await deleteCollection(techRef.collection('private'));
      await deleteCollection(techRef.collection('portfolio'));
      await techRef.delete();
    });

    // delete verification queue record
    await runStep('delete_verification_queue', async () => {
      await db.collection('verificationQueue').doc(uid).delete();
    });

    // delete live location record
    await runStep('delete_live_location', async () => {
      await db.collection('liveLocations').doc(uid).delete();
    });

    // delete firebase auth user last
    await runStep('delete_auth_user', async () => {
      try {
        await admin.auth().deleteUser(uid);
      } catch (authErr) {
        console.error('Failed to delete auth user record:', authErr.message);
        throw authErr;
      }
    });

    return res.status(200).json({
      success: true,
      message: 'Account successfully deleted and personal data purged.',
      failedSteps,
    });
  } catch (err) {
    console.error('Error deleting account:', err);
    return res.status(500).json({
      error: 'Failed to delete account. Please contact support.',
    });
  }
};
