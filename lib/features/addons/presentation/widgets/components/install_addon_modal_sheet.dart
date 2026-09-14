import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/datasources/stremio_addon_api.dart';
import '../../../domain/entities/addon_manifest.dart';

class InstallAddonModalSheet extends StatefulWidget {
  final StremioAddonApi addonApi;
  final ValueChanged<String> onInstall;

  const InstallAddonModalSheet({
    super.key,
    required this.addonApi,
    required this.onInstall,
  });

  static void show(BuildContext context, StremioAddonApi addonApi,
      ValueChanged<String> onInstall) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => InstallAddonModalSheet(
        addonApi: addonApi,
        onInstall: onInstall,
      ),
    );
  }

  @override
  State<InstallAddonModalSheet> createState() => _InstallAddonModalSheetState();
}

class _InstallAddonModalSheetState extends State<InstallAddonModalSheet> {
  final TextEditingController _urlController = TextEditingController();
  AddonManifest? _previewManifest;
  bool _isVerifying = false;
  String? _verifyError;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _verifyUrl() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) return;
    setState(() {
      _isVerifying = true;
      _verifyError = null;
      _previewManifest = null;
    });
    try {
      final manifest = await widget.addonApi.fetchManifest(rawUrl);
      setState(() {
        _previewManifest = manifest;
        _isVerifying = false;
      });
    } catch (e) {
      setState(() {
        _verifyError = 'Invalid Stremio manifest URL or failed connection.';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTokens.radiusLarge)),
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingLg,
          vertical: AppTokens.spacingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppTokens.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withAlpha((0.4 * 255).round()),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const AuraIcon(AppIcons.extension,
                    color: AppColors.accentPink, size: 22),
                const SizedBox(width: AppTokens.spacingSm),
                Text(
                  'Install Stremio Add-on',
                  style: context.auraText.sectionTitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
            Text(
              'Paste an HTTP or HTTPS Stremio v3 manifest URL to verify and install.',
              style: context.auraText.bodyOverview
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppTokens.spacingMd),

            // URL Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    autofocus: true,
                    style: context.auraText.bodyOverview
                        .copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'https://addon-domain.com/manifest.json',
                      hintStyle: context.auraText.caption
                          .copyWith(color: AppColors.textMuted),
                      prefixIcon: const AuraIcon(AppIcons.link,
                          color: AppColors.accentPink, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _verifyUrl(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPink,
                    foregroundColor: AppColors.surfaceBackground,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.textPrimary),
                        )
                      : const Text('Verify'),
                ),
              ],
            ),

            if (_verifyError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.statusError.withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  border: Border.all(
                      color:
                          AppColors.statusError.withAlpha((0.4 * 255).round())),
                ),
                child: Row(
                  children: [
                    const AuraIcon(AppIcons.errorOutline,
                        color: AppColors.statusError, size: 18),
                    const SizedBox(width: AppTokens.spacingSm),
                    Expanded(
                      child: Text(
                        _verifyError!,
                        style: context.auraText.caption
                            .copyWith(color: AppColors.statusError),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Verified Preview Card
            if (_previewManifest != null) ...[
              const SizedBox(height: AppTokens.spacingMd),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                  border: Border.all(
                      color: AppColors.statusSuccess
                          .withAlpha((0.4 * 255).round())),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTokens.spacingSm),
                          decoration: BoxDecoration(
                            color: AppColors.statusSuccess
                                .withAlpha((0.15 * 255).round()),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusSmall),
                          ),
                          child: const AuraIcon(AppIcons.checkCircle,
                              color: AppColors.statusSuccess, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _previewManifest!.name,
                                style: context.auraText.itemTitle.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Version ${_previewManifest!.version}',
                                style: context.auraText.caption
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_previewManifest!.description.isNotEmpty) ...[
                      const SizedBox(height: AppTokens.spacingSm),
                      Text(
                        _previewManifest!.description,
                        style: context.auraText.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPink,
                          foregroundColor: AppColors.surfaceBackground,
                        ),
                        onPressed: () {
                          widget.onInstall(_urlController.text.trim());
                          Navigator.pop(context);
                        },
                        icon: const AuraIcon(AppIcons.extension, size: 18),
                        label: const Text('Confirm & Install Add-on'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppTokens.spacingLg),
          ],
        ),
      ),
    );
  }
}
