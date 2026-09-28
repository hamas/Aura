import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/presentation/primitives/aura_card.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/smart_download_settings.dart';
import '../../../domain/repositories/smart_download_settings_repository.dart';

/// Netflix-style Smart Downloads Configuration Modal.
/// Provides control over automated episode downloads, storage quotas,
/// Wi-Fi guards, and quality presets.
class SmartDownloadsSettingsModal extends StatefulWidget {
  const SmartDownloadsSettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const SmartDownloadsSettingsModal(),
    );
  }

  @override
  State<SmartDownloadsSettingsModal> createState() =>
      _SmartDownloadsSettingsModalState();
}

class _SmartDownloadsSettingsModalState
    extends State<SmartDownloadsSettingsModal> {
  SmartDownloadSettings _settings = const SmartDownloadSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = context.read<SmartDownloadSettingsRepository>();
    final loaded = await repo.loadSettings();
    if (mounted) {
      setState(() {
        _settings = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings(SmartDownloadSettings updated) async {
    setState(() => _settings = updated);
    final repo = context.read<SmartDownloadSettingsRepository>();
    await repo.saveSettings(updated);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentPink),
            )
          : SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.screenEdgeHorizontal,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Drag Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Modal Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentPink.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const AuraIcon(
                            AppIcons.download,
                            color: AppColors.accentPink,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Downloads',
                                style: (context.auraText.titleMedium ??
                                        const TextStyle(fontSize: 16))
                                    .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Automate your offline entertainment',
                                style: context.auraText.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Explainer Card
                    AuraCard(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.successAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'When you finish an episode, Smart Downloads deletes it and downloads the next one for you when connected to Wi-Fi.',
                              style: context.auraText.caption.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. Feature Switches Section
                    _buildSwitchTile(
                      title: 'Smart Downloads',
                      subtitle: 'Auto-download next episode on completion',
                      icon: Icons.auto_awesome,
                      value: _settings.enabled,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        _updateSettings(_settings.copyWith(enabled: val));
                      },
                    ),
                    const Divider(color: Colors.white12, height: 1),

                    _buildSwitchTile(
                      title: 'Auto-Delete Watched',
                      subtitle: 'Delete episode file once finished (≥90%)',
                      icon: Icons.delete_sweep_outlined,
                      value: _settings.autoDeleteWatched,
                      enabled: _settings.enabled,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        _updateSettings(
                            _settings.copyWith(autoDeleteWatched: val));
                      },
                    ),
                    const Divider(color: Colors.white12, height: 1),

                    _buildSwitchTile(
                      title: 'Download on Wi-Fi Only',
                      subtitle: 'Prevents cellular mobile data usage',
                      icon: Icons.wifi,
                      value: _settings.downloadOnWifiOnly,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        _updateSettings(
                            _settings.copyWith(downloadOnWifiOnly: val));
                      },
                    ),
                    const SizedBox(height: 24),

                    // 5. Download Video Quality Preset
                    Text(
                      'VIDEO QUALITY PRESET',
                      style: context.auraText.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQualityOption(
                            label: 'Standard',
                            resolution: '720p',
                            description: 'Faster, less storage',
                            isSelected:
                                _settings.quality == DownloadQuality.standard,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _updateSettings(_settings.copyWith(
                                quality: DownloadQuality.standard,
                              ));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQualityOption(
                            label: 'High',
                            resolution: '1080p',
                            description: 'Crisp video & sound',
                            isSelected:
                                _settings.quality == DownloadQuality.high,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _updateSettings(_settings.copyWith(
                                quality: DownloadQuality.high,
                              ));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 6. Episodes Buffer Size (1 to 3)
                    Text(
                      'UPCOMING EPISODES BUFFER',
                      style: context.auraText.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how many episodes to keep ready ahead of your current progress:',
                      style: context.auraText.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [1, 2, 3].map((count) {
                        final isSelected = _settings.bufferSize == count;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _updateSettings(
                                  _settings.copyWith(bufferSize: count));
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accentPink
                                    : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.accentPink
                                      : Colors.white12,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$count ${count == 1 ? 'Episode' : 'Episodes'}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 7. Done Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            icon,
            color: enabled ? Colors.white70 : Colors.white24,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: enabled ? AppColors.textSecondary : Colors.white24,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.accentPink,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _buildQualityOption({
    required String label,
    required String resolution,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPink.withValues(alpha: 0.15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentPink : Colors.white12,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.accentPink : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentPink
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    resolution,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
