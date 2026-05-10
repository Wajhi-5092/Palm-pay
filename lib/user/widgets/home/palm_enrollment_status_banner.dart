import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paypalm/palm/services/palm_hand_id_service.dart';

/// Shows when this account already has a palm scan saved in Firestore.
class PalmEnrollmentStatusBanner extends StatelessWidget {
  const PalmEnrollmentStatusBanner({super.key});

  static String _formatSavedAt(dynamic raw) {
    if (raw is Timestamp) {
      final d = raw.toDate().toLocal();
      return DateFormat('MMM d, y • h:mm a').format(d);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.data();
        if (data == null) return const SizedBox.shrink();

        final registered = data['palmRegistered'] == true;
        final scan = data['palmScan'];
        final hasScan = scan is Map<String, dynamic>;

        if (!registered && !hasScan) {
          return const SizedBox.shrink();
        }

        final savedAtStr = hasScan ? _formatSavedAt(scan['savedAt']) : '';
        final handIdRaw = (data['handId'] as String?)?.trim() ??
            ((scan is Map<String, dynamic>)
                ? (scan['handId'] as String?)?.trim()
                : null);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
          child: Material(
            elevation: 2,
            shadowColor: const Color(0xFF00D1B2).withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00D1B2).withValues(alpha: 0.18),
                    const Color(0xFF3A86FF).withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFF00D1B2).withValues(alpha: 0.45),
                  width: 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D1B2).withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pan_tool_alt_rounded,
                      color: Color(0xFF00796B),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Palm already scanned',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                letterSpacing: 0.2,
                              ),
                        ),
                        const SizedBox(height: 4),
                        if (handIdRaw != null && handIdRaw.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Hand ID • ${PalmHandIdService.maskHandId(handIdRaw)}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ),
                        Text(
                          savedAtStr.isNotEmpty
                              ? 'Saved on $savedAtStr. You can scan again from Enroll Palm to replace it.'
                              : 'Your palm profile is on file. Scan again anytime to update it.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.verified_rounded,
                    color: const Color(0xFF00D1B2).withValues(alpha: 0.9),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
