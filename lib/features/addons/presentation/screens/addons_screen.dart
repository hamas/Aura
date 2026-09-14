import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../core/presentation/primitives/aura_page_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/datasources/stremio_addon_api.dart';
import '../bloc/addon_bloc.dart';
import '../bloc/addon_event.dart';
import '../bloc/addon_state.dart';
import '../widgets/components/addon_item_card.dart';
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

  @override
  Widget build(BuildContext context) {
    return AuraScaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surfaceBackground,
            title: Text(
              'Stremio Add-on Engine',
              style: context.auraText.sectionTitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const AuraIcon(AppIcons.add, color: AppColors.accentPink),
                tooltip: 'Install Add-on Manifest',
                onPressed: () => _showInstallDialog(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<AddonBloc, AddonState>(
              builder: (context, state) {
                if (state.status == AddonStatus.loading &&
                    state.installedAddons.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accentPink),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacingMd,
                    vertical: AppTokens.spacingSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Add-ons Section Header
                      Text(
                        'INSTALLED ADD-ONS (${state.installedAddons.length})',
                        style: context.auraText.caption.copyWith(
                          color: AppColors.accentPink,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppTokens.spacingSm),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.installedAddons.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final addon = state.installedAddons[index];
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
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
