import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';


class SettingsPlayerPreferencesCard extends StatelessWidget {
  final bool hardwareAcceleration;
  final ValueChanged<bool> onHardwareAccelerationChanged;
  final bool ambientAuraGlow;
  final ValueChanged<bool> onAmbientAuraGlowChanged;
  final bool autoSkipIntros;
  final ValueChanged<bool> onAutoSkipIntrosChanged;
  final String defaultAudioLanguage;
  final ValueChanged<String?> onDefaultAudioLanguageChanged;
  final String defaultSubtitleLanguage;
  final ValueChanged<String?> onDefaultSubtitleLanguageChanged;
  final List<Map<String, String>> languageOptions;

  const SettingsPlayerPreferencesCard({
    super.key,
    required this.hardwareAcceleration,
    required this.onHardwareAccelerationChanged,
    required this.ambientAuraGlow,
    required this.onAmbientAuraGlowChanged,
    required this.autoSkipIntros,
    required this.onAutoSkipIntrosChanged,
    required this.defaultAudioLanguage,
    required this.onDefaultAudioLanguageChanged,
    required this.defaultSubtitleLanguage,
    required this.onDefaultSubtitleLanguageChanged,
    required this.languageOptions,
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMd,
          vertical: AppTokens.spacingSm,
        ),
        child: Column(
          children: [
            // Hardware Acceleration Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.accentPink,
              title: Text(
                'Hardware Acceleration',
                style: context.auraText.bodyOverview.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Enable GPU decoding via MediaKit libmpv for fluid 4K HDR playback',
                style: context.auraText.caption.copyWith(color: AppColors.textMuted),
              ),
              value: hardwareAcceleration,
              onChanged: onHardwareAccelerationChanged,
            ),
            const Divider(color: AppColors.surfaceElevated, height: 1),

            // Ambient Aura Glow Lighting Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.accentPink,
              title: Text(
                'Ambient Aura Glow',
                style: context.auraText.bodyOverview.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Dynamic backlighting projecting letterbox edge colors behind player',
                style: context.auraText.caption.copyWith(color: AppColors.textMuted),
              ),
              value: ambientAuraGlow,
              onChanged: onAmbientAuraGlowChanged,
            ),
            const Divider(color: AppColors.surfaceElevated, height: 1),

            // Auto-Skip Intros & Recaps Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.accentPink,
              title: Text(
                'Auto-Skip Intros & Recaps',
                style: context.auraText.bodyOverview.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Automatically seek past intro themes and recaps without prompt',
                style: context.auraText.caption.copyWith(color: AppColors.textMuted),
              ),
              value: autoSkipIntros,
              onChanged: onAutoSkipIntrosChanged,
            ),
            const Divider(color: AppColors.surfaceElevated, height: 1),

            // Default Audio Language
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Default Audio Language',
                style: context.auraText.bodyOverview.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Preferred soundtrack stream during playback initiation',
                style: context.auraText.caption.copyWith(color: AppColors.textMuted),
              ),
              trailing: DropdownButton<String>(
                value: defaultAudioLanguage,
                dropdownColor: AppColors.surfaceElevated,
                underline: const SizedBox.shrink(),
                style: context.auraText.bodyOverview.copyWith(
                  color: AppColors.accentPink,
                  fontWeight: FontWeight.bold,
                ),
                items: languageOptions.map((lang) {
                  return DropdownMenuItem<String>(
                    value: lang['code'],
                    child: Text(lang['name']!),
                  );
                }).toList(),
                onChanged: onDefaultAudioLanguageChanged,
              ),
            ),
            const Divider(color: AppColors.surfaceElevated, height: 1),

            // Default Subtitle Language
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Default Subtitle Language',
                style: context.auraText.bodyOverview.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Auto-selected subtitle track when available',
                style: context.auraText.caption.copyWith(color: AppColors.textMuted),
              ),
              trailing: DropdownButton<String>(
                value: defaultSubtitleLanguage,
                dropdownColor: AppColors.surfaceElevated,
                underline: const SizedBox.shrink(),
                style: context.auraText.bodyOverview.copyWith(
                  color: AppColors.accentPink,
                  fontWeight: FontWeight.bold,
                ),
                items: languageOptions.map((lang) {
                  return DropdownMenuItem<String>(
                    value: lang['code'],
                    child: Text(lang['name']!),
                  );
                }).toList(),
                onChanged: onDefaultSubtitleLanguageChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsAboutAndLegalCard extends StatelessWidget {
  const SettingsAboutAndLegalCard({super.key});

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTokens.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.accentPink.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  ),
                  child: const AuraIcon(
                    AppIcons.movieFilter,
                    color: AppColors.accentPink,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aura Media Center',
                      style: context.auraText.itemTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'v2.4.0-premium (Build 108)',
                      style: context.auraText.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Aura is a high-performance open-source media player engine supporting Stremio add-ons, Debrid account multi-hoster unbinding, and 4K HDR playback.',
              style: context.auraText.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
