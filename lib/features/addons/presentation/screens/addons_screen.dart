import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
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

  // Engine installation endpoints
  static const String _defaultStreamEngineUrl =
      'https://torrentio.strem.fun/manifest.json';
  static const String _defaultDownloadEngineUrl =
      'https://opensubtitles-v3.strem.io/manifest.json';

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

  void _installEngine(String manifestUrl) {
    context.read<AddonBloc>().add(InstallAddonFromUrlEvent(manifestUrl));
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

                    // Stream engine check (addons with 'stream' resource or stream-capable)
                    final streamEngines = state.installedAddons
                        .where((a) => a.supportsResource('stream') || a.id.contains('torrentio') || a.id.contains('stream'))
                        .toList();
                    final hasStreamEngine = streamEngines.isNotEmpty;
                    final activeStreamEngine = hasStreamEngine ? streamEngines.first : null;

                    // Download engine check
                    final downloadEngines = state.installedAddons
                        .where((a) => a.id.contains('download') || a.supportsResource('subtitles') || a.supportsResource('stream'))
                        .toList();
                    final hasDownloadEngine = downloadEngines.isNotEmpty;
                    final activeDownloadEngine = hasDownloadEngine ? downloadEngines.first : null;

                    // Custom / external third-party add-ons
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
                            'Install streaming and download engine manifests on demand to unblock media resolution.',
                            style: context.auraText.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spacingMd),

                          // Section 1: Stream Engine Card
                          EngineHubStatusCard(
                            title: 'Stream Engine',
                            description:
                                'Enables Stremio v3 protocol stream manifest resolution and HTTP/P2P link parsing.',
                            icon: AppIcons.play,
                            status: isLoading
                                ? EngineStatus.downloading
                                : (hasStreamEngine
                                    ? EngineStatus.installed
                                    : (hasError ? EngineStatus.error : EngineStatus.notInstalled)),
                            errorMessage: hasError ? state.errorMessage : null,
                            isActive: activeStreamEngine?.isEnabled ?? true,
                            onInstallOrUpdate: () => _installEngine(_defaultStreamEngineUrl),
                            onUninstall: activeStreamEngine != null
                                ? () => context
                                    .read<AddonBloc>()
                                    .add(UninstallAddonEvent(activeStreamEngine.id))
                                : null,
                            onToggleActive: activeStreamEngine != null
                                ? (val) => context.read<AddonBloc>().add(
                                    ToggleAddonStatusEvent(activeStreamEngine.id, val))
                                : null,
                          ),
                          const SizedBox(height: AppTokens.spacingMd),

                          // Section 2: Download Engine Card
                          EngineHubStatusCard(
                            title: 'Download Engine',
                            description:
                                'Enables background media fetching, offline storage caching, and subtitle indexing.',
                            icon: AppIcons.download,
                            status: isLoading
                                ? EngineStatus.downloading
                                : (hasDownloadEngine
                                    ? EngineStatus.installed
                                    : (hasError ? EngineStatus.error : EngineStatus.notInstalled)),
                            errorMessage: hasError ? state.errorMessage : null,
                            isActive: activeDownloadEngine?.isEnabled ?? true,
                            onInstallOrUpdate: () => _installEngine(_defaultDownloadEngineUrl),
                            onUninstall: activeDownloadEngine != null
                                ? () => context
                                    .read<AddonBloc>()
                                    .add(UninstallAddonEvent(activeDownloadEngine.id))
                                : null,
                            onToggleActive: activeDownloadEngine != null
                                ? (val) => context.read<AddonBloc>().add(
                                    ToggleAddonStatusEvent(activeDownloadEngine.id, val))
                                : null,
                          ),
                          const SizedBox(height: AppTokens.spacingLg),

                          // Section 3: Installed Add-ons List & Custom Manifest Paste
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
