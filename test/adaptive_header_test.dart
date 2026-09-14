import 'package:aura/core/presentation/primitives/aura_adaptive_app_bar.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraAdaptiveAppBar Widget Tests', () {
    testWidgets('renders Root Mode with category pills and action icons', (
      tester,
    ) async {
      bool tvShowsTapped = false;
      bool moviesTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraAdaptiveAppBar(
              forceCanPop: false,
              categories: [
                AuraCategoryPill(
                  label: 'TV Shows',
                  isSelected: false,
                  onTap: () => tvShowsTapped = true,
                ),
                AuraCategoryPill(
                  label: 'Movies',
                  isSelected: true,
                  onTap: () => moviesTapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('TV Shows'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);

      expect(find.byIcon(AppIcons.cast), findsOneWidget);
      expect(find.byIcon(AppIcons.search), findsOneWidget);

      await tester.tap(find.text('TV Shows'));
      expect(tvShowsTapped, isTrue);

      await tester.tap(find.text('Movies'));
      expect(moviesTapped, isTrue);
    });

    testWidgets('renders Nested Route Mode with back button and view title', (
      tester,
    ) async {
      bool backPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraAdaptiveAppBar(
              forceCanPop: true,
              title: 'Stranger Things',
              onBackPressed: () => backPressed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(AppIcons.back), findsOneWidget);
      expect(find.text('Stranger Things'), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.back));
      expect(backPressed, isTrue);
    });

    testWidgets('interpolates background opacity based on scroll offset', (
      tester,
    ) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ListView.builder(
                  controller: scrollController,
                  itemCount: 50,
                  itemBuilder: (_, index) => SizedBox(
                    height: 100,
                    child: Text('Item $index'),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AuraAdaptiveAppBar(
                    scrollController: scrollController,
                    forceCanPop: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AuraAdaptiveAppBar), findsOneWidget);

      scrollController.jumpTo(100.0);
      await tester.pump();

      expect(find.byType(AuraAdaptiveAppBar), findsOneWidget);
    });
  });
}
