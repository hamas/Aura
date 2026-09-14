import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/addons/data/repositories/addon_repository_impl.dart';
import '../features/addons/domain/repositories/addon_repository.dart';
import '../features/addons/presentation/bloc/addon_bloc.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/catalog/data/repositories/catalog_repository_impl.dart';
import '../features/catalog/domain/repositories/catalog_repository.dart';
import '../features/catalog/presentation/bloc/catalog_bloc.dart';
import '../features/clips/data/repositories/clips_repository_impl.dart';
import '../features/clips/domain/repositories/clips_repository.dart';
import '../features/clips/presentation/bloc/clips_bloc.dart';
import '../features/library/data/repositories/library_repository_impl.dart';
import '../features/library/domain/repositories/library_repository.dart';
import '../features/library/presentation/bloc/library_bloc.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class AuraApp extends StatelessWidget {
  final SharedPreferences prefs;

  const AuraApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    // Instantiate Core Repositories
    final AuthRepository authRepository = AuthRepositoryImpl();
    final CatalogRepository catalogRepository = CatalogRepositoryImpl();
    final AddonRepository addonRepository = AddonRepositoryImpl(prefs: prefs);
    final LibraryRepository libraryRepository = LibraryRepositoryImpl(
      prefs: prefs,
      authRepository: authRepository,
    );
    final ClipsRepository clipsRepository =
        ClipsRepositoryImpl(catalogRepository: catalogRepository);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<CatalogRepository>.value(value: catalogRepository),
        RepositoryProvider<AddonRepository>.value(value: addonRepository),
        RepositoryProvider<LibraryRepository>.value(value: libraryRepository),
        RepositoryProvider<ClipsRepository>.value(value: clipsRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(authRepository: authRepository)
              ..add(CheckAuthStatusEvent()),
          ),
          BlocProvider<CatalogBloc>(
            create: (context) =>
                CatalogBloc(catalogRepository: catalogRepository),
          ),
          BlocProvider<AddonBloc>(
            create: (context) => AddonBloc(addonRepository: addonRepository),
          ),
          BlocProvider<LibraryBloc>(
            create: (context) =>
                LibraryBloc(libraryRepository: libraryRepository),
          ),
          BlocProvider<ClipsBloc>(
            create: (context) => ClipsBloc(clipsRepository: clipsRepository),
          ),
        ],
        child: MaterialApp.router(
          title: 'Aura',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
