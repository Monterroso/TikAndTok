import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_snackbars.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _isLogin = true; // Toggle between login and signup
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter an email address';
    }
    final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _authService.signInUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _authService.signUpUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          VerificationSnackBar(
            message: e.toString(),
            context: context,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithGoogle();
      // No need to navigate, AuthWrapper will handle it
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EmailField(
                      controller: _emailController,
                      validator: _validateEmail,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _passwordController,
                      validator: _validatePassword,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 24),
                    SubmitButton(
                      isLogin: _isLogin,
                      isLoading: _isLoading,
                      onSubmit: _submitForm,
                    ),
                    const SizedBox(height: 16),
                    GoogleSignInButton(
                      isLoading: _isLoading,
                      onPressed: _signInWithGoogle,
                    ),
                    if (_isLogin) ...[
                      const SizedBox(height: 16),
                      ForgotPasswordButton(
                        isLoading: _isLoading,
                        onPressed: _resetPassword,
                      ),
                    ],
                    const SizedBox(height: 16),
                    AuthToggleButton(
                      isLogin: _isLogin,
                      isLoading: _isLoading,
                      onToggle: () => setState(() => _isLogin = !_isLogin),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
