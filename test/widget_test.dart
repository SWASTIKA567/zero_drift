import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapping_showcase/main.dart';
import 'package:mapping_showcase/services/storage_service.dart';

void main() {
  testWidgets('ZeroDriftApp smoke test renders splash screen branding',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(ZeroDriftApp(storageService: storageService));

    // Verify splash branding is rendered
    expect(find.text('ZERO '), findsOneWidget);
    expect(find.text('DRIFT'), findsOneWidget);
    expect(find.text('Intelligent Dead Reckoning System'), findsOneWidget);
    expect(find.text('GNSS CONNECTED'), findsOneWidget);
  });
}
