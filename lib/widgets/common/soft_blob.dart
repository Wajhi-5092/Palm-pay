import 'package:flutter/material.dart';

/// Soft circle highlight without [BackdropFilter] (much cheaper on GPU).
class SoftBlob extends StatelessWidget {
  final double size;
  final Color color;

  const SoftBlob({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.4,
              spreadRadius: size * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}
