import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/portfolio_item.dart';

class PortfolioRepository {
  CollectionReference _portfolioCol(String providerId) {
    return FirebaseFirestore.instance
        .collection(FirestorePaths.technicians)
        .doc(providerId)
        .collection('portfolio');
  }

  // stream portfolio items for provider
  Stream<List<PortfolioItem>> streamPortfolio(String providerId,
      {bool approvedOnly = false}) {
    if (providerId.isEmpty) return Stream.value([]);
    Query query =
        _portfolioCol(providerId).orderBy('createdAt', descending: true);
    if (approvedOnly) {
      query = query.where('isApproved', isEqualTo: true);
    }
    return query.snapshots().map((snap) {
      return snap.docs
          .map((d) =>
              PortfolioItem.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // add new portfolio item
  Future<String> addPortfolioItem({
    required String providerId,
    required String title,
    required String photoUrl,
    String description = '',
    String category = '',
  }) async {
    final docRef = _portfolioCol(providerId).doc();
    final item = PortfolioItem(
      id: docRef.id,
      providerId: providerId,
      title: title,
      description: description,
      photoUrl: photoUrl,
      category: category,
      createdAt: DateTime.now(),
      isApproved: true,
    );
    await docRef.set(item.toMap());
    return docRef.id;
  }

  // delete portfolio item
  Future<void> deletePortfolioItem(String providerId, String itemId) async {
    if (providerId.isEmpty || itemId.isEmpty) return;
    await _portfolioCol(providerId).doc(itemId).delete();
  }

  // toggle portfolio item approval status
  Future<void> toggleApproval(
      String providerId, String itemId, bool approved) async {
    if (providerId.isEmpty || itemId.isEmpty) return;
    await _portfolioCol(providerId)
        .doc(itemId)
        .update({'isApproved': approved});
  }
}
