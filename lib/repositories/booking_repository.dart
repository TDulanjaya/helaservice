import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/booking.dart';

class BookingRepository {
  final _col = FirebaseFirestore.instance.collection(FirestorePaths.bookings);

  Future<void> createBooking(Booking booking) async {
    await _col.add(booking.toMap());
  }

  Stream<List<Booking>> streamBookingsForProvider(String providerId) {
    return _col.where('providerId', isEqualTo: providerId).snapshots().map((snap) {
      final items = snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Stream<List<Booking>> streamBookingsForCustomer(String customerId) {
    return _col.where('customerId', isEqualTo: customerId).snapshots().map((snap) {
      final items = snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }
}
