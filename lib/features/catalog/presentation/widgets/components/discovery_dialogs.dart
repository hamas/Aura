import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';


class DiscoveryDialogs {
  static void showCastDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Row(
          children: [
            const AuraIcon(AppIcons.cast, color: AppColors.accentPink),
            const SizedBox(width: AppTokens.spacingSm),
            Text(
              'Connect Device',
              style: context.auraText.sectionTitle.copyWith(
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Searching for available Chromecast, Android TV, and DLNA display targets on your local network...',
          style: context.auraText.bodyOverview.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: context.auraText.caption
                  .copyWith(color: AppColors.accentPink),
            ),
          ),
        ],
      ),
    );
  }

  static void showCategoriesModal(BuildContext context) {
    final genres = [
      'Action & Adventure',
      'Sci-Fi & Cyberpunk',
      'Crime & Mystery',
      'Drama',
      'Comedy',
      'Animation & Anime',
      'Documentary',
      'Thriller & Suspense',
      'Fantasy',
      'Horror',
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppTokens.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Browse Categories',
                style: context.auraText.sectionTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: genres.length,
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        genre,
                        style: context.auraText.bodyOverview.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const AuraIcon(
                        AppIcons.chevronRight,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surfaceElevated,
                            content: Text('Filtering by "$genre"'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
