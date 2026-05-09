import 'package:flutter/material.dart';

class AccountSectionGroup extends StatelessWidget {
  final List<Widget> children;
  const AccountSectionGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 0,
            offset: Offset(0, -2), // Top highlight edge
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
