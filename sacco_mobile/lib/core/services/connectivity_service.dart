import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  StreamSubscription<bool>? _connectivitySubscription;
  
  ConnectivityService(this._connectivity);

  /// Check current connectivity status
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Get connectivity stream
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((results) {
      return !results.contains(ConnectivityResult.none);
    });
  }

  /// Listen to connectivity changes
  void startListening(Function(bool) onConnectivityChanged) {
    _connectivitySubscription = connectivityStream.listen(onConnectivityChanged);
  }

  /// Stop listening to connectivity changes
  void stopListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  void dispose() {
    stopListening();
  }
}