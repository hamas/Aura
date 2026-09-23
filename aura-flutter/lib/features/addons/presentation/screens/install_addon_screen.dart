import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/addon_preset.dart';
import '../bloc/addon_bloc.dart';
import '../bloc/addon_event.dart';
import '../bloc/addon_state.dart';

class InstallAddonScreen extends StatefulWidget {
  const InstallAddonScreen({super.key});

  @override
  State<InstallAddonScreen> createState() => _InstallAddonScreenState();
}

class _InstallAddonScreenState extends State<InstallAddonScreen> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isInstalling = false;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _urlController.text = data.text!.trim();
        _errorMessage = null;
      });
    }
  }

  Future<void> _launchCommunityDirectory() async {
    final uri = Uri.parse(CommunityAddonPreset.communityDirectoryUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _submitUrl() {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid Stremio HTTPS manifest URL.';
      });
      return;
    }

    String formattedUrl = rawUrl;
    if (formattedUrl.startsWith('stremio://')) {
      formattedUrl = formattedUrl.replaceFirst('stremio://', 'https://');
    } else if (formattedUrl.startsWith('aura://addon/install?url=')) {
      formattedUrl = Uri.decodeComponent(
        formattedUrl.replaceFirst('aura://addon/install?url=', ''),
      );
    }

    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      setState(() {
        _errorMessage = 'URL must start with http:// or https://';
      });
      return;
    }

    if (!formattedUrl.endsWith('/manifest.json')) {
      if (formattedUrl.endsWith('/')) {
        formattedUrl += 'manifest.json';
      } else if (!formattedUrl.contains('manifest.json')) {
        formattedUrl += '/manifest.json';
      }
    }

    setState(() {
      _isInstalling = true;
      _errorMessage = null;
    });

    context.read<AddonBloc>().add(InstallAddonFromUrlEvent(formattedUrl));
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 12;

    return BlocListener<AddonBloc, AddonState>(
      listener: (context, state) {
        if (state.status == AddonStatus.success && _isInstalling) {
          setState(() => _isInstalling = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.statusSuccess,
              behavior: SnackBarBehavior.floating,
              content: Text(
                state.successMessage ?? 'Add-on installed successfully!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
          context.pop();
        } else if (state.status == AddonStatus.failure && _isInstalling) {
          setState(() {
            _isInstalling = false;
            _errorMessage = state.errorMessage ?? 'Failed to install add-on manifest.';
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceBackground,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: topPadding,
                left: AppTokens.spacingMd,
                right: AppTokens.spacingMd,
                bottom: 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Install Custom Add-on Manifest',
                    style: AppTypography.sectionTitle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter a Stremio v3 manifest URL (e.g. Torrentio with Debrid configuration or CyberFlix catalog) to install custom streaming extensions.',
                    style: AppTypography.bodyOverview.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // URL Input Container
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141923),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _errorMessage != null
                            ? AppColors.statusError
                            : const Color(0xFF222B3F),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        const AuraIcon(
                          AppIcons.extension,
                          color: AppColors.accentPink,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            focusNode: _focusNode,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'https://torrentio.strem.fun/.../manifest.json',
                              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submitUrl(),
                          ),
                        ),
                        IconButton(
                          icon: const AuraIcon(AppIcons.link, color: AppColors.textSecondary, size: 18),
                          tooltip: 'Paste from clipboard',
                          onPressed: _pasteFromClipboard,
                        ),
                      ],
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const AuraIcon(AppIcons.warning, color: AppColors.statusError, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.statusError,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isInstalling ? null : _submitUrl,
                      child: _isInstalling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Install Add-on',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Shortcut Card for Community Directory
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1E2838)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentPink.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const AuraIcon(
                            AppIcons.autoAwesome,
                            color: AppColors.accentPink,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Explore Community Registry',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Discover hundreds of verified community manifests on stremio-addons.net',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const AuraIcon(AppIcons.chevronRight, color: Colors.white70, size: 20),
                          onPressed: _launchCommunityDirectory,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Top Bar
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AuraAdaptiveAppBar(
                title: 'Add Manifest URL',
                opacity: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
