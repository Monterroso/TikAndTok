import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'email_verification_banner.dart';

class ProfileCard extends StatelessWidget {
  final User? user;

  const ProfileCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserInfoRow(user: user),
            if (!AuthService().isEmailVerified && user?.email != null) ...[
              const SizedBox(height: 16),
              EmailVerificationBanner(),
            ],
          ],
        ),
      ),
    );
  }
}

class UserInfoRow extends StatelessWidget {
  final User? user;

  const UserInfoRow({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UserAvatar(photoURL: user?.photoURL),
        const SizedBox(width: 16),
        Expanded(
          child: UserDetails(
            displayName: user?.displayName,
            email: user?.email,
          ),
        ),
      ],
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String? photoURL;

  const UserAvatar({
    super.key,
    this.photoURL,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundImage: photoURL != null ? NetworkImage(photoURL!) : null,
      child: photoURL == null ? const Icon(Icons.person) : null,
    );
  }
}

class UserDetails extends StatelessWidget {
  final String? displayName;
  final String? email;

  const UserDetails({
    super.key,
    this.displayName,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName ?? 'Anonymous User',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (email != null) ...[
          const SizedBox(height: 4),
          Text(
            email!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
} 