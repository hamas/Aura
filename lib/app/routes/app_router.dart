import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/presentation/primitives/primitives.dart';
import '../../core/theme/app_colors.dart';
import '../../features/addons/presentation/screens/addons_screen.dart';
import '../../features/catalog/domain/entities/media_item.dart';
import '../../features/catalog/presentation/screens/detail_screen.dart';
import '../../features/catalog/presentation/screens/discovery_screen.dart';
import '../../features/catalog/presentation/screens/search_screen.dart';
import '../../features/clips/presentation/screens/clips_screen.dart';
import '../../features/downloads/presentation/screens/downloads_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/player/data/services/media_kit_player_service.dart';
import '../../features/player/presentation/bloc/player_bloc.dart';
import '../../features/player/presentation/bloc/player_event.dart';
import '../../features/player/presentation/widgets/player_view.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Main Application Navigation Shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainNavigationScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiscoveryScreen(),
            ),
          ),
          GoRoute(
            path: '/clips',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ClipsScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LibraryScreen(),
            ),
          ),
          GoRoute(
            path: '/downloads',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DownloadsScreen(),
            ),
          ),
          GoRoute(
            path: '/addons',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AddonsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // Detail Screen Route
      GoRoute(
        path: '/detail/:type/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final typeString = state.pathParameters['type'] ?? 'movie';
          final idString = state.pathParameters['id'] ?? '0';
          final id = int.tryParse(idString) ?? 0;
          final type = typeString == 'series' || typeString == 'tv'
              ? MediaType.series
              : MediaType.movie;
          final initialItem = state.extra as MediaItem?;

          return DetailScreen(
            id: id,
            type: type,
            initialItem: initialItem,
          );
        },
      ),

      // Fullscreen Video Player Route
      GoRoute(
        path: '/player',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final streamUrl = extra['streamUrl'] as String? ?? '';
          final title = extra['title'] as String?;
          final subtitle = extra['subtitle'] as String?;
          final headers = extra['headers'] as Map<String, String>?;
          final mediaId = extra['mediaId'] as String?;
          final posterPath = extra['posterPath'] as String?;
          final backdropPath = extra['backdropPath'] as String?;
          final mediaType = extra['type'] as String?;
          final seasonNumber = extra['seasonNumber'] as int?;
          final episodeNumber = extra['episodeNumber'] as int?;

          final playerService = MediaKitPlayerService();

          return BlocProvider(
            create: (context) {
              final bloc = PlayerBloc(playerService: playerService);
              bloc.add(
                PlayStreamEvent(
                  streamUrl: streamUrl,
                  title: title,
                  subtitle: subtitle,
                  httpHeaders: headers,
                ),
              );
              return bloc;
            },
            child: PlayerView(
              playerService: playerService,
              onBack: () => Navigator.of(context).pop(),
              mediaId: mediaId,
              posterPath: posterPath,
              backdropPath: backdropPath,
              mediaType: mediaType,
              seasonNumber: seasonNumber,
              episodeNumber: episodeNumber,
            ),
          );
        },
      ),
    ],
  );
}

class MainNavigationScaffold extends StatelessWidget {
  final Widget child;

  const MainNavigationScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/clips')) {
      return 1;
    }
    if (location.startsWith('/downloads') || location.startsWith('/library')) {
      return 2;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/clips');
        break;
      case 2:
        context.go('/downloads');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalBottomBlurHeight = bottomPadding + 100.0;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.surfaceBackground,
      body: Stack(
        children: [
          Positioned.fill(child: child),

          // Bottom Bar Background Blur Overlay (matching top bar!)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: totalBottomBlurHeight,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0x99FFFFFF),
                            Color(0x00FFFFFF),
                          ],
                          stops: [0.0, 0.55, 1.0],
                        ).createShader(bounds);
                      },
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                        child: const ColoredBox(color: Colors.black),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.surfaceBackground.withValues(alpha: 0.51),
                            AppColors.surfaceBackground.withValues(alpha: 0.21),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.60, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Pill Toolbar
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding + 16,
            child: Center(
              child: AuraFloatingBottomPill(
                currentIndex: currentIndex,
                onTap: (idx) => _onItemTapped(idx, context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
