import 'package:flutter/material.dart';
import 'package:paypalm/palm/data/palm_simple_firestore_service.dart';
import 'package:paypalm/palm/ui/palm_scanner_screen.dart';

/// Routes to [PalmScannerScreen]. For **enrollment**, skips the scanner if a palm
/// is already saved unless the user chooses to replace it.
class PalmScanScreen extends StatelessWidget {
  const PalmScanScreen({
    super.key,
    required this.isRegistration,
    this.billAmount,
  });

  final bool isRegistration;
  final double? billAmount;

  PalmScannerPurpose get _purpose {
    if (isRegistration) return PalmScannerPurpose.registration;
    if (billAmount != null && billAmount! > 0) {
      return PalmScannerPurpose.merchantCheckout;
    }
    return PalmScannerPurpose.userVerification;
  }

  Widget _scanner() {
    return PalmScannerScreen(
      purpose: _purpose,
      checkoutAmount: billAmount,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isRegistration) {
      return _scanner();
    }

    return FutureBuilder<bool>(
      future: PalmSimpleFirestoreService.hasRegisteredPalm(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return _AlreadyRegisteredPalmView(
            onBack: () => Navigator.of(context).maybePop(),
            onReplace: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => PalmScannerScreen(
                    purpose: PalmScannerPurpose.registration,
                    checkoutAmount: billAmount,
                  ),
                ),
              );
            },
          );
        }
        return _scanner();
      },
    );
  }
}

class _AlreadyRegisteredPalmView extends StatelessWidget {
  const _AlreadyRegisteredPalmView({
    required this.onBack,
    required this.onReplace,
  });

  final VoidCallback onBack;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00D1B2);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF5F6F8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Back',
                  ),
                ),
                const Spacer(flex: 1),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_rounded,
                    size: 72,
                    color: teal.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Palm already scanned',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your palm is already enrolled. You do not need to scan again '
                  'unless you want to replace it with a new scan.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        height: 1.45,
                      ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: onBack,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF005CB8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onReplace,
                  child: const Text(
                    'Replace with new scan',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF316D99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
