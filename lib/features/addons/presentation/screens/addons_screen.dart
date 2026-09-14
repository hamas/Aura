import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/primitives/aura_icon.dart';
import '../../data/datasources/stremio_addon_api.dart';
import '../../domain/entities/addon_manifest.dart';
import '../bloc/addon_bloc.dart';
import '../bloc/addon_event.dart';
import '../bloc/addon_state.dart';

class AddonsScreen extends StatefulWidget {
  const AddonsScreen({super.key});

  @override
  State<AddonsScreen> createState() => _AddonsScreenState();
}

class _AddonsScreenState extends State<AddonsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final StremioAddonApi _addonApi = StremioAddonApi();

  @override
  void initState() {
    super.initState();
    context.read<AddonBloc>().add(LoadAddonsEvent());
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _showInstallDialog(BuildContext context) {
    _urlController.clear();
    AddonManifest? previewManifest;
    bool isVerifying = false;
    String? verifyError;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(top: BorderSide(color: Color(0xFF222B3F))),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.textMuted.withAlpha((0.4 * 255).round()),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Row(
                      children: [
                        AuraIcon(AppIcons.extension,
                            color: AppTheme.primaryAccent, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Install Stremio Add-on',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Paste an HTTP or HTTPS Stremio v3 manifest URL to verify and install.',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // URL Input Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            autofocus: true,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText:
                                  'https://addon-domain.com/manifest.json',
                              prefixIcon: AuraIcon(AppIcons.link,
                                  color: AppTheme.primaryAccent, size: 20),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                            ),
                            onSubmitted: (_) async {
                              final rawUrl = _urlController.text.trim();
                              if (rawUrl.isEmpty) return;
                              setModalState(() {
                                isVerifying = true;
                                verifyError = null;
                                previewManifest = null;
                              });
                              try {
                                final manifest =
                                    await _addonApi.fetchManifest(rawUrl);
                                setModalState(() {
                                  previewManifest = manifest;
                                  isVerifying = false;
                                });
                              } catch (e) {
                                setModalState(() {
                                  verifyError = 'Failed to load manifest: $e';
                                  isVerifying = false;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: isVerifying
                              ? null
                              : () async {
                                  final rawUrl = _urlController.text.trim();
                                  if (rawUrl.isEmpty) return;
                                  setModalState(() {
                                    isVerifying = true;
                                    verifyError = null;
                                    previewManifest = null;
                                  });
                                  try {
                                    final manifest =
                                        await _addonApi.fetchManifest(rawUrl);
                                    setModalState(() {
                                      previewManifest = manifest;
                                      isVerifying = false;
                                    });
                                  } catch (e) {
                                    setModalState(() {
                                      verifyError =
                                          'Invalid Stremio manifest URL.';
                                      isVerifying = false;
                                    });
                                  }
                                },
                          child: isVerifying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Verify'),
                        ),
                      ],
                    ),

                    if (verifyError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.errorAccent
                              .withAlpha((0.15 * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.errorAccent
                                  .withAlpha((0.4 * 255).round())),
                        ),
                        child: Row(
                          children: [
                            const AuraIcon(AppIcons.errorOutline,
                                color: AppTheme.errorAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                verifyError!,
                                style: const TextStyle(
                                    color: AppTheme.errorAccent, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Verified Preview Card
                    if (previewManifest != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.successAccent
                                  .withAlpha((0.4 * 255).round())),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successAccent
                                        .withAlpha((0.15 * 255).round()),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const AuraIcon(AppIcons.checkCircle,
                                      color: AppTheme.successAccent, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        previewManifest!.name,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        'Version ${previewManifest!.version}',
                                        style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (previewManifest!.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                previewManifest!.description,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              children: previewManifest!.resources.map((res) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    res.toUpperCase(),
                                    style: const TextStyle(
                                        color: AppTheme.primaryAccent,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.read<AddonBloc>().add(
                                  InstallAddonFromUrlEvent(
                                      _urlController.text.trim()),
                                );
                            Navigator.pop(sheetContext);
                          },
                          icon: const AuraIcon(AppIcons.download, size: 20),
                          label: const Text('Confirm & Install Add-on'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Community Add-ons'),
        actions: [
          IconButton(
            icon:
                const AuraIcon(AppIcons.addLink, color: AppTheme.primaryAccent),
            tooltip: 'Install via URL',
            onPressed: () => _showInstallDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInstallDialog(context),
        backgroundColor: AppTheme.primaryAccent,
        icon: const AuraIcon(AppIcons.add, color: Colors.white),
        label: const Text('Install Addon',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: BlocConsumer<AddonBloc, AddonState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.errorAccent,
                content: Text(state.errorMessage!),
              ),
            );
          } else if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.successAccent,
                content: Text(state.successMessage!),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == AddonStatus.loading &&
              state.installedAddons.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryAccent),
            );
          }

          if (state.installedAddons.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AuraIcon(AppIcons.extensionOff,
                        size: 64, color: AppTheme.textMuted),
                    const SizedBox(height: 16),
                    const Text(
                      'No add-ons currently installed',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aura relies on external Stremio v3 HTTP/JSON manifests for streams and subtitles.',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showInstallDialog(context),
                      icon: const AuraIcon(AppIcons.add),
                      label: const Text('Install Manifest URL'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: state.installedAddons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final addon = state.installedAddons[index];
              return _buildAddonCard(context, addon);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddonCard(BuildContext context, AddonManifest addon) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E283E)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF26324D)),
                ),
                child: const AuraIcon(AppIcons.extension,
                    color: AppTheme.primaryAccent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            addon.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F293E),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'v${addon.version}',
                            style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      addon.transportUrl,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Switch(
                value: addon.isEnabled,
                activeThumbColor: AppTheme.primaryAccent,
                onChanged: (val) {
                  context.read<AddonBloc>().add(
                        ToggleAddonStatusEvent(addon.id, val),
                      );
                },
              ),
            ],
          ),
          if (addon.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              addon.description,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12.5, height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              // Supported resources & types pills
              Wrap(
                spacing: 6,
                children: [
                  ...addon.resources.take(3).map((res) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2335),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        res.toUpperCase(),
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
                  ...addon.types.take(2).map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14241E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t.toUpperCase(),
                        style: const TextStyle(
                            color: AppTheme.successAccent,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const AuraIcon(AppIcons.delete,
                    color: AppTheme.errorAccent, size: 20),
                tooltip: 'Uninstall',
                onPressed: () {
                  context.read<AddonBloc>().add(UninstallAddonEvent(addon.id));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
