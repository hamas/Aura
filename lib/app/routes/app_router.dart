import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../../features/player/data/services/media_kit_player_service.dart';
import '../../features/player/presentation/bloc/player_bloc.dart';
import '../../features/player/presentation/bloc/player_event.dart';
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
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DiscoveryScreen(),
            ),
          ),
          GoRoute(
            path: '/clips',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ClipsScreen(),
            ),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const LibraryScreen(),
            ),
          ),
          GoRoute(
            path: '/downloads',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DownloadsScreen(),
            ),
          ),
          GoRoute(
            path: '/addons',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AddonsScreen(),
            ),
          ),
          GoRoute(
            path: '/addons/install',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const InstallAddonScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
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
          return NoTransitionPage(
            key: ValueKey('category_${genre}_${state.pageKey}'),
            child: CategoryScreen(genreName: genre),
          );
        },
      ),

      // Standalone Search Screen Route (outside navigation shell to hide bottom pill)
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const SearchScreen(),
        ),
      ),

      // Profile Selection Screen Route (Full overlay outside navigation shell)
      GoRoute(
        path: '/profiles',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const ProfileSelectionScreen(),
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

          return NoTransitionPage(
            key: state.pageKey,
            child: PersonDetailsScreen(
              personId: id,
              initialName: initialName,
            ),
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

          return NoTransitionPage(
            key: state.pageKey,
            child: MediaDetailsScreen(
              id: id,
              type: type,
              initialItem: initialItem,
            ),
          );
        },
      ),

      // Fullscreen Video Player Route
      GoRoute(
        path: '/player',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
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

          return NoTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
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
            ),
          );
        },
      ),
    ],
  );
}
