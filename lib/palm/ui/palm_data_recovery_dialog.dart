import 'package:flutter/material.dart';
import 'package:paypalm/screens/auth_choice_screen.dart';

/// When Firestore / Auth data is missing or unreachable after a palm flow.
Future<void> showPalmFirestoreRecoveryDialog({
  required BuildContext context,
  required String message,
  required bool merchantFlow,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: Text(merchantFlow ? 'Could not load customer' : 'Could not save palm data'),
        content: SingleChildScrollView(
          child: Text(
            message.isNotEmpty
                ? message
                : 'Check your connection and account. You may need to sign in again or re-register your palm.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (!merchantFlow)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const AuthChoiceScreen(),
                  ),
                  (_) => false,
                );
              },
              child: const Text('Sign in or register'),
            ),
        ],
      );
    },
  );
}
