import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:paypalm/screens/auth_choice_screen.dart';
import 'package:paypalm/services/auth_service.dart';
import 'package:paypalm/services/auth_session_service.dart';
import 'package:paypalm/services/connectivity_service.dart';
import 'package:paypalm/services/mpin_service.dart';
import 'package:paypalm/user/screens/home_page.dart';
import 'package:paypalm/user/screens/login_screen.dart';
import 'package:paypalm/widgets/custom_snackbar.dart';

class MpinUnlockScreen extends StatefulWidget {
  const MpinUnlockScreen({super.key});

  @override
  State<MpinUnlockScreen> createState() => _MpinUnlockScreenState();
}

class _MpinUnlockScreenState extends State<MpinUnlockScreen> {
  final _mpinController = TextEditingController();
  final _mpinService = MpinService();
  final _authSession = AuthSessionService();

  final _localAuth = LocalAuthentication();
  final _connectivity = ConnectivityService();
  StreamSubscription<bool>? _internetSub;

  bool _submitting = false;
  bool _biometricAvailable = false;
  bool _isOnline = true;
  int _mpinLength = 4;
  int _lockRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    _internetSub = _connectivity.onInternetAvailable.listen((available) {
      if (!mounted) return;
      setState(() => _isOnline = available);
    });
  }

  Future<void> _loadInitialState() async {
    final length = await _mpinService.getMpinLength();
    bool deviceSupported = false;
    bool canCheck = false;

    if (!kIsWeb) {
      try {
        deviceSupported = await _localAuth.isDeviceSupported();
        canCheck = await _localAuth.canCheckBiometrics;
      } catch (_) {
        deviceSupported = false;
        canCheck = false;
      }
    }

    final online = await _connectivity.isInternetAvailable();

    if (!mounted) return;
    setState(() {
      _mpinLength = (length == 4 || length == 6) ? length : 4;
      _biometricAvailable = deviceSupported && canCheck;
      _isOnline = online;
    });

    await _refreshLockUI();
  }

  Future<void> _refreshLockUI() async {
    final remaining = await _mpinService.getLockRemainingSeconds();
    if (!mounted) return;
    setState(() => _lockRemainingSeconds = remaining);
  }

  @override
  void dispose() {
    _internetSub?.cancel();
    _mpinController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlocked() async {
    final sessionOk = await _authSession.hasValidCachedSession();
    if (!sessionOk) {
      if (!_isOnline) {
        // Session requires online re-auth; wait for connectivity before redirecting.
        if (!mounted) return;
        final dialogFuture = showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return AlertDialog(
              title: const Text('No Internet Connection'),
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Waiting for connection to restore…',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          },
        );

        try {
          await _connectivity.onInternetAvailable.firstWhere((v) => v);
        } finally {
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
        }
        await dialogFuture;
      }

      await AuthService().logout(clearMpin: false);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
        (route) => false,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await AuthService().logout(clearMpin: false);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
        (route) => false,
      );
      return;
    }

    if (_isOnline) {
      try {
        await _authSession.persistSessionFromUser(user, pendingRefresh: false);
      } catch (_) {
        await _authSession.setPendingRefresh(true);
      }
    } else {
      await _authSession.setPendingRefresh(true);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Future<void> _unlock() async {
    setState(() => _submitting = true);
    try {
      final input = _mpinController.text.trim();
      if (input.length != _mpinLength || !RegExp(r'^\d+$').hasMatch(input)) {
        CustomSnackbar.show(
          context: context,
          message: 'Enter a valid $_mpinLength-digit MPIN',
          type: SnackbarType.warning,
        );
        return;
      }

      final result = await _mpinService.verifyMpin(input);
      if (!mounted) return;

      if (result.state == MpinVerificationState.locked) {
        await _refreshLockUI();
        if (!mounted) return;
        CustomSnackbar.show(
          context: context,
          message: 'Too many attempts. Try again soon.',
          type: SnackbarType.error,
        );
        return;
      }

      if (result.state != MpinVerificationState.valid) {
        _mpinController.clear();
        await _refreshLockUI();
        if (!mounted) return;
        CustomSnackbar.show(
          context: context,
          message: 'Incorrect MPIN',
          type: SnackbarType.error,
        );
        return;
      }

      await _handleUnlocked();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _logoutAndUsePassword() async {
    // Fallback auth: clear session, but keep MPIN metadata.
    await AuthService().logout(clearMpin: false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _biometricUnlock() async {
    if (_lockRemainingSeconds > 0) {
      await _refreshLockUI();
      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        message: 'Temporarily locked due to multiple failed attempts.',
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Unlock PayPalm with biometrics',
        biometricOnly: true,
      );

      if (!mounted) return;
      if (!didAuth) return;

      await _handleUnlocked();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentBlue = Color(0xFF3A86FF);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Welcome back',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      _isOnline
                          ? 'Instant login with your MPIN'
                          : 'Offline mode: instant login works, sync later',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_lockRemainingSeconds > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Too many attempts. Try again in $_lockRemainingSeconds sec.',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _mpinController,
                      keyboardType: TextInputType.number,
                      maxLength: _mpinLength,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: 'MPIN ($_mpinLength digits)',
                        border: const OutlineInputBorder(),
                        counterText: '',
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: accentBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: (_submitting || _lockRemainingSeconds > 0)
                          ? null
                          : _unlock,
                      child: Text(_submitting ? 'Checking...' : 'Login'),
                    ),
                    const SizedBox(height: 10),
                    if (_biometricAvailable)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (_submitting || _lockRemainingSeconds > 0)
                              ? null
                              : _biometricUnlock,
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: const Text('Use Fingerprint'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _submitting ? null : _logoutAndUsePassword,
                      child: const Text('Login with Email Instead'),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
