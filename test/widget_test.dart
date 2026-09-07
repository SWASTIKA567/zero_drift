import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapping_showcase/main.dart';
import 'package:mapping_showcase/models/auth_models.dart';
import 'package:mapping_showcase/screens/home_screen.dart';
import 'package:mapping_showcase/services/storage_service.dart';

void main() {
  testWidgets('ZeroDriftApp renders splash screen and transitions to login',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    // Test tapping Sign In with empty fields triggers validation
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your username or email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    // Scroll to and navigate to Sign Up screen
    final signUpButton = find.text('Sign Up');
    await tester.ensureVisible(signUpButton);
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();

    // Verify Sign Up form
    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Create Account'), findsOneWidget);

    // Scroll to and tap back to Sign In
    final signInLink = find.text('Sign In');
    await tester.ensureVisible(signInLink);
    await tester.tap(signInLink);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('HomeScreen renders normal zerodrift text in dashboard as requested',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();
    final testUser = UserModel(username: 'testUser', email: 'TestUser@gmail.com');

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          storageService: storageService,
          currentUser: testUser,
        ),
      ),
    );

    // Verify 'zerodrift' text is displayed normally
    expect(find.text('zerodrift'), findsWidgets);
    expect(find.text('testUser'), findsOneWidget);
    expect(find.text('TestUser@gmail.com'), findsOneWidget);
    expect(find.text('AUTHENTICATED'), findsOneWidget);
  });
}
