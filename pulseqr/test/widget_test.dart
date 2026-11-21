import 'package:flutter_test/flutter_test.dart';

import 'package:pulseqr/main.dart';

void main() {
  testWidgets('PulseQR auth screen renders the create-account view', (WidgetTester tester) async {
    await tester.pumpWidget(const PulseQrApp(connected: false));

    expect(find.text('Establish Institutional Identity'), findsOneWidget);
    expect(find.text('Institutional Role'.toUpperCase()), findsOneWidget);
    expect(find.text('Create Student Account'), findsOneWidget);
  });

  testWidgets('Switching to Sign In shows the sign-in form', (WidgetTester tester) async {
    await tester.pumpWidget(const PulseQrApp(connected: false));

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Sign In as Student'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });
}
