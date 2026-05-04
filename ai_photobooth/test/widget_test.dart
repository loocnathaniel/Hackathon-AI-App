import 'package:ai_photobooth/main.dart';
import 'package:ai_photobooth/services/auth_service.dart';
import 'package:ai_photobooth/services/generation_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.instance.init();
    await GenerationStore.instance.init();
  });

  testWidgets('Shows sign-in when logged out', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Booth AI'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
