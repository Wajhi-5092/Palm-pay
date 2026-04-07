import 'package:flutter/material.dart';
import 'account_selector.dart';
import 'profile_card.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        ProfileCard(),
        SizedBox(height: 20),
        AccountSelector(),
      ],
    );
  }
}
