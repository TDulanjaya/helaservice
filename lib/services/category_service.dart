import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/admin_models.dart';
import '../l10n/app_localizations.dart';

// live cache of categories
class CategoryService extends ChangeNotifier {
  CategoryService._();
  static final CategoryService instance = CategoryService._();

  final Map<String, CategoryRow> _categoriesById = {};
  bool _isInitialized = false;
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  Map<String, CategoryRow> get categoriesById => Map.unmodifiable(_categoriesById);
  List<CategoryRow> get allCategories => _categoriesById.values.toList();
  List<CategoryRow> get liveCategories =>
      _categoriesById.values.where((c) => c.isLive).toList();

  // start category listener
  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    _isLoading = true;

    _subscription = FirebaseFirestore.instance
        .collection(FirestorePaths.categories)
        .snapshots()
        .listen(
      (snapshot) {
        _categoriesById.clear();
        for (final doc in snapshot.docs) {
          try {
            final cat = CategoryRow.fromMap(doc.id, doc.data());
            _categoriesById[doc.id] = cat;
            _categoriesById[doc.id.toLowerCase()] = cat;
          } catch (e) {
            debugPrint('[CategoryService] Failed to parse category ${doc.id}: $e');
          }
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        debugPrint('[CategoryService] Error listening to categories: $err');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // get category name by id
  String nameOf(String? id, {BuildContext? context, Locale? locale}) {
    final fallbackLabel = context != null
        ? AppLocalizations.of(context)?.genericService ?? 'Service'
        : 'Service';

    if (id == null) return fallbackLabel;
    final trimmed = id.trim();
    if (trimmed.isEmpty) return fallbackLabel;

    final cat = _categoriesById[trimmed] ?? _categoriesById[trimmed.toLowerCase()];
    if (cat == null) {
      return fallbackLabel;
    }

    if (cat.name.trim().isNotEmpty) {
      return cat.name.trim();
    }

    return fallbackLabel;
  }

  // get full category row by id
  CategoryRow? getCategory(String? id) {
    if (id == null) return null;
    final trimmed = id.trim();
    return _categoriesById[trimmed] ?? _categoriesById[trimmed.toLowerCase()];
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
