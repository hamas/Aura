import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/presentation/primitives/primitives.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
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
    if (location.startsWith('/search')) {
      return 2;
    }
    if (location.startsWith('/library')) {
      return 3;
    }
    if (location.startsWith('/settings') ||
        location.startsWith('/profile') ||
        location.startsWith('/addons')) {
      return 4;
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
        context.go('/search');
        break;
      case 3:
        context.go('/library');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceBackground,
          border: Border(top: BorderSide(color: Color(0xFF1F1F1F), width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.surfaceBackground,
          indicatorColor: AppColors.surfaceElevated,
          selectedIndex: currentIndex,
          onDestinationSelected: (idx) => _onItemTapped(idx, context),
          destinations: const [
            NavigationDestination(
              icon: AuraIcon(AppIcons.home),
              selectedIcon: AuraIcon(AppIcons.home,
                  color: AppColors.accentPink, fill: 1.0),
              label: 'Home',
            ),
            NavigationDestination(
              icon: AuraIcon(AppIcons.clips),
              selectedIcon: AuraIcon(AppIcons.clips,
                  color: AppColors.accentPink, fill: 1.0),
              label: 'Clips',
            ),
            NavigationDestination(
              icon: AuraIcon(AppIcons.search),
              selectedIcon:
                  AuraIcon(AppIcons.search, color: AppColors.accentPink),
              label: 'Search',
            ),
            NavigationDestination(
              icon: AuraIcon(AppIcons.library),
              selectedIcon: AuraIcon(AppIcons.library,
                  color: AppColors.accentPink, fill: 1.0),
              label: 'Library',
            ),
            NavigationDestination(
              icon: AuraIcon(AppIcons.settings),
              selectedIcon: AuraIcon(AppIcons.settings,
                  color: AppColors.accentPink, fill: 1.0),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
