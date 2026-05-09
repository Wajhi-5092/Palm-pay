import 'package:flutter/material.dart';

class PalmRegistrationSuccessScreen extends StatelessWidget {
  const PalmRegistrationSuccessScreen({
    super.key,
    required this.completedAt,
  });

  final DateTime completedAt;

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00D1B2);
    final fmt =
        '${completedAt.year}-${completedAt.month.toString().padLeft(2, '0')}-${completedAt.day.toString().padLeft(2, '0')} '
        '${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.verified_rounded, size: 88, color: teal),
              const SizedBox(height: 24),
              Text(
                'Palm Registered Successfully',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Encrypted biometric template uploaded. Raw images are not stored.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black54,
                    ),
              ),
              const SizedBox(height: 32),
              _row(Icons.calendar_today_outlined, 'Completed', fmt),
              const SizedBox(height: 16),
              _row(Icons.security_rounded, 'Protection', 'AES-256 • Server-side sealing'),
              const SizedBox(height: 32),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3A86FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.black54),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}
