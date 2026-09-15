import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Real-Debrid Account',
            style: context.auraText.bodyOverview.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unrestricts P2P torrents into high-speed HTTPS direct stream links with instant zero-buffering playback.',
            style: context.auraText.caption.copyWith(
              color: AppColors.textMuted,
              height: 1.4,
              fontSize: 12.0,
            ),
          ),
          const SizedBox(height: 14),
          if (isLoadingDebrid)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else if (debridAccount != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: debridAccount!.isPremium
                      ? AppColors.statusSuccess.withValues(alpha: 0.3)
                      : AppColors.statusWarning.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Username',
                        style: context.auraText.caption.copyWith(color: AppColors.textMuted, fontSize: 13.0),
                      ),
                      Text(
                        debridAccount!.username,
                        style: context.auraText.bodyOverview.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subscription',
                        style: context.auraText.caption.copyWith(color: AppColors.textMuted, fontSize: 13.0),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: debridAccount!.isPremium
                              ? AppColors.statusSuccess.withValues(alpha: 0.2)
                              : AppColors.statusWarning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          debridAccount!.isPremium
                              ? 'PREMIUM (${debridAccount!.premiumDaysLeft}d left)'
                              : 'FREE ACCOUNT',
                          style: TextStyle(
                            color: debridAccount!.isPremium
                                ? AppColors.statusSuccess
                                : AppColors.statusWarning,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusError,
                  side: const BorderSide(color: AppColors.statusError),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: onDisconnectDebrid,
                icon: const AuraIcon(AppIcons.linkOff, size: 16),
                label: const Text('Disconnect Real-Debrid', style: TextStyle(fontSize: 13)),
              ),
            ),
          ] else ...[
            TextField(
              controller: rdKeyController,
              style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 13.0),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                hintText: 'Paste API Token from real-debrid.com/apitoken',
                hintStyle: context.auraText.caption.copyWith(color: AppColors.textMuted, fontSize: 12.0),
                prefixIcon: const AuraIcon(
                  AppIcons.vpnKey,
                  color: Colors.white70,
                  size: 16,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: onSaveDebridKey,
                icon: const AuraIcon(AppIcons.addLink, size: 16, color: Colors.black),
                label: const Text('Connect Real-Debrid', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
