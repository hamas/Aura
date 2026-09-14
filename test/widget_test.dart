import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura/app/app.dart';

void main() {
  testWidgets('Aura app bootstrap smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(AuraApp(prefs: prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AuraApp), findsOneWidget);
  });
}
