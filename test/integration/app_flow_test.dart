import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypticdash/main.dart';

void main() {
  setUpAll(() {
    // Initialize Flutter bindings for testing
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('CrypticDash App Flow', () {
    testWidgets('app launches and shows auth screen', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const CrypticDashApp());
      
      // Wait for the app to fully initialize
      await tester.pumpAndSettle();

      // Verify that our app shows the auth screen initially
      expect(find.text('Connect to GitHub'), findsOneWidget);
    });

    testWidgets('app has proper navigation structure', (WidgetTester tester) async {
      await tester.pumpWidget(const CrypticDashApp());
      await tester.pumpAndSettle();

      // Check that the app has the basic structure
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Check that the main app widget exists
      expect(find.byType(CrypticDashApp), findsOneWidget);
    });
  });
}
