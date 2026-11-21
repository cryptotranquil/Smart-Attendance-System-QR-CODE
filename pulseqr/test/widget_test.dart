// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:pulseqr/main.dart';

void main() {
  testWidgets('MyApp displays PulseQR title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(connected: false));

    // Verify that our app shows PulseQR
    expect(find.text('PulseQR'), findsOneWidget);
  });

  testWidgets('AuthPreviewScreen displays welcome message', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(connected: false));

    // Verify the preview text
    expect(find.textContaining('Design preview'), findsOneWidget);
  });
}