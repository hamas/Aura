import 'package:aura/core/presentation/primitives/aura_adaptive_app_bar.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraAdaptiveAppBar Widget Tests', () {
    testWidgets('renders Root Mode with A glyph and category pills',
        (tester) async {
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

      // Verify category pills are rendered
      expect(find.text('TV Shows'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);

      // Verify default actions (Cast & Search icons)
      expect(find.byIcon(AppIcons.cast), findsOneWidget);
      expect(find.byIcon(AppIcons.search), findsOneWidget);

      // Test interaction with pills
      await tester.tap(find.text('TV Shows'));
      expect(tvShowsTapped, isTrue);

      await tester.tap(find.text('Movies'));
      expect(moviesTapped, isTrue);
    });

    testWidgets('renders Nested Route Mode with back button and view title',
        (tester) async {
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

      // Verify back button is displayed instead of glyph/categories
      expect(find.byIcon(AppIcons.arrowBackIosNew), findsOneWidget);
      expect(find.text('Stranger Things'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(AppIcons.arrowBackIosNew));
      expect(backPressed, isTrue);
    });

    testWidgets('interpolates background color opacity based on scroll offset',
        (tester) async {
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

      // Initial opacity (offset = 0)
      final initialContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(AuraAdaptiveAppBar),
          matching: find.byType(Container).first,
        ),
      );
      final initialBoxDecoration = initialContainer.decoration as BoxDecoration;
      expect((((initialBoxDecoration.color?.a ?? 0) * 255).round()), 0);

      // Scroll down past 50.0
      scrollController.jumpTo(100.0);
      await tester.pump();

      final scrolledContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(AuraAdaptiveAppBar),
          matching: find.byType(Container).first,
        ),
      );
      final scrolledBoxDecoration =
          scrolledContainer.decoration as BoxDecoration;
      expect((((scrolledBoxDecoration.color?.a ?? 0) * 255).round()), 255);
    });
  });
}
