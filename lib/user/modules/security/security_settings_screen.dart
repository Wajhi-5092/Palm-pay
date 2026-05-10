// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:paypalm/services/mpin_service.dart';
import 'package:paypalm/widgets/custom_snackbar.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _mpinService = MpinService();
  bool _hasMpin = false;
  bool _enableMpinOnReopen = false;
  int _mpinLength = 4;

  @override
  void initState() {
    super.initState();
    _loadSecurityState();
  }

  Future<void> _loadSecurityState() async {
    final hasMpin = await _mpinService.hasMpin();
    final enableMpinOnReopen = await _mpinService.isEnabledOnReopen();
    final mpinLength = await _mpinService.getMpinLength();
    if (!mounted) return;
    setState(() {
      _hasMpin = hasMpin;
      _enableMpinOnReopen = enableMpinOnReopen;
      _mpinLength = (mpinLength == 4 || mpinLength == 6) ? mpinLength : 4;
    });
  }

  Future<void> _showSetOrChangeMpinDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    int newLength = _mpinLength;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogInnerContext, setDialogState) {
            return AlertDialog(
              title: Text(_hasMpin ? 'Change MPIN' : 'Set MPIN'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hasMpin)
                      TextField(
                        controller: currentController,
                        keyboardType: TextInputType.number,
                        maxLength: _mpinLength,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Current MPIN',
                          counterText: '',
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<int>(
                            contentPadding: EdgeInsets.zero,
                            value: 4,
                            groupValue: newLength,
                            onChanged: (v) {
                              setDialogState(() => newLength = v ?? 4);
                              newController.clear();
                              confirmController.clear();
                            },
                            title: const Text('4-digit'),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<int>(
                            contentPadding: EdgeInsets.zero,
                            value: 6,
                            groupValue: newLength,
                            onChanged: (v) {
                              setDialogState(() => newLength = v ?? 6);
                              newController.clear();
                              confirmController.clear();
                            },
                            title: const Text('6-digit'),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: newController,
                      keyboardType: TextInputType.number,
                      maxLength: newLength,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New MPIN',
                        counterText: '',
                      ),
                    ),
                    TextField(
                      controller: confirmController,
                      keyboardType: TextInputType.number,
                      maxLength: newLength,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm MPIN',
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final newMpin = newController.text.trim();
                    final confirm = confirmController.text.trim();

                    if (newMpin.length != newLength ||
                        int.tryParse(newMpin) == null) {
                      CustomSnackbar.show(
                        context: dialogContext,
                        message: 'MPIN must be $newLength digits',
                        type: SnackbarType.warning,
                      );
                      return;
                    }

                    if (newMpin != confirm) {
                      CustomSnackbar.show(
                        context: dialogContext,
                        message: 'MPIN confirmation does not match',
                        type: SnackbarType.warning,
                      );
                      return;
                    }

                    if (_hasMpin) {
                      final verifyResult =
                          await _mpinService.verifyMpin(currentController.text);

                      if (!mounted) return;

                      if (verifyResult.state == MpinVerificationState.locked) {
                        if (!dialogContext.mounted) return;
                        CustomSnackbar.show(
                          context: dialogContext,
                          message:
                              'Too many attempts. Try again in ${verifyResult.remainingSeconds ?? ''} seconds.',
                          type: SnackbarType.error,
                        );
                        return;
                      }

                      if (verifyResult.state != MpinVerificationState.valid) {
                        if (!dialogContext.mounted) return;
                        CustomSnackbar.show(
                          context: dialogContext,
                          message: 'Current MPIN is incorrect',
                          type: SnackbarType.error,
                        );
                        return;
                      }
                    }

                    await _mpinService.setMpin(newMpin);
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    await _loadSecurityState();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Current Password'),
                ),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                final email = user.email;
                if (email == null || email.isEmpty) {
                  CustomSnackbar.show(
                    context: dialogContext,
                    message: 'Password change requires an email account',
                    type: SnackbarType.warning,
                  );
                  return;
                }

                try {
                  final credential = EmailAuthProvider.credential(
                    email: email,
                    password: currentController.text,
                  );
                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newController.text);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  if (!mounted) return;
                  CustomSnackbar.show(
                    context: context,
                    message: 'Password changed successfully',
                    type: SnackbarType.success,
                  );
                } catch (_) {
                  if (!dialogContext.mounted) return;
                  CustomSnackbar.show(
                    context: dialogContext,
                    message:
                        'Could not change password. Check current password.',
                    type: SnackbarType.error,
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleMpinOnReopen(bool value) async {
    if (value && !_hasMpin) {
      CustomSnackbar.show(
        context: context,
        message: 'Set MPIN first before enabling quick login',
        type: SnackbarType.warning,
      );
      return;
    }
    await _mpinService.setEnabledOnReopen(value);
    if (!mounted) return;
    setState(() => _enableMpinOnReopen = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              value: _enableMpinOnReopen,
              onChanged: _toggleMpinOnReopen,
              title: const Text('Login by MPIN on app reopen'),
              subtitle: const Text(
                'When enabled, app asks MPIN every time it reopens.',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: Text(_hasMpin ? 'Change MPIN' : 'Set MPIN'),
              subtitle: Text(_hasMpin
                  ? 'Update your $_mpinLength-digit MPIN (hashed and stored securely on this device)'
                  : 'Save a 4 or 6-digit MPIN securely. After you set it, sign-in with password will ask for this MPIN next.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _showSetOrChangeMpinDialog,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_reset_rounded),
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _changePassword,
            ),
          ),
        ],
      ),
    );
  }
}
