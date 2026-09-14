import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../debrid/domain/entities/debrid_account.dart';

class SettingsDebridCard extends StatelessWidget {
  final bool isLoadingDebrid;
  final DebridAccount? debridAccount;
  final TextEditingController rdKeyController;
  final VoidCallback onSaveDebridKey;
  final VoidCallback onDisconnectDebrid;

  const SettingsDebridCard({
    super.key,
    required this.isLoadingDebrid,
    required this.debridAccount,
    required this.rdKeyController,
    required this.onSaveDebridKey,
    required this.onDisconnectDebrid,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        side: const BorderSide(color: AppColors.surfaceElevated),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-Debrid Account',
              style: context.auraText.itemTitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Unrestricts P2P torrents into high-speed HTTPS direct stream links with instant zero-buffering playback.',
              style: context.auraText.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            if (isLoadingDebrid)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTokens.spacingSm),
                  child: CircularProgressIndicator(color: AppColors.accentPink),
                ),
              )
            else if (debridAccount != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  border: Border.all(
                    color: debridAccount!.isPremium
                        ? AppColors.statusSuccess.withAlpha((0.3 * 255).round())
                        : AppColors.statusWarning
                            .withAlpha((0.3 * 255).round()),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Username',
                          style: context.auraText.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                        Text(
                          debridAccount!.username,
                          style: context.auraText.bodyOverview.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spacingSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subscription',
                          style: context.auraText.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.spacingSm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: debridAccount!.isPremium
                                ? AppColors.statusSuccess
                                    .withAlpha((0.2 * 255).round())
                                : AppColors.statusWarning
                                    .withAlpha((0.2 * 255).round()),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusSmall),
                          ),
                          child: Text(
                            debridAccount!.isPremium
                                ? 'PREMIUM (${debridAccount!.premiumDaysLeft}d left)'
                                : 'FREE ACCOUNT',
                            style: context.auraText.metadataPill.copyWith(
                              color: debridAccount!.isPremium
                                  ? AppColors.statusSuccess
                                  : AppColors.statusWarning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusError,
                    side: const BorderSide(color: AppColors.statusError),
                  ),
                  onPressed: onDisconnectDebrid,
                  icon: const AuraIcon(AppIcons.linkOff, size: 16),
                  label: const Text('Disconnect Real-Debrid'),
                ),
              ),
            ] else ...[
              TextField(
                controller: rdKeyController,
                style: context.auraText.bodyOverview
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  hintText: 'Paste API Token from real-debrid.com/apitoken',
                  hintStyle: context.auraText.caption
                      .copyWith(color: AppColors.textMuted),
                  prefixIcon: const AuraIcon(
                    AppIcons.vpnKey,
                    color: AppColors.accentPink,
                    size: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPink,
                    foregroundColor: AppColors.surfaceBackground,
                  ),
                  onPressed: onSaveDebridKey,
                  icon: const AuraIcon(AppIcons.addLink, size: 18),
                  label: const Text('Connect Real-Debrid'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
