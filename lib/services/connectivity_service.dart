import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isOfflineNotifier = ValueNotifier<bool>(false);
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isInitialized = false;

  bool get isOffline => isOfflineNotifier.value;

  // initialize connectivity monitoring
  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    _connectivity.checkConnectivity().then(_updateStatus).catchError((_) {});

    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateStatus,
      onError: (e) {
        debugPrint('[Connectivity] Status stream error: $e');
      },
    );
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (isOfflineNotifier.value != offline) {
      isOfflineNotifier.value = offline;
      if (kDebugMode) {
        debugPrint('[Connectivity] Network state changed: offline=$offline');
      }
    }
  }

  // manually recheck connectivity status
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      return !isOfflineNotifier.value;
    } catch (_) {
      return !isOfflineNotifier.value;
    }
  }

  void dispose() {
    _subscription?.cancel();
    isOfflineNotifier.dispose();
  }
}
