import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      'Action',
      'Adventure',
      'Animation',
      'Comedy',
      'Crime',
      'Documentary',
      'Drama',
      'Family',
      'Fantasy',
      'History',
      'Horror',
      'Music',
      'Mystery',
      'Romance',
      'Sci-Fi',
      'Thriller',
      'War',
      'Western',
    ];

    final mediaQuery = MediaQuery.of(context);
    final screenRadius = mediaQuery.padding.top > 0
        ? (mediaQuery.padding.top * 0.75).clamp(24.0, 36.0)
        : 28.0;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Categories',
      barrierColor: Colors.black.withValues(alpha: 0.40),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: mediaQuery.size.width * 0.88,
                constraints: BoxConstraints(
                  maxHeight: mediaQuery.size.height * 0.72,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(screenRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: genres.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3.2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    return Material(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          GoRouter.of(context).push(
                              '/category?genre=${Uri.encodeComponent(genre)}');
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            genre,
                            textAlign: TextAlign.center,
                            style: context.auraText.bodyOverview.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
