import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/addon_preset.dart';
import '../../data/datasources/stremio_addon_api.dart';
import '../bloc/addon_bloc.dart';
import '../bloc/addon_event.dart';
import '../bloc/addon_state.dart';
import '../widgets/components/addon_item_card.dart';
import '../widgets/components/engine_hub_status_card.dart';
import '../widgets/components/install_addon_modal_sheet.dart';

class AddonsScreen extends StatefulWidget {
  final bool isStandaloneScreen;

  const AddonsScreen({
    super.key,
    this.isStandaloneScreen = true,
  });

  @override
  State<AddonsScreen> createState() => _AddonsScreenState();
}

class _AddonsScreenState extends State<AddonsScreen> {
  final StremioAddonApi _addonApi = StremioAddonApi();

  @override
  void initState() {
    super.initState();
    context.read<AddonBloc>().add(LoadAddonsEvent());
  }

  void _showInstallDialog(BuildContext context) {
    InstallAddonModalSheet.show(
      context,
      _addonApi,
      (manifestUrl) {
        context.read<AddonBloc>().add(InstallAddonFromUrlEvent(manifestUrl));
      },
    );
  }

  Future<void> _launchCommunityDirectory() async {
    final uri = Uri.parse(CommunityAddonPreset.communityDirectoryUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _installPreset(CommunityAddonPreset preset) {
    context.read<AddonBloc>().add(
          InstallDirectAddonManifestEvent(preset.manifest),
        );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = widget.isStandaloneScreen
        ? MediaQuery.of(context).padding.top + kToolbarHeight + 4
        : 0.0;

    final content = BlocBuilder<AddonBloc, AddonState>(
      builder: (context, state) {
        final isLoading = state.status == AddonStatus.loading;
        final hasError = state.status == AddonStatus.failure;

        // Presets status
        final freeEngineInstalled = state.installedAddons
            .any((a) => a.id == CommunityAddonPreset.freeCommunityEngine.id);
        final freeEngineActive = freeEngineInstalled &&
            state.installedAddons
                .firstWhere((a) => a.id == CommunityAddonPreset.freeCommunityEngine.id)
                .isEnabled;

        final subtitlesEngineInstalled = state.installedAddons
            .any((a) => a.id == CommunityAddonPreset.openSubtitlesEngine.id);
        final subtitlesEngineActive = subtitlesEngineInstalled &&
            state.installedAddons
                .firstWhere((a) => a.id == CommunityAddonPreset.openSubtitlesEngine.id)
                .isEnabled;

        final customAddons = state.installedAddons;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title matching Settings screen design
            Text(
              'Community Engines & Add-ons',
              style: context.auraText.caption.copyWith(
                fontSize: 13.0,
                fontWeight: FontWeight.normal,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Prominent Community Add-ons Banner Button (Minimal White Glass Card Style)
            GestureDetector(
              onTap: _launchCommunityDirectory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0x1AFFFFFF),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const AuraIcon(
                        AppIcons.language,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Browse Community Directory',
                                style: context.auraText.bodyOverview.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.0,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const AuraIcon(
                                AppIcons.openInNew,
                                color: AppColors.textMuted,
                                size: 14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Explore web directory with 1-click install add-ons & engines',
                            style: context.auraText.caption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AuraIcon(
                      AppIcons.chevronRight,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingLg),

            // Free Community Stream Engine Card
            EngineHubStatusCard(
              title: CommunityAddonPreset.freeCommunityEngine.name,
              description:
                  CommunityAddonPreset.freeCommunityEngine.description,
              icon: AppIcons.playCircle,
              status: isLoading
                  ? EngineStatus.downloading
                  : (freeEngineInstalled
                      ? EngineStatus.installed
                      : (hasError ? EngineStatus.error : EngineStatus.notInstalled)),
              errorMessage: hasError ? state.errorMessage : null,
              isActive: freeEngineActive,
              onInstallOrUpdate: () => _installPreset(
                  CommunityAddonPreset.freeCommunityEngine),
              onUninstall: freeEngineInstalled
                  ? () => context.read<AddonBloc>().add(
                        UninstallAddonEvent(
                            CommunityAddonPreset.freeCommunityEngine.id),
                      )
                  : null,
              onToggleActive: freeEngineInstalled
                  ? (val) => context.read<AddonBloc>().add(
                        ToggleAddonStatusEvent(
                            CommunityAddonPreset.freeCommunityEngine.id, val),
                      )
                  : null,
            ),
            const SizedBox(height: AppTokens.spacingSm),

            // OpenSubtitles Engine Card
            EngineHubStatusCard(
              title: CommunityAddonPreset.openSubtitlesEngine.name,
              description:
                  CommunityAddonPreset.openSubtitlesEngine.description,
              icon: AppIcons.subtitles,
              status: isLoading
                  ? EngineStatus.downloading
                  : (subtitlesEngineInstalled
                      ? EngineStatus.installed
                      : (hasError ? EngineStatus.error : EngineStatus.notInstalled)),
              errorMessage: hasError ? state.errorMessage : null,
              isActive: subtitlesEngineActive,
              onInstallOrUpdate: () => _installPreset(
                  CommunityAddonPreset.openSubtitlesEngine),
              onUninstall: subtitlesEngineInstalled
                  ? () => context.read<AddonBloc>().add(
                        UninstallAddonEvent(
                            CommunityAddonPreset.openSubtitlesEngine.id),
                      )
                  : null,
              onToggleActive: subtitlesEngineInstalled
                  ? (val) => context.read<AddonBloc>().add(
                        ToggleAddonStatusEvent(
                            CommunityAddonPreset.openSubtitlesEngine.id, val),
                      )
                  : null,
            ),
            const SizedBox(height: AppTokens.spacingLg),

            // Installed Custom Add-ons List (if any custom URL manifests added)
            if (customAddons.where((a) =>
                a.id != CommunityAddonPreset.freeCommunityEngine.id &&
                a.id != CommunityAddonPreset.openSubtitlesEngine.id).isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Custom Add-ons',
                    style: context.auraText.caption.copyWith(
                      fontSize: 13.0,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showInstallDialog(context),
                    child: Row(
                      children: [
                        const AuraIcon(AppIcons.add,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Add Manifest',
                          style: context.auraText.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: customAddons.where((a) =>
                    a.id != CommunityAddonPreset.freeCommunityEngine.id &&
                    a.id != CommunityAddonPreset.openSubtitlesEngine.id).length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final addon = customAddons.where((a) =>
                      a.id != CommunityAddonPreset.freeCommunityEngine.id &&
                      a.id != CommunityAddonPreset.openSubtitlesEngine.id).elementAt(index);
                  return AddonItemCard(
                    addon: addon,
                    onUninstall: () {
                      context
                          .read<AddonBloc>()
                          .add(UninstallAddonEvent(addon.id));
                    },
                  );
                },
              ),
            ],
            const SizedBox(height: 40),
          ],
        );
      },
    );

    if (!widget.isStandaloneScreen) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingSm,
          vertical: AppTokens.spacingSm,
        ),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(top: topPadding),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacingMd,
                    vertical: AppTokens.spacingSm,
                  ),
                  child: content,
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuraAdaptiveAppBar(
              title: 'Add-ons & Engine Hub',
              opacity: 1.0,
              actions: [
                IconButton(
                  icon:
                      const AuraIcon(AppIcons.add, color: AppColors.accentPink),
                  tooltip: 'Install Custom Manifest',
                  onPressed: () => _showInstallDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
