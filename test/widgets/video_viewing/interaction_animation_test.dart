import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/widgets/video_viewing/interaction_animation.dart';

void main() {
  group('InteractionAnimation Widget Tests', () {
    testWidgets('renders correctly when inactive', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractionAnimation(
              isActive: false,
              count: 10,
              onTap: () {},
              activeIcon: Icons.favorite,
              inactiveIcon: Icons.favorite_border,
              activeColor: Colors.red,
            ),
          ),
        ),
      );

      // Verify inactive state
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('renders correctly when active', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractionAnimation(
              isActive: true,
              count: 10,
              onTap: () {},
              activeIcon: Icons.favorite,
              inactiveIcon: Icons.favorite_border,
              activeColor: Colors.red,
            ),
          ),
        ),
      );

      // Verify active state
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('handles tap correctly', (WidgetTester tester) async {
      bool wasTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractionAnimation(
              isActive: false,
              count: 10,
              onTap: () => wasTapped = true,
              activeIcon: Icons.favorite,
              inactiveIcon: Icons.favorite_border,
              activeColor: Colors.red,
            ),
          ),
        ),
      );

      // Tap the icon
      await tester.tap(find.byType(InteractionAnimation));
      await tester.pump();

      // Verify callback was called
      expect(wasTapped, true);
    });

    testWidgets('hides count when showCount is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractionAnimation(
              isActive: false,
              count: 10,
              onTap: () {},
              activeIcon: Icons.favorite,
              inactiveIcon: Icons.favorite_border,
              activeColor: Colors.red,
              showCount: false,
            ),
          ),
        ),
      );

      // Verify count is not shown
      expect(find.text('10'), findsNothing);
    });

    testWidgets('uses correct colors for active/inactive states', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractionAnimation(
              isActive: true,
              count: 10,
              onTap: () {},
              activeIcon: Icons.bookmark,
              inactiveIcon: Icons.bookmark_border,
              activeColor: Colors.amber,
              inactiveColor: Colors.grey,
            ),
          ),
        ),
      );

      // Find the Icon widget
      final Icon icon = tester.widget<Icon>(find.byType(Icon));
      
      // Verify the color is amber (active color)
      expect(icon.color, Colors.amber);

      // Rebuild with inactive state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractionAnimation(
              isActive: false,
              count: 10,
              onTap: () {},
              activeIcon: Icons.bookmark,
              inactiveIcon: Icons.bookmark_border,
              activeColor: Colors.amber,
              inactiveColor: Colors.grey,
            ),
          ),
        ),
      );
      await tester.pump();

      // Find the new Icon widget
      final Icon inactiveIcon = tester.widget<Icon>(find.byType(Icon));
      
      // Verify the color is grey (inactive color)
      expect(inactiveIcon.color, Colors.grey);
    });
  });
} 