# Migration Guide: CocoaPods to Swift Package Manager (SPM)

## Table of Contents
1. [Overview](#overview)
2. [Current Project State](#current-project-state)
3. [Pre-Migration Steps](#pre-migration-steps)
4. [Migration Process](#migration-process)
5. [Testing Strategy](#testing-strategy)
6. [Troubleshooting](#troubleshooting)
7. [Rollback Plan](#rollback-plan)

## Overview

This document outlines the process of migrating our TikTok Clone iOS dependencies from CocoaPods to Swift Package Manager (SPM). This migration aims to improve build times and resolve ongoing CocoaPods-related issues.

### Benefits of Migration
- Faster build times
- Native integration with Xcode
- Simplified dependency management
- Better caching and incremental builds
- No need for external dependency managers

## Current Project State

### Flutter Dependencies
```yaml
# Firebase dependencies
firebase_core: ^3.10.1
firebase_auth: ^5.4.1
firebase_storage: ^12.4.1
firebase_messaging: ^15.2.1
cloud_firestore: ^5.6.2

# Authentication
google_sign_in: ^6.1.0

# Media handling
video_player: ^2.8.1
image_picker: ^1.0.7
```

### iOS Configuration
- Minimum iOS version: 13.0
- Current dependency manager: CocoaPods
- Build configuration: Debug, Profile, Release

## Pre-Migration Steps

### 1. Project Backup
```bash
# Create a backup branch
git checkout -b backup/cocoapods-setup
git add .
git commit -m "Backup before SPM migration"
git push origin backup/cocoapods-setup

# Create a new branch for migration
git checkout -b feature/spm-migration
```

### 2. Document Current Settings
- Screenshot or document current build settings
- Export scheme configurations
- Note all CocoaPods configurations and versions
- Document any custom build phases or scripts

### 3. Environment Setup
- Update Xcode to latest version
- Clean build folder and derived data
- Document current build times for comparison

## Migration Process

### Step 1: Remove CocoaPods

1. Clean up CocoaPods files:
```bash
cd ios
pod deintegrate
rm Podfile
rm Podfile.lock
rm -rf Pods
```

2. Clean Xcode project:
```bash
cd ..
rm -rf ios/Runner.xcworkspace
xcodebuild clean -workspace ios/Runner.xcworkspace -scheme Runner
```

### Step 2: Update Xcode Project

1. Open `.xcodeproj` file in Xcode
2. Update build settings:
   - Verify minimum deployment target (iOS 13.0)
   - Remove CocoaPods-related build phases
   - Update framework search paths
   - Clean up any CocoaPods-related configurations

### Step 3: Add SPM Dependencies

1. In Xcode:
   - File > Add Packages
   - Add the following packages:

2. Firebase SDK:
   ```
   Repository: https://github.com/firebase/firebase-ios-sdk
   Version: Up to Next Major (latest stable)
   Required Products:
   - FirebaseAnalytics
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseMessaging
   ```

3. Google Sign In:
   ```
   Repository: https://github.com/google/GoogleSignIn-iOS
   Version: Up to Next Major (latest stable)
   ```

4. Additional Dependencies:
   - Add any other native iOS dependencies required by Flutter plugins

### Step 4: Update Build Settings

1. Framework Search Paths:
   - Remove CocoaPods-related paths
   - Add SPM package paths if necessary

2. Header Search Paths:
   - Update for SPM structure
   - Remove CocoaPods-related paths

3. Other Linker Flags:
   - Update as needed for SPM
   - Remove CocoaPods-specific flags

4. Build Phases:
   - Remove CocoaPods-related scripts
   - Add any necessary SPM-related build phases

### Step 5: Flutter Integration

1. Update Flutter configuration:
   ```bash
   flutter clean
   flutter pub get
   cd ios
   flutter build ios --no-codesign
   ```

2. Verify plugin registration in `ios/Runner/GeneratedPluginRegistrant.m`

## Testing Strategy

### 1. Functionality Testing

Test each major feature:
- [ ] Firebase Authentication
- [ ] Google Sign-in
- [ ] Cloud Firestore operations
- [ ] Firebase Storage uploads/downloads
- [ ] Push notifications
- [ ] Video playback
- [ ] Image picker
- [ ] All other app-specific features

### 2. Performance Testing

Compare metrics:
- [ ] Clean build time
- [ ] Incremental build time
- [ ] App launch time
- [ ] Memory usage
- [ ] Binary size

### 3. Integration Testing

- [ ] Run automated test suite
- [ ] Verify CI/CD pipeline
- [ ] Test on different iOS versions
- [ ] Test on different devices

## Troubleshooting

### Common Issues and Solutions

1. Missing Frameworks
```
Solution: Verify SPM package products are properly selected in Xcode
```

2. Build Errors
```
Solution: Clean build folder and derived data, then rebuild
```

3. Linking Issues
```
Solution: Check framework search paths and linked libraries
```

4. Plugin Compatibility
```
Solution: Verify Flutter plugin versions support SPM
```

## Rollback Plan

### If Migration Fails

1. Restore CocoaPods setup:
```bash
git checkout backup/cocoapods-setup
```

2. Reinstall pods:
```bash
cd ios
pod install
```

3. Rebuild project:
```bash
flutter clean
flutter pub get
cd ios
pod install
flutter build ios
```

### Documentation Updates

After successful migration:
1. Update README.md with new build instructions
2. Update CI/CD configuration
3. Update development environment setup guide
4. Document any new requirements or dependencies

## Migration Checklist

Pre-Migration:
- [ ] Create backup branch
- [ ] Document current setup
- [ ] Verify SPM support for all dependencies
- [ ] Update Xcode

Migration:
- [ ] Remove CocoaPods
- [ ] Configure SPM
- [ ] Update build settings
- [ ] Test functionality
- [ ] Update CI/CD

Post-Migration:
- [ ] Update documentation
- [ ] Train team on new workflow
- [ ] Monitor for issues
- [ ] Clean up backup branches (after successful migration)

## Support

For issues or questions about this migration:
- Create an issue in the project repository
- Reference this document
- Include relevant logs and error messages
- Document any solutions found for future reference
