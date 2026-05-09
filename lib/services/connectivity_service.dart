import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports whether the device has an active network interface (Wi‑Fi, cellular,
/// ethernet, VPN, etc.). This avoids false "offline" states common when probing
/// arbitrary hosts on restrictive Wi‑Fi networks.
///
/// Actual reachability (Firebase, APIs) is validated by those calls; this gate
/// only prevents blocking users who are clearly on a network.
class ConnectivityService {
  final Connectivity _connectivity;

  Stream<bool>? _internetStream;

  ConnectivityService({
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  Stream<bool> get onInternetAvailable {
    _internetStream ??= _buildStream();
    return _internetStream!;
  }

  Future<bool> isInternetAvailable() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _isConnectivityResultOnline(result);
    } catch (_) {
      return false;
    }
  }

  Stream<bool> _buildStream() {
    final controller = StreamController<bool>.broadcast();

    void emit(bool value) {
      if (!controller.isClosed) controller.add(value);
    }

    Future<void> emitLatest() async {
      emit(await isInternetAvailable());
    }

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
