import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local demo wallet + profile defaults. **Demo balances are stored per Firebase user**
/// (`demo_wallet_v1_<uid>`) so edits never leak across accounts on a shared device.
class LocalAppStateService {
  /// Legacy global key (pre per-user storage). Migrated once into the signed-in
  /// user's bucket, then removed.
  static const String _legacyBalanceKey = 'wallet_balance';

  static const String _nameKey = 'profile_name';
  static const String _phoneKey = 'profile_phone';
  static const String _emailKey = 'profile_email';
  static const String _notificationsKey = 'notifications_enabled';

  static const double defaultBalance = 10090.86;
  static const double resetBalanceValue = 50000.0;

  static String _demoWalletKey(String uid) => 'demo_wallet_v1_$uid';

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// Ensures this signed-in user has a demo-wallet row: [defaultBalance] for a
  /// new account, or preserved per-user value after the first run.
  Future<void> _ensureDemoWalletForCurrentUser() async {
    final uid = _currentUid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _demoWalletKey(uid);
    if (prefs.containsKey(key)) return;

    double initial = defaultBalance;
    if (prefs.containsKey(_legacyBalanceKey)) {
      final legacy = prefs.getDouble(_legacyBalanceKey);
      initial = legacy ?? defaultBalance;
      await prefs.remove(_legacyBalanceKey);
    }
    await prefs.setDouble(key, initial);
  }

  Future<void> ensureDefaults() async {
    await _ensureDemoWalletForCurrentUser();

    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_nameKey)) {
      await prefs.setString(_nameKey, 'PayPalm User');
    }
    if (!prefs.containsKey(_phoneKey)) {
      await prefs.setString(_phoneKey, '0318 3116227');
    }
    if (!prefs.containsKey(_emailKey)) {
      await prefs.setString(_emailKey, 'user@paypalm.app');
    }
    if (!prefs.containsKey(_notificationsKey)) {
      await prefs.setBool(_notificationsKey, true);
    }
  }

  /// Demo balance for the **current** user only.
  Future<double> getBalance() async {
    final uid = _currentUid;
    if (uid == null) return defaultBalance;
    await _ensureDemoWalletForCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_demoWalletKey(uid)) ?? defaultBalance;
  }

  Future<double> addDemoMoney(double amount) async {
    final uid = _currentUid;
    if (uid == null) {
      throw StateError('Demo wallet: not signed in');
    }
    await _ensureDemoWalletForCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    final key = _demoWalletKey(uid);
    final current = prefs.getDouble(key) ?? defaultBalance;
    final updated = current + amount;
    await prefs.setDouble(key, updated);
    return updated;
  }

  Future<double> setDemoMoney(double amount) async {
    final uid = _currentUid;
    if (uid == null) {
      throw StateError('Demo wallet: not signed in');
    }
    await _ensureDemoWalletForCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_demoWalletKey(uid), amount);
    return amount;
  }

  Future<double> clearDemoMoney() async {
    final uid = _currentUid;
    if (uid == null) {
      throw StateError('Demo wallet: not signed in');
    }
    await _ensureDemoWalletForCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_demoWalletKey(uid), 0);
    return 0;
  }

  /// Sets this user's demo balance to [resetBalanceValue] (e.g. quick reset in Add Cash).
  Future<double> resetDemoMoney() async {
    final uid = _currentUid;
    if (uid == null) {
      throw StateError('Demo wallet: not signed in');
    }
    await _ensureDemoWalletForCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_demoWalletKey(uid), resetBalanceValue);
    return resetBalanceValue;
  }

  /// Restores this user's demo balance to the **app default** ([defaultBalance]).
  Future<double> resetDemoMoneyToDefault() async {
    final uid = _currentUid;
    if (uid == null) {
      throw StateError('Demo wallet: not signed in');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_demoWalletKey(uid), defaultBalance);
    return defaultBalance;
  }

  Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? 'PayPalm User';
  }

  Future<String> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey) ?? '0318 3116227';
  }

  Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? 'user@paypalm.app';
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
    await prefs.setString(_phoneKey, phone.trim());
    await prefs.setString(_emailKey, email.trim());
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }
}
