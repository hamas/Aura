import 'package:aura/core/presentation/primitives/aura_floating_bottom_pill.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraFloatingBottomPill Widget Tests', () {
    testWidgets('renders Home, Clips, and Library navigation items', (
      tester,
    ) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraFloatingBottomPill(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      expect(find.byIcon(AppIcons.home), findsOneWidget);
      expect(find.byIcon(AppIcons.clips), findsOneWidget);
      expect(find.byIcon(AppIcons.downloads), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.clips));
      expect(tappedIndex, equals(1));
    });
  });
}
