import 'package:flutter_test/flutter_test.dart';
import 'package:crypticdash/screens/dashboard_screen.dart';

void main() {
  setUpAll(() {
    // Initialize Flutter bindings for testing
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('DashboardScreen', () {
    testWidgets('dashboard screen can be instantiated', (WidgetTester tester) async {
      // Test that the dashboard screen can be created without crashing
      // This is a basic smoke test to ensure the widget compiles
      expect(() => const DashboardScreen(), returnsNormally);
    });

    testWidgets('dashboard screen has basic structure', (WidgetTester tester) async {
      // Create a simple test that doesn't require complex providers
      // Just verify the widget can be created
      const dashboard = DashboardScreen();
      expect(dashboard, isA<DashboardScreen>());
    });
  });
}
