import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/technician.dart';

class TechnicianRepository {
  final _col = FirebaseFirestore.instance.collection(FirestorePaths.technicians);

  Stream<List<Technician>> streamTechnicians() {
    return _col.snapshots().map((snap) {
      final items =
          snap.docs.map((d) => Technician.fromMap(d.id, d.data())).toList();
      items.sort((a, b) => b.rating.compareTo(a.rating));
      return items;
    });
  }

  Future<Technician?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Technician.fromMap(doc.id, doc.data()!);
  }
}
