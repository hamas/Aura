import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/addons/presentation/screens/addons_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/catalog/domain/entities/media_item.dart';
import '../../features/catalog/presentation/screens/detail_screen.dart';
import '../../features/catalog/presentation/screens/discovery_screen.dart';
import '../../features/catalog/presentation/screens/search_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/player/data/services/media_kit_player_service.dart';
import '../../features/player/presentation/bloc/player_bloc.dart';
import '../../features/player/presentation/bloc/player_event.dart';
import '../../features/player/presentation/widgets/player_view.dart';
import '../theme/app_theme.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

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
            path: '/addons',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AddonsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
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
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/library')) return 2;
    if (location.startsWith('/addons')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/library');
        break;
      case 3:
        context.go('/addons');
        break;
      case 4:
        context.go('/profile');
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
          border: Border(top: BorderSide(color: Color(0xFF1E2638), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (idx) => _onItemTapped(idx, context),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.movie_outlined),
              selectedIcon: Icon(Icons.movie, color: AppTheme.primaryAccent),
              label: 'Discover',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: AppTheme.primaryAccent),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.video_library_outlined),
              selectedIcon: Icon(Icons.video_library, color: AppTheme.primaryAccent),
              label: 'Library',
            ),
            NavigationDestination(
              icon: Icon(Icons.extension_outlined),
              selectedIcon: Icon(Icons.extension, color: AppTheme.primaryAccent),
              label: 'Add-ons',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppTheme.primaryAccent),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
