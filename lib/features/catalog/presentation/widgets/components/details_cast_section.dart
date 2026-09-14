import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aura/core/constants/api_constants.dart';
import 'package:aura/core/presentation/primitives/aura_icon.dart';
import 'package:aura/core/presentation/primitives/aura_section_header.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:aura/core/theme/app_typography.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';

class DetailsCastSection extends StatelessWidget {
  final MediaItem item;

  const DetailsCastSection({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuraSectionHeader(
          title: 'Top Cast & Crew',
          padding: EdgeInsets.zero,
          showChevron: false,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: item.cast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final actor = item.cast[index];
              final profileUrl = actor.profilePath != null
                  ? '${ApiConstants.tmdbPosterW500}${actor.profilePath}'
                  : null;

              return InkWell(
                onTap: () {
                  context.push('/person/${actor.id}', extra: actor.name);
                },
                borderRadius: BorderRadius.circular(36),
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.surfaceElevated,
                        backgroundImage: profileUrl != null
                            ? CachedNetworkImageProvider(profileUrl)
                            : null,
                        child: profileUrl == null
                            ? const AuraIcon(AppIcons.person,
                                color: AppColors.textMuted, size: 24)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        actor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        actor.character,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
