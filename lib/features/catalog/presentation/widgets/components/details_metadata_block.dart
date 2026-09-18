import 'package:flutter/material.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_typography.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';

/// Metadata, spoken languages, production companies, and legal TMDb attribution notice block.
class DetailsMetadataBlock extends StatelessWidget {
  final MediaItem item;

  const DetailsMetadataBlock({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final languagesStr = item.spokenLanguages.isNotEmpty
        ? item.spokenLanguages.join(', ')
        : 'English';

    final companiesStr = item.productionCompanies.isNotEmpty
        ? item.productionCompanies.join(' • ')
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Languages & Studio',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRow('Spoken Languages', languagesStr),
              if (companiesStr != null) ...[
                const Divider(color: Colors.white10, height: 20),
                _buildRow('Production', companiesStr),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Legal TMDb Attribution Notice
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Film and television metadata provided by TMDb.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted.withValues(alpha: 0.7),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyOverview.copyWith(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
