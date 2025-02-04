import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class EmailVerificationBanner extends StatelessWidget {
  const EmailVerificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade900,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Please verify your email address',
              style: TextStyle(
                color: Colors.orange.shade900,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await AuthService().resendVerificationEmail();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification email sent'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Resend'),
          ),
        ],
      ),
    );
  }
} 