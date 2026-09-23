import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/primitives/aura_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/person_details.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../widgets/media_poster_card.dart';

/// Screen displaying detailed actor metadata, biography, and filmography grid.
class PersonDetailsScreen extends StatefulWidget {
  final int personId;
  final String? initialName;

  const PersonDetailsScreen({
    super.key,
    required this.personId,
    this.initialName,
  });

  @override
  State<PersonDetailsScreen> createState() => _PersonDetailsScreenState();
}

class _PersonDetailsScreenState extends State<PersonDetailsScreen> {
  final CatalogRepository _catalogRepository = CatalogRepositoryImpl();
  PersonDetails? _personDetails;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isBioExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final details =
          await _catalogRepository.getPersonDetails(widget.personId);
      if (mounted) {
        setState(() {
          _personDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load details.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuraScaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: Text(
              _personDetails?.name ?? widget.initialName ?? '',
              style: context.auraText.sectionTitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accentPink),
              ),
            )
          else if (_errorMessage != null || _personDetails == null)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  _errorMessage ?? 'Actor details unavailable',
                  style: context.auraText.bodyOverview,
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, _personDetails!),
                    const SizedBox(height: AppTokens.spacingLg),
                    if (_personDetails!.biography.isNotEmpty) ...[
                      _buildBiography(context, _personDetails!.biography),
                      const SizedBox(height: AppTokens.spacingXl),
                    ],
                    Text(
                      'Filmography',
                      style: context.auraText.sectionTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacingMd),
                  ],
                ),
              ),
            ),
            _buildFilmographyGrid(context, _personDetails!.knownFor),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PersonDetails person) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surfaceElevated, width: 2),
            image: person.profilePath != null
                ? DecorationImage(
                    image: NetworkImage(person.profilePath!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: person.profilePath == null
              ? const Icon(Icons.person, size: 40, color: AppColors.textMuted)
              : null,
        ),
        const SizedBox(width: AppTokens.spacingLg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.name,
                style: context.auraText.sectionTitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (person.knownForDepartment.isNotEmpty)
                    person.knownForDepartment,
                  if (person.placeOfBirth != null &&
                      person.placeOfBirth!.isNotEmpty)
                    person.placeOfBirth,
                ].join(' • '),
                style: context.auraText.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBiography(BuildContext context, String bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bio,
          maxLines: _isBioExpanded ? null : 4,
          overflow:
              _isBioExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: context.auraText.bodyOverview,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _isBioExpanded = !_isBioExpanded),
          child: Text(
            _isBioExpanded ? 'Show Less' : 'Read More',
            style: context.auraText.caption.copyWith(
              color: AppColors.accentPink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilmographyGrid(BuildContext context, List<MediaItem> items) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingLg),
          child: Text(
            'No filmography entries available.',
            style: context.auraText.caption,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingLg),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: AppTokens.posterAspectRatio,
          crossAxisSpacing: AppTokens.spacingMd,
          mainAxisSpacing: AppTokens.spacingMd,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return MediaPosterCard(
              item: item,
              onTap: () {
                context.push(
                  '/detail/${item.type.name}/${item.id}',
                  extra: item,
                );
              },
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}
