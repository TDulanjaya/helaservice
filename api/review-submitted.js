const { admin, db } = require('./_firebase');
const { verifyFirebaseToken } = require('./_auth');

// recompute provider rating, review count, and jobs count server side after review submission
module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const decodedUser = await verifyFirebaseToken(req, res);
  if (!decodedUser) return;
  const callerUid = decodedUser.uid;

  const { bookingId } = req.body || {};
  if (!bookingId || typeof bookingId !== 'string') {
    return res.status(400).json({ error: 'bookingId is required' });
  }

  try {
    const bookingSnap = await db.collection('bookings').doc(bookingId).get();
    if (!bookingSnap.exists) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    const bookingData = bookingSnap.data() || {};
    if (bookingData.customerId !== callerUid) {
      return res.status(403).json({ error: 'Caller is not the booking customer' });
    }

    if (bookingData.status !== 'completed') {
      return res.status(400).json({ error: 'Booking is not completed' });
    }

    const providerId = bookingData.providerId;
    if (!providerId) {
      return res.status(400).json({ error: 'Provider ID missing from booking' });
    }

    const reviewSnap = await db.collection('reviews').doc(bookingId).get();
    if (!reviewSnap.exists) {
      return res.status(404).json({ error: 'Review does not exist for this booking' });
    }

    // fetch all reviews for provider
    const reviewsQuery = await db
      .collection('reviews')
      .where('providerId', '==', providerId)
      .get();

    let sum = 0;
    let count = 0;
    reviewsQuery.forEach((doc) => {
      const data = doc.data();
      if (typeof data.rating === 'number' && data.rating >= 1 && data.rating <= 5) {
        sum += data.rating;
        count++;
      }
    });

    const averageRating = count > 0 ? Number((sum / count).toFixed(1)) : 5.0;

    // fetch total completed bookings for provider
    const completedJobsQuery = await db
      .collection('bookings')
      .where('providerId', '==', providerId)
      .where('status', '==', 'completed')
      .get();

    const jobsCount = completedJobsQuery.size;

    // update technician document via Admin SDK
    await db.collection('technicians').doc(providerId).set(
      {
        rating: averageRating,
        reviewCount: count,
        jobsCount: jobsCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return res.status(200).json({
      success: true,
      providerId,
      rating: averageRating,
      reviewCount: count,
      jobsCount,
    });
  } catch (err) {
    console.error('Review submitted handler error:', err);
    return res.status(500).json({ error: err.message || 'Internal server error' });
  }
};
