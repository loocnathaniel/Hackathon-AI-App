import 'package:flutter_test/flutter_test.dart';
import 'package:ai_photobooth/main.dart';

void main() {
  testWidgets('Photobooth screen renders core controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('AI Photobooth Setup'), findsOneWidget);
    expect(find.text('Background prompt'), findsOneWidget);
    expect(find.textContaining('Open '), findsOneWidget);
    expect(find.text('Use gallery (fallback)'), findsOneWidget);
    expect(find.text('Generate photobooth result'), findsOneWidget);
  });
}
