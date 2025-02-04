import 'package:flutter/material.dart';

class SubmitButton extends StatelessWidget {
  final bool isLogin;
  final bool isLoading;
  final VoidCallback onSubmit;

  const SubmitButton({
    super.key,
    required this.isLogin,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onSubmit,
      child: Text(isLogin ? 'Login' : 'Sign Up'),
    );
  }
}

class AuthToggleButton extends StatelessWidget {
  final bool isLogin;
  final bool isLoading;
  final VoidCallback onToggle;

  const AuthToggleButton({
    super.key,
    required this.isLogin,
    required this.isLoading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onToggle,
      child: Text(
        isLogin ? 'Need an account? Sign up' : 'Have an account? Login',
      ),
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const GoogleSignInButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.g_mobiledata),
          SizedBox(width: 8),
          Text('Sign in with Google'),
        ],
      ),
    );
  }
}

class ForgotPasswordButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const ForgotPasswordButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: const Text('Forgot Password?'),
    );
  }
} 