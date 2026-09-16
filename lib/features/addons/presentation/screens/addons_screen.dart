import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  const AddonsScreen({super.key});

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

  void _installPreset(CommunityAddonPreset preset) {
    context.read<AddonBloc>().add(
          InstallDirectAddonManifestEvent(preset.manifest),
        );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 4;

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
                child: BlocBuilder<AddonBloc, AddonState>(
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

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spacingMd,
                        vertical: AppTokens.spacingSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hub Header
                          Text(
                            'ENGINE HUB & ADD-ONS',
                            style: context.auraText.caption.copyWith(
                              color: AppColors.accentPink,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Install 1-click community engines and utility manifests on demand to resolve media sources.',
                            style: context.auraText.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spacingMd),

                          // SECTION 1: CORE STREAM ENGINES
                          Text(
                            'SECTION 1: CORE STREAM ENGINES',
                            style: context.auraText.caption.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spacingSm),

                          // Free Community Stream Engine Card
                          EngineHubStatusCard(
                            title: CommunityAddonPreset.freeCommunityEngine.name,
                            description:
                                CommunityAddonPreset.freeCommunityEngine.description,
                            icon: AppIcons.play,
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
                          const SizedBox(height: AppTokens.spacingLg),

                          // SECTION 2: UTILITY & SUBTITLES
                          Text(
                            'SECTION 2: UTILITY & SUBTITLES',
                            style: context.auraText.caption.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spacingSm),

                          EngineHubStatusCard(
                            title: CommunityAddonPreset.openSubtitlesEngine.name,
                            description:
                                CommunityAddonPreset.openSubtitlesEngine.description,
                            icon: AppIcons.download,
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

                          // SECTION 3: INSTALLED ADD-ONS & CUSTOM MANIFEST
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'INSTALLED ADD-ONS (${customAddons.length})',
                                style: context.auraText.caption.copyWith(
                                  color: AppColors.accentPink,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showInstallDialog(context),
                                icon: const AuraIcon(AppIcons.add,
                                    color: AppColors.accentPink, size: 16),
                                label: Text(
                                  'Add Custom Manifest',
                                  style: context.auraText.caption.copyWith(
                                    color: AppColors.accentPink,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spacingSm),

                          if (customAddons.isEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppTokens.spacingLg),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.radiusMedium),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Column(
                                children: [
                                  const AuraIcon(AppIcons.extension,
                                      color: AppColors.textMuted, size: 32),
                                  const SizedBox(height: AppTokens.spacingSm),
                                  Text(
                                    'No Engines or Add-ons Installed',
                                    style: context.auraText.itemTitle.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Install a Stream Engine above or paste a custom Stremio manifest URL to resolve media sources.',
                                    textAlign: TextAlign.center,
                                    style: context.auraText.caption
                                        .copyWith(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: customAddons.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final addon = customAddons[index];
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
                      ),
                    );
                  },
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
