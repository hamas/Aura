import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_typography.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';

/// Editorial Information & Production Details block.
class DetailsInformationBlock extends StatelessWidget {
  final MediaItem item;

  const DetailsInformationBlock({
    super.key,
    required this.item,
  });

  String _formatReleaseDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'N/A';
    try {
      final parsed = DateTime.parse(rawDate.trim());
      return DateFormat('MMMM d, yyyy').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  String _formatRuntime(int? minutes) {
    if (minutes == null || minutes <= 0) return 'N/A';
    final hrs = minutes ~/ 60;
    final mins = minutes % 60;
    if (hrs > 0 && mins > 0) {
      return '$hrs hr $mins min';
    } else if (hrs > 0) {
      return '$hrs hr';
    } else {
      return '$mins min';
    }
  }

  String _formatCurrency(int? amount) {
    if (amount == null || amount <= 0) return 'N/A';
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final releaseStr = _formatReleaseDate(item.releaseDate);
    final runtimeStr = _formatRuntime(item.runtimeMinutes);
    final ratedStr = item.certification != null && item.certification!.isNotEmpty
        ? item.certification!
        : (item.type == MediaType.movie ? 'PG-13' : 'TV-MA');
    final regionsStr = item.productionCountries.isNotEmpty
        ? item.productionCountries.join(', ')
        : 'United States';

    final budgetStr = item.type == MediaType.movie ? _formatCurrency(item.budget) : null;
    final revenueStr = item.type == MediaType.movie ? _formatCurrency(item.revenue) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Information',
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
            children: [
              _buildRow('Released', releaseStr),
              const Divider(color: Colors.white10, height: 20),
              _buildRow('Run Time', runtimeStr),
              const Divider(color: Colors.white10, height: 20),
              _buildRow('Rated', ratedStr),
              const Divider(color: Colors.white10, height: 20),
              _buildRow('Regions of Origin', regionsStr),
              if (budgetStr != null && budgetStr != 'N/A') ...[
                const Divider(color: Colors.white10, height: 20),
                _buildRow('Budget', budgetStr),
              ],
              if (revenueStr != null && revenueStr != 'N/A') ...[
                const Divider(color: Colors.white10, height: 20),
                _buildRow('Revenue', revenueStr),
              ],
            ],
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
