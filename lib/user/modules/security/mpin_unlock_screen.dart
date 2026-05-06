import 'package:flutter/material.dart';
import 'package:paypalm/screens/auth_choice_screen.dart';
import 'package:paypalm/services/auth_service.dart';
import 'package:paypalm/services/mpin_service.dart';
import 'package:paypalm/user/screens/home_page.dart';
import 'package:paypalm/widgets/custom_snackbar.dart';

class MpinUnlockScreen extends StatefulWidget {
  const MpinUnlockScreen({super.key});

  @override
  State<MpinUnlockScreen> createState() => _MpinUnlockScreenState();
}

class _MpinUnlockScreenState extends State<MpinUnlockScreen> {
  final _mpinController = TextEditingController();
  final _mpinService = MpinService();
  bool _submitting = false;

  @override
  void dispose() {
    _mpinController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final input = _mpinController.text.trim();
    if (input.length != 4) {
      CustomSnackbar.show(
        context: context,
        message: 'Enter a valid 4-digit MPIN',
        type: SnackbarType.warning,
      );
      return;
    }

    setState(() => _submitting = true);
    final isValid = await _mpinService.verifyMpin(input);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!isValid) {
      CustomSnackbar.show(
        context: context,
        message: 'Incorrect MPIN',
        type: SnackbarType.error,
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Future<void> _logoutAndUsePassword() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Quick Login with MPIN',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your 4-digit MPIN to continue.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mpinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'MPIN',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _submitting ? null : _unlock,
                    child: Text(_submitting ? 'Checking...' : 'Login Instantly'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _logoutAndUsePassword,
                    child: const Text('Use password instead'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
