import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class VerificationSnackBar extends SnackBar {
  VerificationSnackBar({
    super.key,
    required String message,
    required BuildContext context,
  }) : super(
          content: Text(message),
          action: message.contains('verify your email')
              ? SnackBarAction(
                  label: 'Resend',
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
                )
              : null,
        );
} 