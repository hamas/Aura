import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_theme.dart';
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Install Stremio Add-on'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter manifest URL (e.g. https://example.com/manifest.json)',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link, color: AppTheme.primaryAccent),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final url = _urlController.text.trim();
                if (url.isNotEmpty) {
                  Navigator.pop(dialogContext);
                  context.read<AddonBloc>().add(InstallAddonFromUrlEvent(url));
                }
              },
              child: const Text('Install'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Add-ons Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryAccent),
            tooltip: 'Install Add-on',
            onPressed: () => _showInstallDialog(context),
          ),
        ],
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
          if (state.status == AddonStatus.loading && state.installedAddons.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryAccent),
            );
          }

          if (state.installedAddons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.extension_off_outlined, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  const Text(
                    'No add-ons installed',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showInstallDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Install Manifest URL'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
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
    return Card(
      child: Padding(
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.extension, color: AppTheme.primaryAccent, size: 24),
                ),
                const SizedBox(width: 12),
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'v${addon.version}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        addon.transportUrl,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
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
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                // Supported resources badges
                Wrap(
                  spacing: 6,
                  children: addon.resources.take(3).map((res) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        res,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      ),
                    );
                  }).toList(),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.errorAccent, size: 20),
                  tooltip: 'Uninstall',
                  onPressed: () {
                    context.read<AddonBloc>().add(UninstallAddonEvent(addon.id));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
