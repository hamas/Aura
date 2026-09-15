import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../debrid/data/repositories/debrid_repository_impl.dart';
import '../../../debrid/domain/entities/debrid_account.dart';
import '../widgets/components/settings_debrid_card.dart';

class SettingsScreen extends StatefulWidget {
  final String? initialSubPage;

  const SettingsScreen({
    super.key,
    this.initialSubPage,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _currentSubPage;

  // Settings State
  String _uiLanguage = 'English';
  bool _quitOnClose = true;
  bool _escapeExitFullscreen = true;
  bool _blurUnwatchedEpisodes = false;
  bool _enableGamepadSupport = false;

  String _defaultSubtitlesLanguage = 'English';
  String _defaultSubtitlesSize = '100%';

  String _defaultAudioTrack = 'English';
  bool _surroundSound = false;

  bool _autoPlayNextEpisode = true;
  bool _hardwareAcceleratedDecoding = true;

  String _cacheSize = '2GiB';
  String _torrentProfile = 'Default';

  bool _showDiscordActivity = false;

  // Debrid Repository
  final DebridRepositoryImpl _debridRepo = DebridRepositoryImpl();
  DebridAccount? _debridAccount;
  bool _isLoadingDebrid = false;
  final TextEditingController _rdKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentSubPage = widget.initialSubPage;
    _loadSettings();
    _loadDebridStatus();
  }

  Future<void> _loadDebridStatus() async {
    setState(() => _isLoadingDebrid = true);
    try {
      if (await _debridRepo.hasValidToken()) {
        final acc = await _debridRepo.getAccountDetails();
        setState(() => _debridAccount = acc);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingDebrid = false);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _uiLanguage = prefs.getString('pref_ui_language') ?? 'English';
      _quitOnClose = prefs.getBool('pref_quit_on_close') ?? true;
      _escapeExitFullscreen = prefs.getBool('pref_escape_exit_fullscreen') ?? true;
      _blurUnwatchedEpisodes = prefs.getBool('pref_blur_unwatched') ?? false;
      _enableGamepadSupport = prefs.getBool('pref_gamepad_support') ?? false;

      _defaultSubtitlesLanguage = prefs.getString('pref_sub_lang') ?? 'English';
      _defaultSubtitlesSize = prefs.getString('pref_sub_size') ?? '100%';

      _defaultAudioTrack = prefs.getString('pref_audio_track') ?? 'English';
      _surroundSound = prefs.getBool('pref_surround_sound') ?? false;

      _autoPlayNextEpisode = prefs.getBool('pref_autoplay_next') ?? true;
      _hardwareAcceleratedDecoding = prefs.getBool('pref_hw_decoding') ?? true;

      _cacheSize = prefs.getString('pref_cache_size') ?? '2GiB';
      _torrentProfile = prefs.getString('pref_torrent_profile') ?? 'Default';

      _showDiscordActivity = prefs.getBool('pref_discord_activity') ?? false;
    });
  }

  Future<void> _saveBool(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  Future<void> _saveString(String key, String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, val);
  }

  @override
  void dispose() {
    _rdKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 8;

    return PopScope(
      canPop: _currentSubPage == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentSubPage != null) {
          setState(() => _currentSubPage = null);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceBackground,
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppTokens.spacingMd,
                  topPadding + AppTokens.spacingMd,
                  AppTokens.spacingMd,
                  AppTokens.spacingLg + 100,
                ),
                child: _currentSubPage == null
                    ? _buildMainSettingsMenu()
                    : _buildSubPageContent(),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AuraAdaptiveAppBar(
                title: _currentSubPage ?? 'Settings',
                opacity: 1.0,
                onBackPressed: _currentSubPage != null
                    ? () => setState(() => _currentSubPage = null)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MAIN SETTINGS SCREEN ---
  Widget _buildMainSettingsMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Minimal White Account Header Card
        _buildAccountDetailsHeader(),
        const SizedBox(height: AppTokens.spacingLg),

        // Section Title matching search screen text size & weight
        Text(
          'Settings & Options',
          style: context.auraText.caption.copyWith(
            fontSize: 13.0,
            fontWeight: FontWeight.normal,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // 2. Minimal Navigation List using Pill Cards & Material Symbols
        Column(
          children: [
            _buildMenuItemPill(
              icon: AppIcons.person,
              title: 'Profile',
              subtitle: 'Account details, cloud sync & auth session',
              onTap: () => setState(() => _currentSubPage = 'Profile'),
            ),
            const SizedBox(height: 8),
            _buildMenuItemPill(
              icon: AppIcons.tune,
              title: 'Interface',
              subtitle: 'Language, window controls & gamepad options',
              onTap: () => setState(() => _currentSubPage = 'Interface'),
            ),
            const SizedBox(height: 8),
            _buildMenuItemPill(
              icon: AppIcons.playCircle,
              title: 'Player',
              subtitle: 'Subtitles, audio tracks, seeking & auto-play',
              onTap: () => setState(() => _currentSubPage = 'Player'),
            ),
            const SizedBox(height: 8),
            _buildMenuItemPill(
              icon: AppIcons.bolt,
              title: 'Streaming',
              subtitle: 'Debrid providers, endpoints & cache profile',
              onTap: () => setState(() => _currentSubPage = 'Streaming'),
            ),
            const SizedBox(height: 8),
            _buildMenuItemPill(
              icon: AppIcons.shield,
              title: 'Policies',
              subtitle: 'Privacy policy & terms of service',
              onTap: () => setState(() => _currentSubPage = 'Policies'),
            ),
            const SizedBox(height: 8),
            _buildMenuItemPill(
              icon: AppIcons.infoOutline,
              title: 'Licence',
              subtitle: 'Open source software & legal notices',
              onTap: () => setState(() => _currentSubPage = 'Licence'),
            ),
          ],
        ),
      ],
    );
  }

  // --- MINIMAL ACCOUNT DETAILS CARD ---
  Widget _buildAccountDetailsHeader() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final joiningDateStr = user != null
            ? '${user.createdAt.year}-${user.createdAt.month.toString().padLeft(2, '0')}-${user.createdAt.day.toString().padLeft(2, '0')}'
            : 'N/A';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0x22FFFFFF),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white12,
                backgroundImage: user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null
                    ? const AuraIcon(
                        AppIcons.person,
                        color: Colors.white,
                        size: 26,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user != null ? user.displayName : 'Guest User',
                      style: context.auraText.bodyOverview.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (user != null) ...[
                          Image.asset(
                            AppAssets.googleLogo,
                            width: 13,
                            height: 13,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Expanded(
                          child: Text(
                            user != null
                                ? user.email
                                : 'Sign in to sync watchlist & cloud preferences',
                            style: context.auraText.caption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const AuraIcon(
                            AppIcons.history,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Member since: $joiningDateStr',
                            style: context.auraText.caption.copyWith(
                              color: Colors.white70,
                              fontSize: 11.0,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right-aligned action icon
              state.isAuthenticated
                  ? IconButton(
                      tooltip: 'Sign Out',
                      onPressed: () => context.read<AuthBloc>().add(SignOutEvent()),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                      ),
                      icon: const AuraIcon(
                        AppIcons.logout,
                        color: AppColors.statusError,
                        size: 20,
                      ),
                    )
                  : InkWell(
                      onTap: () => context.read<AuthBloc>().add(SignInWithGoogleEvent()),
                      borderRadius: BorderRadius.circular(100),
                      child: Tooltip(
                        message: 'Sign In with Google',
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: Image.asset(
                            AppAssets.googleLogo,
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  // Helper Pill Navigation Card
  Widget _buildMenuItemPill({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: AuraIcon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.auraText.bodyOverview.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
    );
  }

  // --- SUB PAGE ROUTER & BUILDER ---
  Widget _buildSubPageContent() {
    switch (_currentSubPage) {
      case 'Profile':
        return _buildProfileSubPage();
      case 'Interface':
        return _buildInterfaceSubPage();
      case 'Player':
        return _buildPlayerSubPage();
      case 'Streaming':
        return _buildStreamingSubPage();
      case 'Policies':
        return _buildPoliciesSubPage();
      case 'Licence':
        return _buildLicenceSubPage();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- SUB PAGE: PROFILE ---
  Widget _buildProfileSubPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAccountDetailsHeader(),
        const SizedBox(height: AppTokens.spacingLg),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trakt & Integrations',
                style: context.auraText.bodyOverview.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trakt Scrobbling',
                    style: context.auraText.caption.copyWith(
                      color: Colors.white70,
                      fontSize: 14.0,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {},
                    child: const Text('Authenticate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Divider(color: Color(0x1AFFFFFF), height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: Colors.black,
                activeTrackColor: Colors.white,
                inactiveThumbColor: Colors.white54,
                inactiveTrackColor: Colors.white10,
                title: Text(
                  'Show watching activity on Discord',
                  style: context.auraText.caption.copyWith(
                    color: Colors.white70,
                    fontSize: 14.0,
                  ),
                ),
                value: _showDiscordActivity,
                onChanged: (val) {
                  setState(() => _showDiscordActivity = val);
                  _saveBool('pref_discord_activity', val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SUB PAGE: INTERFACE ---
  Widget _buildInterfaceSubPage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'UI Language',
              style: context.auraText.bodyOverview.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14.0,
              ),
            ),
            subtitle: Text(
              'Select primary language for application menus',
              style: context.auraText.caption.copyWith(color: AppColors.textMuted, fontSize: 12.0),
            ),
            trailing: DropdownButton<String>(
              value: _uiLanguage,
              dropdownColor: const Color(0xFF1F1F1F),
              underline: const SizedBox.shrink(),
              style: context.auraText.bodyOverview.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.0,
              ),
              items: ['English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese']
                  .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _uiLanguage = val);
                  _saveString('pref_ui_language', val);
                }
              },
            ),
          ),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.black,
            activeTrackColor: Colors.white,
            title: Text('Quit on close', style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 14.0)),
            value: _quitOnClose,
            onChanged: (val) {
              setState(() => _quitOnClose = val);
              _saveBool('pref_quit_on_close', val);
            },
          ),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.black,
            activeTrackColor: Colors.white,
            title: Text('Escape key exit full screen', style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 14.0)),
            value: _escapeExitFullscreen,
            onChanged: (val) {
              setState(() => _escapeExitFullscreen = val);
              _saveBool('pref_escape_exit_fullscreen', val);
            },
          ),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.black,
            activeTrackColor: Colors.white,
            title: Text('Blur unwatched episodes image', style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 14.0)),
            value: _blurUnwatchedEpisodes,
            onChanged: (val) {
              setState(() => _blurUnwatchedEpisodes = val);
              _saveBool('pref_blur_unwatched', val);
            },
          ),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.black,
            activeTrackColor: Colors.white,
            title: Text('Enable gamepad support', style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 14.0)),
            value: _enableGamepadSupport,
            onChanged: (val) {
              setState(() => _enableGamepadSupport = val);
              _saveBool('pref_gamepad_support', val);
            },
          ),
        ],
      ),
    );
  }

  // --- SUB PAGE: PLAYER ---
  Widget _buildPlayerSubPage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitles
          _buildSubSectionTitle(AppIcons.subtitles, 'Subtitles'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Default Subtitles Language', style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 14.0)),
            trailing: DropdownButton<String>(
              value: _defaultSubtitlesLanguage,
              dropdownColor: const Color(0xFF1F1F1F),
              underline: const SizedBox.shrink(),
              style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 13.0),
              items: ['English', 'Spanish', 'French', 'German'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _defaultSubtitlesLanguage = val);
                  _saveString('pref_sub_lang', val);
                }
              },
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Default Subtitles Size', style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 14.0)),
            trailing: DropdownButton<String>(
              value: _defaultSubtitlesSize,
              dropdownColor: const Color(0xFF1F1F1F),
              underline: const SizedBox.shrink(),
              style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 13.0),
              items: ['75%', '100%', '125%', '150%'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _defaultSubtitlesSize = val);
                  _saveString('pref_sub_size', val);
                }
              },
            ),
          ),
          const Divider(color: Color(0x1AFFFFFF), height: 24),

          // Audio
          _buildSubSectionTitle(AppIcons.audiotrack, 'Audio'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Default Audio Track', style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 14.0)),
            trailing: DropdownButton<String>(
              value: _defaultAudioTrack,
              dropdownColor: const Color(0xFF1F1F1F),
              underline: const SizedBox.shrink(),
              style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 13.0),
              items: ['English', 'Spanish', 'French', 'German', 'Original'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _defaultAudioTrack = val);
                  _saveString('pref_audio_track', val);
                }
              },
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.black,
            activeTrackColor: Colors.white,
            title: Text('Surround sound', style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 14.0)),
            value: _surroundSound,
            onChanged: (val) {
              setState(() => _surroundSound = val);
              _saveBool('pref_surround_sound', val);
            },
          ),
          const Divider(color: Color(0x1AFFFFFF), height: 24),

          // Controls & Auto-Play
          _buildSubSectionTitle(AppIcons.tune, 'Playback & Performance'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.black,
            activeTrackColor: Colors.white,
            title: Text('Auto-Play Next Episode', style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 14.0)),
            value: _autoPlayNextEpisode,
            onChanged: (val) {
              setState(() => _autoPlayNextEpisode = val);
              _saveBool('pref_autoplay_next', val);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.black,
            activeTrackColor: Colors.white,
            title: Text('Hardware-accelerated decoding', style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 14.0)),
            value: _hardwareAcceleratedDecoding,
            onChanged: (val) {
              setState(() => _hardwareAcceleratedDecoding = val);
              _saveBool('pref_hw_decoding', val);
            },
          ),
        ],
      ),
    );
  }

  // --- SUB PAGE: STREAMING ---
  Widget _buildStreamingSubPage() {
    return Column(
      children: [
        SettingsDebridCard(
          isLoadingDebrid: _isLoadingDebrid,
          debridAccount: _debridAccount,
          rdKeyController: _rdKeyController,
          onSaveDebridKey: () async {
            final key = _rdKeyController.text.trim();
            if (key.isNotEmpty) {
              await _debridRepo.saveApiToken(key);
              _rdKeyController.clear();
              await _loadDebridStatus();
            }
          },
          onDisconnectDebrid: () async {
            await _debridRepo.removeToken();
            setState(() => _debridAccount = null);
          },
        ),
        const SizedBox(height: AppTokens.spacingMd),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubSectionTitle(AppIcons.bolt, 'Engine Options'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Cache size', style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 14.0)),
                trailing: DropdownButton<String>(
                  value: _cacheSize,
                  dropdownColor: const Color(0xFF1F1F1F),
                  underline: const SizedBox.shrink(),
                  style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 13.0),
                  items: ['1GiB', '2GiB', '5GiB', '10GiB'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _cacheSize = val);
                      _saveString('pref_cache_size', val);
                    }
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Torrent profile', style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 14.0)),
                trailing: DropdownButton<String>(
                  value: _torrentProfile,
                  dropdownColor: const Color(0xFF1F1F1F),
                  underline: const SizedBox.shrink(),
                  style: context.auraText.bodyOverview.copyWith(color: Colors.white, fontSize: 13.0),
                  items: ['Default', 'Fast', 'Low RAM'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _torrentProfile = val);
                      _saveString('pref_torrent_profile', val);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SUB PAGE: POLICIES ---
  Widget _buildPoliciesSubPage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubSectionTitle(AppIcons.shield, 'Terms of Service & Privacy Policy'),
          const SizedBox(height: 16),
          Text(
            'Terms of Service',
            style: context.auraText.bodyOverview.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '1. Client Application Scope\nAura is strictly a local-first client-side user interface, media player, and catalog manager. Aura does NOT host, index, scrape, upload, or distribute any media files, video streams, or torrent files.\n\n2. Disclaimer of Content & Liability\nAura provides no video content. All metadata and images are retrieved directly from third-party APIs. Aura disclaims all liability for content accessed via user-provided credentials or third-party debrid resolvers.\n\n3. User Compliance & Copyright\nUsers agree to comply with all applicable local and international copyright laws. Users are solely responsible for ensuring they possess lawful authorization for any media accessed.\n\n4. "As-Is" Warranty Limitation\nAura is provided "AS IS" without warranty of any kind, express or implied, including merchantability or fitness for a particular purpose.',
            style: context.auraText.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 12.5,
            ),
          ),
          const Divider(color: Color(0x1AFFFFFF), height: 28),
          Text(
            'Privacy Policy (Local-First)',
            style: context.auraText.bodyOverview.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '1. Zero Telemetry & Tracking\nAura collects zero usage telemetry, zero activity logs, and zero tracking analytics. We operate no tracking servers.\n\n2. On-Device Credentials & Tokens\nAll API keys (Real-Debrid, Trakt.tv) and local profile PINs are encrypted and stored exclusively on your local device. Credentials are transmitted directly to official service endpoints over HTTPS with no intermediary proxying.\n\n3. Local Storage & Downloads\nOffline downloads and cache files are sandboxed strictly within your device\'s local storage filesystem.\n\n4. Data Wipe\nYou may instantly purge all locally stored credentials, settings, and cached data at any time via Settings.',
            style: context.auraText.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB PAGE: LICENCE ---
  Widget _buildLicenceSubPage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubSectionTitle(AppIcons.infoOutline, 'Open Source Licences & Attributions'),
          const SizedBox(height: 16),
          Text(
            'Application License (MIT)',
            style: context.auraText.bodyOverview.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Copyright (c) 2026 Aura Media Center\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software.',
            style: context.auraText.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
              fontSize: 12.0,
            ),
          ),
          const Divider(color: Color(0x1AFFFFFF), height: 28),
          Text(
            'Third-Party Service Attributions',
            style: context.auraText.bodyOverview.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• TMDB API Notice:\nThis product uses the TMDB API but is not endorsed or certified by TMDB.\n\n• Trakt.tv:\nScrobbling and watchlist synchronization powered by Trakt.tv API services.\n\n• Multimedia Engine:\nPlayback engine powered by MediaKit (libmpv wrapper), Flutter framework, and Material Symbols.',
            style: context.auraText.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        AuraIcon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: context.auraText.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13.0,
          ),
        ),
      ],
    );
  }
}
