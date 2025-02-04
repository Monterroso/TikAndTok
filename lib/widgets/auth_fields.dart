import 'package:flutter/material.dart';

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool enabled;

  const EmailField({
    super.key,
    required this.controller,
    required this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email',
        prefixIcon: Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: validator,
      enabled: enabled,
    );
  }
}

class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final bool enabled;

  const PasswordField({
    super.key,
    required this.controller,
    required this.validator,
    required this.obscureText,
    required this.onToggleVisibility,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: enabled ? onToggleVisibility : null,
        ),
      ),
      obscureText: obscureText,
      validator: validator,
      enabled: enabled,
    );
  }
} 