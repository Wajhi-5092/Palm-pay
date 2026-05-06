import 'package:shared_preferences/shared_preferences.dart';

class MpinService {
  static const String _mpinKey = 'user_mpin';
  static const String _enabledOnReopenKey = 'mpin_enabled_on_reopen';

  Future<bool> hasMpin() async {
    final prefs = await SharedPreferences.getInstance();
    final mpin = prefs.getString(_mpinKey);
    return mpin != null && mpin.length == 4;
  }

  Future<void> setMpin(String mpin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mpinKey, mpin);
  }

  Future<bool> verifyMpin(String input) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_mpinKey);
    return saved != null && saved == input;
  }

  Future<void> removeMpin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mpinKey);
    await prefs.setBool(_enabledOnReopenKey, false);
  }

  Future<bool> isEnabledOnReopen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledOnReopenKey) ?? false;
  }

  Future<void> setEnabledOnReopen(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledOnReopenKey, enabled);
  }
}
