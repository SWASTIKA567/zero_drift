import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapping_showcase/main.dart';
import 'package:mapping_showcase/services/storage_service.dart';

void main() {
  testWidgets('ZeroDriftApp renders splash screen and transitions to login',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(ZeroDriftApp(storageService: storageService));

    // Verify splash branding is rendered
    expect(find.text('ZERO '), findsOneWidget);
    expect(find.text('DRIFT'), findsOneWidget);
    expect(find.text('Intelligent Dead Reckoning System'), findsOneWidget);
    expect(find.text('GNSS CONNECTED'), findsOneWidget);

    // Advance time beyond splash delay (2200ms) and animation transition
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pumpAndSettle();

    // Verify transition to Login screen
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    expect(find.text('Username or Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
  });
}
