import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// A screen that displays and allows editing of the user's profile information.
/// This includes their username, bio, and profile picture.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isUploadingImage = false;

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService().signOutUser();
      if (mounted) {
        Navigator.of(context).pop(); // Pop the profile screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _pickImage(String uid, ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512, // Reasonable size for profile pictures
        maxHeight: 512,
        imageQuality: 85, // Good quality but smaller file size
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      try {
        final String photoURL = await FirebaseStorageService().uploadProfileImage(
          uid: uid,
          file: File(image.path),
        );

        await FirestoreService().updateUserProfile(
          uid: uid,
          photoURL: photoURL,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile picture: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploadingImage = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to access camera/gallery. Please check app permissions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Profile Picture'),
        content: const Text('Choose a source:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(uid, ImageSource.gallery);
            },
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(uid, ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<User?>(context);
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().streamUserProfile(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return const Center(child: Text('No profile data available'));
          }

          final profileData = snapshot.data!.data()!;
          
          // Set initial values if controllers are empty
          if (_usernameController.text.isEmpty) {
            _usernameController.text = profileData['username'] ?? '';
          }
          if (_bioController.text.isEmpty) {
            _bioController.text = profileData['bio'] ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile picture section
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _isUploadingImage 
                          ? null 
                          : () => _showImageSourceDialog(user.uid),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: profileData['photoURL']?.isNotEmpty == true
                              ? NetworkImage(profileData['photoURL']!)
                              : null,
                          child: _isUploadingImage
                              ? const CircularProgressIndicator()
                              : profileData['photoURL']?.isNotEmpty != true
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                        ),
                      ),
                      if (!_isUploadingImage)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              onPressed: () => _showImageSourceDialog(user.uid),
                              constraints: const BoxConstraints(
                                minWidth: 35,
                                minHeight: 35,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Username field
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (value.length > 30) {
                        return 'Username must be less than 30 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                        return 'Username can only contain letters, numbers, and underscores';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Bio field
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value != null && value.length > 150) {
                        return 'Bio must not exceed 150 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Update button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isUploadingImage
                          ? null
                          : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                setState(() => _isLoading = true);
                                try {
                                  await FirestoreService().updateUserProfile(
                                    uid: user.uid,
                                    username: _usernameController.text,
                                    bio: _bioController.text,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Profile updated successfully'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error updating profile: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Update Profile'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 