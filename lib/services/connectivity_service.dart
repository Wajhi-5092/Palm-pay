import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  final InternetConnectionChecker _internetChecker;

  Stream<bool>? _internetStream;

  ConnectivityService({
    Connectivity? connectivity,
  })  : _connectivity = connectivity ?? Connectivity(),
        // internet_connection_checker v3 uses createInstance().
        _internetChecker = InternetConnectionChecker.createInstance();

  Stream<bool> get onInternetAvailable {
    _internetStream ??= _buildStream();
    return _internetStream!;
  }

  Future<bool> isInternetAvailable() async {
    if (kIsWeb) {
      final result = await _connectivity.checkConnectivity();
      return _isConnectivityResultOnline(result);
    }
    return _internetChecker.hasConnection;
  }

  Stream<bool> _buildStream() {
    final controller = StreamController<bool>.broadcast();

    void emit(bool value) {
      if (!controller.isClosed) controller.add(value);
    }

    Future<void> emitLatest() async {
      try {
        final online = kIsWeb
            ? _isConnectivityResultOnline(
                await _connectivity.checkConnectivity())
            : await _internetChecker.hasConnection;
        emit(online);
      } catch (_) {
        emit(false);
      }
    }

    // Initial state.
    emitLatest();

    _connectivity.onConnectivityChanged.listen((_) async {
      await emitLatest();
    }, onError: (_) {
      emit(false);
    });

    return controller.stream;
  }

  bool _isConnectivityResultOnline(Object? result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    if (result is Iterable<ConnectivityResult>) {
      return result.any((value) => value != ConnectivityResult.none);
    }
    return false;
  }
}
