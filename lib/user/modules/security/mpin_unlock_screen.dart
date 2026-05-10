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

/// Where [MpinUnlockScreen] was opened from — adjusts headline copy only.
enum MpinUnlockMode {
  appResume,
  afterPasswordLogin,
}

class MpinUnlockScreen extends StatefulWidget {
  const MpinUnlockScreen({
    super.key,
    this.mode = MpinUnlockMode.appResume,
  });

  final MpinUnlockMode mode;

  @override
  State<MpinUnlockScreen> createState() => _MpinUnlockScreenState();
}

class _MpinUnlockScreenState extends State<MpinUnlockScreen>
    with TickerProviderStateMixin {
  final _mpinController = TextEditingController();
  final _focusNode = FocusNode();
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
  Timer? _lockTicker;

  /// Inline status — avoids stacking snackbars on a focused screen.
  String? _statusLine;
  _MpinStatusTone _statusTone = _MpinStatusTone.neutral;

  bool _contentVisible = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _successPulse = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]    ).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOutCubic),
    );

    _mpinController.addListener(_onPinChanged);

    _loadInitialState();
    _internetSub = _connectivity.onInternetAvailable.listen((available) {
      if (!mounted) return;
      setState(() => _isOnline = available);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _contentVisible = true);
      _focusNode.requestFocus();
    });
  }

  void _onPinChanged() {
    setState(() {
      if (_statusTone != _MpinStatusTone.warning) {
        _statusLine = null;
        _statusTone = _MpinStatusTone.neutral;
      }
    });
    final t = _mpinController.text;
    if (t.length == _mpinLength &&
        !_submitting &&
        _lockRemainingSeconds == 0) {
      _unlock();
    }
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
    _startLockTickerIfNeeded();
  }

  void _startLockTickerIfNeeded() {
    _lockTicker?.cancel();
    if (_lockRemainingSeconds <= 0) return;
    _lockTicker = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _refreshLockUI();
      if (!mounted) return;
      if (_lockRemainingSeconds <= 0) {
        _lockTicker?.cancel();
        _lockTicker = null;
        setState(() {
          _statusLine = null;
          _statusTone = _MpinStatusTone.neutral;
        });
      }
    });
  }

  Future<void> _refreshLockUI() async {
    final remaining = await _mpinService.getLockRemainingSeconds();
    if (!mounted) return;
    setState(() {
      _lockRemainingSeconds = remaining;
      if (remaining > 0) {
        _statusLine = 'Try again in ${remaining}s';
        _statusTone = _MpinStatusTone.warning;
      }
    });
    if (remaining > 0) _startLockTickerIfNeeded();
  }

  @override
  void dispose() {
    _lockTicker?.cancel();
    _internetSub?.cancel();
    _mpinController.removeListener(_onPinChanged);
    _shakeController.dispose();
    _mpinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleUnlocked() async {
    final sessionOk = await _authSession.hasValidCachedSession();
    if (!sessionOk) {
      if (!_isOnline) {
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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  Future<void> _unlock() async {
    if (_submitting || _lockRemainingSeconds > 0) return;

    final input = _mpinController.text.trim();
    if (input.length != _mpinLength || !RegExp(r'^\d+$').hasMatch(input)) {
      setState(() {
        _statusLine = 'Enter all $_mpinLength digits';
        _statusTone = _MpinStatusTone.error;
      });
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await _mpinService.verifyMpin(input);
      if (!mounted) return;

      if (result.state == MpinVerificationState.locked) {
        _mpinController.clear();
        await _refreshLockUI();
        if (!mounted) return;
        setState(() {
          _statusLine =
              'Too many attempts. Wait ${result.remainingSeconds ?? _lockRemainingSeconds}s';
          _statusTone = _MpinStatusTone.error;
        });
        return;
      }

      if (result.state != MpinVerificationState.valid) {
        _mpinController.clear();
        await _shakeController.forward(from: 0);
        await _refreshLockUI();
        if (!mounted) return;
        setState(() {
          _statusLine = 'Incorrect PIN';
          _statusTone = _MpinStatusTone.error;
        });
        _focusNode.requestFocus();
        return;
      }

      setState(() {
        _successPulse = true;
        _statusLine = null;
        _statusTone = _MpinStatusTone.neutral;
      });
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      await _handleUnlocked();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _logoutAndUsePassword() async {
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
      setState(() {
        _statusLine = 'Wait for the timer to unlock';
        _statusTone = _MpinStatusTone.warning;
      });
      return;
    }

    setState(() => _submitting = true);
    try {
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Unlock PayPalm',
        biometricOnly: true,
      );

      if (!mounted) return;
      if (!didAuth) return;

      setState(() => _successPulse = true);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      await _handleUnlocked();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static const _accent = Color(0xFF0F766E);
  static const _surface = Color(0xFFFAFAFA);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final text = _mpinController.text;
    final headline = widget.mode == MpinUnlockMode.afterPasswordLogin
        ? 'Enter your PIN'
        : 'Welcome back';
    final subline = widget.mode == MpinUnlockMode.afterPasswordLogin
        ? 'One quick step to open your wallet.'
        : (_isOnline
            ? 'Enter your PIN to continue'
            : 'Offline — enter your PIN to continue');

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: AnimatedOpacity(
          opacity: _contentVisible ? 1 : 0,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _minimalLogo(),
                      const SizedBox(height: 36),
                      Text(
                        headline,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: const Color(0xFF111827),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subline,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B7280),
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 40),
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: child,
                          );
                        },
                        child: AnimatedScale(
                          scale: _successPulse ? 1.02 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: _pinInputRow(text),
                        ),
                      ),
                      if (_statusLine != null) ...[
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _statusLine!,
                            key: ValueKey(_statusLine),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _toneColor(_statusTone),
                            ),
                          ),
                        ),
                      ],
                      if (_submitting && !_successPulse) ...[
                        const SizedBox(height: 18),
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      ],
                      const SizedBox(height: 36),
                      if (_biometricAvailable && !_successPulse)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: (_submitting || _lockRemainingSeconds > 0)
                                ? null
                                : _biometricUnlock,
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fingerprint_rounded,
                                    size: 26,
                                    color: _lockRemainingSeconds > 0
                                        ? const Color(0xFF9CA3AF)
                                        : _accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Use biometrics',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _lockRemainingSeconds > 0
                                          ? const Color(0xFF9CA3AF)
                                          : _accent,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: (_submitting || _successPulse)
                            ? null
                            : _logoutAndUsePassword,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                        ),
                        child: const Text('Sign in with password instead'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _minimalLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.lock_outline_rounded, color: _accent, size: 26),
      ),
    );
  }

  Widget _pinInputRow(String text) {
    final filled = text.length;
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_mpinLength, (i) {
                final isActive = i == filled && filled < _mpinLength;
                final isFilled = i < filled;
                final highlight = _successPulse && isFilled;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 46,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      width: isActive || highlight ? 2 : 1.2,
                      color: highlight
                          ? const Color(0xFF059669)
                          : isActive
                              ? _accent
                              : const Color(0xFFD1D5DB),
                    ),
                    color: highlight
                        ? const Color(0xFFECFDF5)
                        : isFilled
                            ? const Color(0xFFF9FAFB)
                            : Colors.white,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: isFilled
                          ? Padding(
                              key: ValueKey('d$i'),
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 28,
                                  height: 1,
                                  fontWeight: FontWeight.bold,
                                  color: highlight
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF1F2937),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                );
              }),
            ),
          ),
          Opacity(
            opacity: 0.008,
            child: SizedBox(
              width: 280,
              height: 58,
              child: TextField(
                controller: _mpinController,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                maxLength: _mpinLength,
                readOnly: _lockRemainingSeconds > 0,
                obscureText: false,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontSize: 1, height: 0.01),
                cursorColor: Colors.transparent,
                showCursor: false,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onSubmitted: (_) => _unlock(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _toneColor(_MpinStatusTone t) {
    switch (t) {
      case _MpinStatusTone.error:
        return const Color(0xFFB91C1C);
      case _MpinStatusTone.warning:
        return const Color(0xFFB45309);
      case _MpinStatusTone.neutral:
        return const Color(0xFF6B7280);
    }
  }
}

enum _MpinStatusTone { neutral, error, warning }
