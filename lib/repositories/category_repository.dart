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

  Stream<List<CategoryRow>> streamLiveCategories() {
    return streamCategoryRows().map((list) => list.where((c) => c.isLive).toList());
  }

  Future<void> addCategory(CategoryRow category) async {
    final docId = category.id.isNotEmpty
        ? category.id
        : 'cat_${category.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}';
    
    // Check if category already exists to avoid unintended overwrite
    final existing = await _col.doc(docId).get();
    if (existing.exists && category.id.isEmpty) {
      throw Exception('Category with ID "$docId" already exists. Please choose a different name.');
    }

    await _col.doc(docId).set(category.toMap(), SetOptions(merge: true));
  }

  Future<void> updateCategory(CategoryRow category) async {
    if (category.id.isEmpty) {
      throw Exception('Category ID cannot be empty for update.');
    }
    final data = category.toMap();
    data['basePrice'] = FieldValue.delete();
    await _col.doc(category.id).set(data, SetOptions(merge: true));
  }

  Future<void> toggleCategoryStatus(String id, String currentStatus) async {
    final newActive = currentStatus.toLowerCase() != 'active';
    final newStatus = newActive ? 'active' : 'paused';
    await _col.doc(id).update({
      'status': newStatus,
      'isLive': newActive,
      'basePrice': FieldValue.delete(),
    });
  }

  Future<void> toggleCategoryLive(String id, bool currentIsLive) async {
    final newLive = !currentIsLive;
    await _col.doc(id).update({
      'isLive': newLive,
      'status': newLive ? 'active' : 'paused',
      'basePrice': FieldValue.delete(),
    });
  }

  Future<void> toggleCategoryDistrict(
      String id, String district, bool isCurrentlyAssigned) async {
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
  }

  Future<void> deleteCategory(String id) async {
    // 1. Check if category is used by any technician via count() aggregate
    final techCountSnap = await FirebaseFirestore.instance
        .collection('technicians')
        .where('category', isEqualTo: id)
        .count()
        .get();
    final techCount = techCountSnap.count ?? 0;

    // 2. Check if category is used by any jobRequest via count() aggregate
    final jobCountSnap = await FirebaseFirestore.instance
        .collection('jobRequests')
        .where('category', isEqualTo: id)
        .count()
        .get();
    final jobCount = jobCountSnap.count ?? 0;

    if (techCount > 0 || jobCount > 0) {
      throw Exception(
        'Cannot delete category "$id": it is currently in use by $techCount provider(s) and $jobCount job request(s).',
      );
    }

    await _col.doc(id).delete();
  }
}
