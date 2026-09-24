import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/category_item.dart';
import '../models/admin_models.dart';

class CategoryRepository {
  final _col = FirebaseFirestore.instance.collection(FirestorePaths.categories);

  Stream<List<CategoryItem>> streamCategories() {
    return _col.snapshots().map((snap) {
      final items =
          snap.docs.map((d) => CategoryItem.fromMap(d.id, d.data())).toList();
      items.sort((a, b) => a.label.compareTo(b.label));
      return items;
    });
  }

  Stream<List<CategoryRow>> streamCategoryRows() {
    return _col.snapshots().map((snap) {
      final items =
          snap.docs.map((d) => CategoryRow.fromMap(d.id, d.data())).toList();
      items.sort((a, b) => a.name.compareTo(b.name));
      return items;
    });
  }

  Future<void> addCategory(CategoryRow category) async {
    final docId = category.id.isNotEmpty
        ? category.id
        : category.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    await _col.doc(docId).set(category.toMap(), SetOptions(merge: true));
  }
}

