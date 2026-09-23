import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura/app/app.dart';

class MockStorage extends Fake implements Storage {
  @override
  Future<void> write(String key, dynamic value) async {}

  @override
  dynamic read(String key) => null;

  @override
  Future<void> delete(String key) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  setUp(() {
    HydratedBloc.storage = MockStorage();
  });

  testWidgets('Aura app bootstrap smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(AuraApp(prefs: prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AuraApp), findsOneWidget);
  });
}
