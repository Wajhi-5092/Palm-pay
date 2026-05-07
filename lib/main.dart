import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:paypalm/screens/splash_screen.dart';
import 'package:paypalm/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:paypalm/screens/auth_choice_screen.dart';
import 'package:paypalm/services/auth_session_service.dart';
import 'package:paypalm/services/auth_service.dart';
import 'package:paypalm/services/connectivity_service.dart';
import 'package:paypalm/services/mpin_service.dart';
import 'package:paypalm/user/modules/security/mpin_unlock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Set persistence to LOCAL for web only. Mobile platforms handle this automatically.
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  final _authSession = AuthSessionService();
  final _connectivity = ConnectivityService();
  final _mpinService = MpinService();

  StreamSubscription<bool>? _internetSub;
  Timer? _inactivityTimer;
  Timer? _sessionExpiryTimer;

  bool _isOnline = true;
  bool _routingInProgress = false;

  static const Duration inactivityTimeout = Duration(minutes: 10);
  static const Duration expiryCheckInterval = Duration(minutes: 1);

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, () async {
      if (_routingInProgress) return;

      // Only enforce inactivity timeout if user is actually logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // Not logged in, skip inactivity check

      _routingInProgress = true;

      try {
        final sessionOk = await _authSession.hasValidCachedSession();
        if (!sessionOk) {
          await AuthService().logout(clearMpin: false);
          if (!mounted) return;
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
            (route) => false,
          );
          return;
        }

        final hasMpin = await _mpinService.hasMpin();
        final mpinOnReopen = await _mpinService.isEnabledOnReopen();

        if (hasMpin && mpinOnReopen) {
          if (!mounted) return;
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MpinUnlockScreen()),
            (route) => false,
          );
        } else {
          // No MPIN quick-login enabled: require full sign-in again.
          await AuthService().logout(clearMpin: false);
          if (!mounted) return;
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
            (route) => false,
          );
        }
      } finally {
        _routingInProgress = false;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _internetSub = _connectivity.onInternetAvailable.listen((online) async {
      if (!mounted) return;
      setState(() => _isOnline = online);
      await _authSession.tryRefreshSessionIfNeeded(isOnline: online);
    });

    _resetInactivityTimer();

    _sessionExpiryTimer = Timer.periodic(expiryCheckInterval, (_) async {
      if (!mounted) return;

      // Only check session expiry if user is actually logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // Not logged in, no need to check

      final expired = await _authSession.isAppSessionExpired();
      if (!expired) return; // Session still valid

      // Session expired: require full sign-in again (but keep MPIN metadata).
      await AuthService().logout(clearMpin: false);
      if (!mounted) return;
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _internetSub?.cancel();
    _inactivityTimer?.cancel();
    _sessionExpiryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        _authSession.touchActivity();
        _resetInactivityTimer();
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            MaterialApp(
              navigatorKey: _navigatorKey,
              title: 'PayPalm App',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: const SplashScreen(),
            ),
            if (!_isOnline)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: AnimatedOpacity(
                  opacity: _isOnline ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No Internet Connection',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
