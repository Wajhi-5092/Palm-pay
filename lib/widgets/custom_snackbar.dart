import 'dart:ui';
import 'package:flutter/material.dart';

enum SnackbarType { success, error, warning, info }

class CustomSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    SnackbarType type = SnackbarType.info,
  }) {
    Color accentColor;
    IconData icon;

    // Define colors perfectly matching your PayPalm theme
    switch (type) {
      case SnackbarType.success:
        accentColor = const Color(0xFF00D1B2); // Brand Teal
        icon = Icons.check_circle_outline_rounded;
        break;
      case SnackbarType.error:
        accentColor = const Color(0xFFFF4B4B); // Vibrant Red
        icon = Icons.error_outline_rounded;
        break;
      case SnackbarType.warning:
        accentColor = const Color(0xFFFFB020); // Warning Orange
        icon = Icons.warning_amber_rounded;
        break;
      case SnackbarType.info:
        accentColor = const Color(0xFF3A86FF); // Accent Blue
        icon = Icons.info_outline_rounded;
        break;
    }

    // Hide any currently visible snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Show the custom glassmorphism snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        duration: const Duration(seconds: 3),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Glowing Icon Container
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  
                  // Message
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
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
