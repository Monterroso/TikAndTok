import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/widgets/video_viewing/custom_bottom_navigation_bar.dart';
import 'package:flutter_application_1/screens/profile_screen.dart';
import 'package:flutter_application_1/screens/saved_videos_screen.dart';

void main() {
  group('CustomBottomNavigationBar Tests', () {
    testWidgets('renders all buttons correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigationBar(),
          ),
        ),
      );

      // Verify all buttons are present
      expect(find.byIcon(Icons.collections_bookmark), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      // Verify tooltips
      expect(find.byTooltip('Collections'), findsOneWidget);
      expect(find.byTooltip('Profile'), findsOneWidget);
    });

    testWidgets('navigates to SavedVideosScreen when collections button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigationBar(),
          ),
        ),
      );

      // Tap collections button
      await tester.tap(find.byIcon(Icons.collections_bookmark));
      await tester.pumpAndSettle();

      // Verify navigation to SavedVideosScreen
      expect(find.byType(SavedVideosScreen), findsOneWidget);
    });

    testWidgets('navigates to ProfileScreen when profile button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigationBar(),
          ),
        ),
      );

      // Tap profile button
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Verify navigation to ProfileScreen
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('upload button is centered and visually distinct',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigationBar(),
          ),
        ),
      );

      // Find the upload button
      final uploadButton = find.byType(ElevatedButton);
      expect(uploadButton, findsOneWidget);

      // Verify it's a circle button
      final buttonShape = tester
          .widget<ElevatedButton>(uploadButton)
          .style
          ?.shape
          ?.resolve({});
      expect(buttonShape, isA<CircleBorder>());
    });
  });
} 