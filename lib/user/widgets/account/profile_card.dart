import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  static String _initials(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    final parts =
        t.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList(growable: false);
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color.fromARGB(255, 0, 62, 104);
    final authUser = FirebaseAuth.instance.currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmall = width < 350;

        if (authUser == null) {
          return Container(
            padding: EdgeInsets.all(isSmall ? 14 : 20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Sign in to see your profile.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return Container(
          padding: EdgeInsets.all(isSmall ? 14 : 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(authUser.uid)
                .snapshots(),
            builder: (context, snap) {
              final data = snap.data?.data();
              final nameFs = (data?['name'] as String?)?.trim();
              final displayName = (nameFs != null && nameFs.isNotEmpty)
                  ? nameFs
                  : (authUser.displayName?.trim().isNotEmpty == true
                      ? authUser.displayName!.trim()
                      : 'PayPalm User');

              final phone = (data?['phone'] as String?)?.trim();
              final emailFs = (data?['email'] as String?)?.trim();
              final email = (emailFs != null && emailFs.isNotEmpty)
                  ? emailFs
                  : (authUser.email ?? '');

              return Row(
                children: [
                  Container(
                    width: isSmall ? 55 : 70,
                    height: isSmall ? 55 : 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.tealAccent, width: 2),
                      image: authUser.photoURL != null &&
                              authUser.photoURL!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(authUser.photoURL!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (authUser.photoURL == null ||
                            authUser.photoURL!.isEmpty)
                        ? Center(
                            child: Text(
                              _initials(displayName),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: isSmall ? 16 : 18,
                              ),
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: isSmall ? 10 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmall ? 15 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildEditButton(cardColor, isSmall),
                          ],
                        ),

                        SizedBox(height: isSmall ? 2 : 4),

                        if (phone != null && phone.isNotEmpty)
                          Text(
                            phone,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmall ? 11 : 13,
                            ),
                          ),

                        if (email.isNotEmpty)
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isSmall ? 10 : 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEditButton(Color color, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit,
            size: isSmall ? 10 : 12,
            color: color,
          ),
          SizedBox(width: isSmall ? 2 : 4),
          Text(
            'Edit',
            style: TextStyle(
              color: color,
              fontSize: isSmall ? 10 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
