import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/admin_models.dart';

class DistrictRepository {
  final _col =
      FirebaseFirestore.instance.collection(FirestorePaths.districtStats);

  Stream<List<DistrictLoad>> streamDistrictLoads() {
    return _col.snapshots().map((snap) {
      return snap.docs
          .map((d) => DistrictLoad.fromMap(d.id, d.data()))
          .toList();
    });
  }

  Stream<List<ExpansionDistrict>> streamExpansionDistricts() {
    return _col.snapshots().map((snap) {
      return snap.docs
          .map((d) => ExpansionDistrict.fromMap(d.id, d.data()))
          .toList();
    });
  }

  Future<void> saveDistrict(String id, Map<String, dynamic> data) async {
    await _col.doc(id).set(data, SetOptions(merge: true));
  }
}
