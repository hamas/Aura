import 'package:aura/features/player/data/services/media_kit_player_service.dart';
import 'package:aura/features/player/domain/entities/player_state.dart';
import 'package:aura/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura/features/player/presentation/bloc/player_event.dart';
import 'package:aura/features/player/presentation/widgets/aura_glow_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ambient Aura Glow Player Backlight Engine Tests', () {
    test('AuraPlayerState enableAuraGlow defaults to true and copies correctly',
        () {
      const state = AuraPlayerState();
      expect(state.enableAuraGlow, isTrue);

      final disabled = state.copyWith(enableAuraGlow: false);
      expect(disabled.enableAuraGlow, isFalse);
    });

    test('PlayerBloc handles ToggleAuraGlowEvent and SetAuraGlowEvent',
        () async {
      final playerService = MediaKitPlayerService.test();
      final bloc = PlayerBloc(playerService: playerService);

      expect(bloc.state.enableAuraGlow, isTrue);

      bloc.add(const ToggleAuraGlowEvent());
      await expectLater(
        bloc.stream,
        emits(predicate<AuraPlayerState>((s) => s.enableAuraGlow == false)),
      );

      bloc.add(const SetAuraGlowEvent(true));
      await expectLater(
        bloc.stream,
        emits(predicate<AuraPlayerState>((s) => s.enableAuraGlow == true)),
      );

      await bloc.close();
    });

    testWidgets('AuraGlowBackdrop renders when enabled and hides when disabled',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraGlowBackdrop(
              isEnabled: true,
              isPlaying: true,
              position: Duration(seconds: 15),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AuraGlowBackdrop), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraGlowBackdrop(
              isEnabled: false,
              isPlaying: true,
              position: Duration(seconds: 15),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AuraGlowBackdrop), findsOneWidget);
    });
  });
}
