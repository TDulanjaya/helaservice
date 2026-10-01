import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/admin_models.dart';

class CategoryRepository {
  final _col = FirebaseFirestore.instance.collection(FirestorePaths.categories);

  Stream<List<CategoryRow>> streamCategoryRows() {
    return _col.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return const <CategoryRow>[];
      }
      final items =
          snap.docs.map((d) => CategoryRow.fromMap(d.id, d.data())).toList();
      items.sort((a, b) => a.name.compareTo(b.name));
      return items;
    });
  }

  Future<void> addCategory(CategoryRow category) async {
    final docId = category.id.isNotEmpty
        ? category.id
        : 'cat_${category.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}';
    await _col.doc(docId).set(category.toMap(), SetOptions(merge: true));
  }

  Future<void> toggleCategoryStatus(String id, String currentStatus) async {
    final newStatus =
        (currentStatus.toLowerCase() == 'active') ? 'Paused' : 'Active';
    await _col.doc(id).update({'status': newStatus}).catchError((_) {});
  }

  Future<void> toggleCategoryDistrict(
      String id, String district, bool isCurrentlyAssigned) async {
    try {
      final doc = await _col.doc(id).get();
      List<String> districts = [];
      List<String> districtsOff = [];
      if (doc.exists && doc.data() != null) {
        districts = List<String>.from(doc.data()!['districts'] ?? []);
        districtsOff = List<String>.from(doc.data()!['districtsOff'] ?? []);
      }

      if (isCurrentlyAssigned) {
        districts.remove(district);
        if (!districtsOff.contains(district)) districtsOff.add(district);
      } else {
        districtsOff.remove(district);
        if (!districts.contains(district)) districts.add(district);
      }

      await _col.doc(id).set({
        'districts': districts,
        'districtsOff': districtsOff,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> deleteCategory(String id) async {
    await _col.doc(id).delete().catchError((_) {});
  }
}
