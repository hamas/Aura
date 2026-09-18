import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/presentation/primitives/primitives.dart';
import '../../features/addons/presentation/screens/addons_screen.dart';
import '../../features/addons/presentation/screens/install_addon_screen.dart';
import '../../features/catalog/domain/entities/media_item.dart';
import '../../features/catalog/presentation/screens/category_screen.dart';
import '../../features/catalog/presentation/screens/media_details_screen.dart';
import '../../features/catalog/presentation/screens/discovery_screen.dart';
import '../../features/catalog/presentation/screens/search_screen.dart';
import '../../features/clips/presentation/screens/clips_screen.dart';
import '../../features/downloads/presentation/screens/downloads_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/player/presentation/widgets/player_view.dart';
import '../../features/catalog/presentation/screens/person_details_screen.dart';
import '../../features/profiles/presentation/screens/profile_selection_screen.dart';
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
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DiscoveryScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
          GoRoute(
            path: '/clips',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ClipsScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const LibraryScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
          GoRoute(
            path: '/downloads',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DownloadsScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
          GoRoute(
            path: '/addons',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AddonsScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
          GoRoute(
            path: '/addons/install',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const InstallAddonScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
        ],
      ),

      // Standalone Category Grid Screen Route (on root navigator so context.push from Search/Home works)
      GoRoute(
        path: '/category',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final genre = state.uri.queryParameters['genre'] ?? 'Action';
          return CustomTransitionPage(
            key: ValueKey('category_${genre}_${state.pageKey}'),
            child: CategoryScreen(genreName: genre),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 250),
          );
        },
      ),

      // Standalone Search Screen Route (outside navigation shell to hide bottom pill)
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SearchScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
        ),
      ),

      // Profile Selection Screen Route (Full overlay outside navigation shell)
      GoRoute(
        path: '/profiles',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfileSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
        ),
      ),

      // Person Details Screen Route
      GoRoute(
        path: '/person/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final idString = state.pathParameters['id'] ?? '0';
          final id = int.tryParse(idString) ?? 0;
          final initialName = state.extra as String?;

          return CustomTransitionPage(
            key: state.pageKey,
            child: PersonDetailsScreen(
              personId: id,
              initialName: initialName,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 250),
          );
        },
      ),

      // Detail Screen Route
      GoRoute(
        path: '/detail/:type/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final rawType = (state.pathParameters['type'] ?? 'movie').toLowerCase();
          final idString = state.pathParameters['id'] ?? '0';
          final id = int.tryParse(idString) ?? 0;
          final initialItem = state.extra as MediaItem?;
          final type = initialItem?.type ??
              (rawType.contains('series') || rawType.contains('tv')
                  ? MediaType.series
                  : MediaType.movie);

          return CustomTransitionPage(
            key: state.pageKey,
            child: MediaDetailsScreen(
              id: id,
              type: type,
              initialItem: initialItem,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 250),
          );
        },
      ),

      // Fullscreen Video Player Route
      GoRoute(
        path: '/player',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return NoTransitionPage(
            key: state.pageKey,
            child: PlayerView(
              args: extra,
              onBack: () => Navigator.of(context).pop(),
            ),
          );
        },
      ),
    ],
  );
}
