import 'package:shared_preferences/shared_preferences.dart';

class LocalAppStateService {
  static const String _balanceKey = 'wallet_balance';
  static const String _nameKey = 'profile_name';
  static const String _phoneKey = 'profile_phone';
  static const String _emailKey = 'profile_email';
  static const String _notificationsKey = 'notifications_enabled';

  static const double defaultBalance = 10090.86;
  static const double resetBalanceValue = 50000.0;

  Future<void> ensureDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_balanceKey)) {
      await prefs.setDouble(_balanceKey, defaultBalance);
    }
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

  Future<double> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_balanceKey) ?? defaultBalance;
  }

  Future<double> addDemoMoney(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getDouble(_balanceKey) ?? defaultBalance;
    final updated = current + amount;
    await prefs.setDouble(_balanceKey, updated);
    return updated;
  }

  Future<double> setDemoMoney(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, amount);
    return amount;
  }

  Future<double> clearDemoMoney() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, 0);
    return 0;
  }

  Future<double> resetDemoMoney() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, resetBalanceValue);
    return resetBalanceValue;
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
