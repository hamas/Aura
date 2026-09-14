import 'package:aura/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:aura/features/search/presentation/bloc/search_bloc.dart';
import 'package:aura/features/search/presentation/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchBloc(
        catalogRepository: context.read<CatalogRepository>(),
      ),
      child: const AmbientSearchScreen(),
    );
  }
}
