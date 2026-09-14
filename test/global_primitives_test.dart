import 'package:aura/core/presentation/primitives/primitives.dart';
import 'package:aura/core/theme/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Global Typography Engine Tests', () {
    test('AppTypography provides standard styled text definitions', () {
      expect(AppTypography.displayHero.fontSize, equals(30));
      expect(AppTypography.displayHero.fontWeight, equals(FontWeight.w900));
      expect(AppTypography.sectionTitle.fontSize, equals(20));
      expect(AppTypography.sectionTitle.fontWeight, equals(FontWeight.w800));
      expect(AppTypography.itemTitle.fontSize, equals(15));
      expect(AppTypography.itemTitle.fontWeight, equals(FontWeight.w600));
      expect(AppTypography.metadataPill.fontSize, equals(11));
      expect(AppTypography.metadataPill.fontWeight, equals(FontWeight.w700));
      expect(AppTypography.bodyOverview.fontSize, equals(14));
      expect(AppTypography.caption.fontSize, equals(12));
    });

    test('AuraTheme includes AuraThemeExtension and typography in ThemeData',
        () {
      final theme = AuraTheme.darkTheme;
      final extension = theme.extension<AuraThemeExtension>();
      expect(extension, isNotNull);
      expect(extension?.cardBackground, equals(AppColors.surfaceCard));
      expect(extension?.focusBorder, equals(AppColors.accentPink));
      expect(theme.textTheme.displayLarge?.fontSize, equals(30));
    });
  });

  group('AuraCard Primitive Tests', () {
    testWidgets('AuraCard renders child and triggers onTap callback', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AuraTheme.darkTheme,
          home: Scaffold(
            body: AuraCard(
              onTap: () => tapped = true,
              child: const Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      await tester.tap(find.byType(AuraCard));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('AuraCard applies default surface color and border radius', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AuraTheme.darkTheme,
          home: const Scaffold(
            body: AuraCard(
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AuraCard),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.surfaceCard));
      expect(
        decoration.borderRadius,
        equals(AppTokens.borderRadiusSmall),
      );
    });
  });

  group('AuraSectionHeader Primitive Tests', () {
    testWidgets('AuraSectionHeader renders title, subtitle, and chevron', (
      tester,
    ) async {
      bool headerTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AuraTheme.darkTheme,
          home: Scaffold(
            body: AuraSectionHeader(
              title: 'Trending Movies',
              subtitle: 'Top 10 this week',
              onTap: () => headerTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Trending Movies'), findsOneWidget);
      expect(find.text('Top 10 this week'), findsOneWidget);
      expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);

      await tester.tap(find.byType(AuraSectionHeader));
      expect(headerTapped, isTrue);
    });
  });

  group('AuraBadge Primitive Tests', () {
    testWidgets('AuraBadge.rating renders rating with star icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AuraTheme.darkTheme,
          home: Scaffold(
            body: AuraBadge.rating('8.9'),
          ),
        ),
      );

      expect(find.text('8.9'), findsOneWidget);
      expect(find.byIcon(AppIcons.star), findsOneWidget);
    });

    testWidgets('AuraBadge.quality renders quality tag', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AuraTheme.darkTheme,
          home: Scaffold(
            body: AuraBadge.quality('4K HDR'),
          ),
        ),
      );

      expect(find.text('4K HDR'), findsOneWidget);
    });

    testWidgets('AuraBadge.episode renders formatted season/episode code', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AuraTheme.darkTheme,
          home: Scaffold(
            body: AuraBadge.episode(2, 5),
          ),
        ),
      );

      expect(find.text('S2:E5'), findsOneWidget);
    });

    testWidgets('AuraBadge.status renders active status indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AuraTheme.darkTheme,
          home: Scaffold(
            body: AuraBadge.status('Debrid Active', active: true),
          ),
        ),
      );

      expect(find.text('DEBRID ACTIVE'), findsOneWidget);
    });
  });

  group('AuraScaffold Primitive Tests', () {
    testWidgets('AuraScaffold applies dark canvas background', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AuraTheme.darkTheme,
          home: const AuraScaffold(
            body: Text('Scaffold Body'),
          ),
        ),
      );

      expect(find.text('Scaffold Body'), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.surfaceBackground));
    });
  });
}
