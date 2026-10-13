import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/saved_address.dart';

class SavedAddressRepository {
  static final SavedAddressRepository _instance = SavedAddressRepository._();
  factory SavedAddressRepository() => _instance;
  SavedAddressRepository._();

  CollectionReference<Map<String, dynamic>> _userAddressesCol(String userId) {
    return FirebaseFirestore.instance
        .collection(FirestorePaths.users)
        .doc(userId)
        .collection('savedAddresses');
  }

  Stream<List<SavedAddress>> streamSavedAddresses(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _userAddressesCol(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SavedAddress.fromFirestore(d)).toList());
  }

  Future<List<SavedAddress>> getSavedAddresses(String userId) async {
    if (userId.isEmpty) return [];
    final snap = await _userAddressesCol(userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => SavedAddress.fromFirestore(d)).toList();
  }

  Future<String> addSavedAddress({
    required String userId,
    required String label,
    required double latitude,
    required double longitude,
    required String address,
    String? landmark,
    String? note,
    double? accuracyMeters,
    String? houseNo,
    String? street,
    String? city,
    String? directions,
  }) async {
    final noteVal = (note != null && note.isNotEmpty) ? note : landmark;
    final ref = await _userAddressesCol(userId).add({
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      if (noteVal != null && noteVal.isNotEmpty) 'note': noteVal,
      if (noteVal != null && noteVal.isNotEmpty) 'landmark': noteVal,
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      if (houseNo != null && houseNo.isNotEmpty) 'houseNo': houseNo,
      if (street != null && street.isNotEmpty) 'street': street,
      if (city != null && city.isNotEmpty) 'city': city,
      if (directions != null && directions.isNotEmpty) 'directions': directions,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateSavedAddress({
    required String userId,
    required String addressId,
    required String label,
    String? address,
    String? landmark,
    String? note,
  }) async {
    final Map<String, dynamic> updates = {'label': label};
    if (address != null) updates['address'] = address;
    final noteVal = (note != null && note.isNotEmpty) ? note : landmark;
    if (noteVal != null) {
      updates['note'] = noteVal;
      updates['landmark'] = noteVal;
    }
    await _userAddressesCol(userId).doc(addressId).update(updates);
  }

  Future<void> deleteSavedAddress({
    required String userId,
    required String addressId,
  }) async {
    await _userAddressesCol(userId).doc(addressId).delete();
  }
}
