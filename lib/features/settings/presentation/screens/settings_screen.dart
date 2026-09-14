import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../debrid/data/repositories/debrid_repository_impl.dart';
import '../../../debrid/domain/entities/debrid_account.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _rdKeyController = TextEditingController();
  final DebridRepositoryImpl _debridRepo = DebridRepositoryImpl();
  DebridAccount? _debridAccount;
  bool _isLoadingDebrid = false;

  // Player preferences
  bool _hardwareAcceleration = true;
  String _defaultAudioLanguage = 'eng';
  String _defaultSubtitleLanguage = 'eng';

  final List<Map<String, String>> _languageOptions = [
    {'code': 'eng', 'name': 'English'},
    {'code': 'spa', 'name': 'Spanish'},
    {'code': 'fre', 'name': 'French'},
    {'code': 'ger', 'name': 'German'},
    {'code': 'ita', 'name': 'Italian'},
    {'code': 'por', 'name': 'Portuguese'},
    {'code': 'jpn', 'name': 'Japanese'},
    {'code': 'kor', 'name': 'Korean'},
    {'code': 'zho', 'name': 'Chinese'},
    {'code': 'ara', 'name': 'Arabic'},
    {'code': 'rus', 'name': 'Russian'},
    {'code': 'hin', 'name': 'Hindi'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDebridStatus();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hardwareAcceleration = prefs.getBool('pref_hardware_acceleration') ?? true;
      _defaultAudioLanguage = prefs.getString('pref_default_audio_lang') ?? 'eng';
      _defaultSubtitleLanguage = prefs.getString('pref_default_sub_lang') ?? 'eng';
    });
  }

  Future<void> _savePreferenceBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _savePreferenceString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _loadDebridStatus() async {
    setState(() => _isLoadingDebrid = true);
    try {
      final hasToken = await _debridRepo.hasValidToken();
      if (hasToken) {
        final account = await _debridRepo.getAccountDetails();
        setState(() {
          _debridAccount = account;
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingDebrid = false);
    }
  }

  Future<void> _saveDebridKey() async {
    final key = _rdKeyController.text.trim();
    if (key.isNotEmpty) {
      await _debridRepo.saveApiToken(key);
      _rdKeyController.clear();
      await _loadDebridStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.successAccent,
            content: Text('Real-Debrid API key saved successfully'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _rdKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Settings & Preferences',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // 1. Account Section
          _buildSectionHeader('Account & Cloud Continuity', Icons.cloud_sync_outlined),
          const SizedBox(height: 10),
          _buildAccountCard(),
          const SizedBox(height: 24),

          // 2. Streaming & Debrid Engine Section
          _buildSectionHeader('Debrid Engine & Multi-hoster', Icons.bolt_outlined),
          const SizedBox(height: 10),
          _buildDebridCard(),
          const SizedBox(height: 24),

          // 3. Player Preferences Section
          _buildSectionHeader('Player Preferences', Icons.tune_rounded),
          const SizedBox(height: 10),
          _buildPlayerPreferencesCard(),
          const SizedBox(height: 24),

          // 4. About & Legal Section
          _buildSectionHeader('About & Legal', Icons.info_outline_rounded),
          const SizedBox(height: 10),
          _buildAboutAndLegalCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryAccent, size: 18),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.primaryAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        return Card(
          color: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.surfaceElevated),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.surfaceElevated,
                      backgroundImage:
                          user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                      child: user?.photoUrl == null
                          ? const Icon(Icons.person, color: AppTheme.textMuted, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user != null ? user.displayName : 'Guest Session',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user != null
                                ? user.email
                                : 'Sign in to sync watchlist, history & add-ons to cloud',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: state.isAuthenticated
                      ? OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorAccent,
                            side: const BorderSide(color: AppTheme.errorAccent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => context.read<AuthBloc>().add(SignOutEvent()),
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Sign Out of Google'),
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () =>
                              context.read<AuthBloc>().add(SignInWithGoogleEvent()),
                          icon: const Icon(Icons.login, size: 18),
                          label: const Text('Sign In with Google'),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDebridCard() {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.surfaceElevated),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-Debrid Account',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Unrestricts P2P torrents into high-speed HTTPS direct stream links with instant zero-buffering playback.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (_isLoadingDebrid)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: AppTheme.primaryAccent),
                ),
              )
            else if (_debridAccount != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _debridAccount!.isPremium
                        ? AppTheme.successAccent.withAlpha((0.3 * 255).round())
                        : AppTheme.warningAccent.withAlpha((0.3 * 255).round()),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Username', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        Text(
                          _debridAccount!.username,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subscription', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _debridAccount!.isPremium
                                ? AppTheme.successAccent.withAlpha((0.2 * 255).round())
                                : AppTheme.warningAccent.withAlpha((0.2 * 255).round()),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _debridAccount!.isPremium
                                ? 'PREMIUM (${_debridAccount!.premiumDaysLeft}d left)'
                                : 'FREE ACCOUNT',
                            style: TextStyle(
                              color: _debridAccount!.isPremium
                                  ? AppTheme.successAccent
                                  : AppTheme.warningAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorAccent,
                    side: const BorderSide(color: AppTheme.errorAccent),
                  ),
                  onPressed: () async {
                    await _debridRepo.removeToken();
                    setState(() => _debridAccount = null);
                  },
                  icon: const Icon(Icons.link_off, size: 16),
                  label: const Text('Disconnect Real-Debrid'),
                ),
              ),
            ] else ...[
              TextField(
                controller: _rdKeyController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  hintText: 'Paste API Token from real-debrid.com/apitoken',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppTheme.primaryAccent, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _saveDebridKey,
                  icon: const Icon(Icons.add_link, size: 18),
                  label: const Text('Connect Real-Debrid'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerPreferencesCard() {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.surfaceElevated),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Hardware Acceleration Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppTheme.primaryAccent,
              title: const Text(
                'Hardware Acceleration',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Enable GPU decoding via MediaKit libmpv for fluid 4K HDR playback',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              value: _hardwareAcceleration,
              onChanged: (val) {
                setState(() => _hardwareAcceleration = val);
                _savePreferenceBool('pref_hardware_acceleration', val);
              },
            ),
            const Divider(color: AppTheme.surfaceElevated, height: 1),

            // Default Audio Language
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Default Audio Language',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Preferred soundtrack stream during playback initiation',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              trailing: DropdownButton<String>(
                value: _defaultAudioLanguage,
                dropdownColor: AppTheme.surfaceElevated,
                underline: const SizedBox.shrink(),
                style: const TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold),
                items: _languageOptions.map((lang) {
                  return DropdownMenuItem<String>(
                    value: lang['code'],
                    child: Text(lang['name']!),
                  );
                }).toList(),
                onChanged: (newVal) {
                  if (newVal != null) {
                    setState(() => _defaultAudioLanguage = newVal);
                    _savePreferenceString('pref_default_audio_lang', newVal);
                  }
                },
              ),
            ),
            const Divider(color: AppTheme.surfaceElevated, height: 1),

            // Default Subtitle Language
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Default Subtitle Language',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Auto-selected subtitle track when available',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              trailing: DropdownButton<String>(
                value: _defaultSubtitleLanguage,
                dropdownColor: AppTheme.surfaceElevated,
                underline: const SizedBox.shrink(),
                style: const TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold),
                items: _languageOptions.map((lang) {
                  return DropdownMenuItem<String>(
                    value: lang['code'],
                    child: Text(lang['name']!),
                  );
                }).toList(),
                onChanged: (newVal) {
                  if (newVal != null) {
                    setState(() => _defaultSubtitleLanguage = newVal);
                    _savePreferenceString('pref_default_sub_lang', newVal);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutAndLegalCard() {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.surfaceElevated),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.movie_filter_rounded, color: AppTheme.primaryAccent, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aura Media Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Version 1.0.0 (Release Build)',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Aura is a modern, modular, cross-platform media center client built with Flutter, MediaKit (libmpv), and the Stremio v3 protocol specification.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 14),
            const Divider(color: AppTheme.surfaceElevated, height: 1),
            const SizedBox(height: 12),

            // TMDB Attribution Banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.video_library_rounded, color: Color(0xFF01D277), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Legal links
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _showTextModal(
                      context,
                      'MIT License',
                      'Copyright (c) 2026 Hamas Younis\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software.',
                    );
                  },
                  icon: const Icon(Icons.gavel_rounded, size: 14, color: AppTheme.primaryAccent),
                  label: const Text('License', style: TextStyle(color: AppTheme.primaryAccent, fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showTextModal(
                      context,
                      'Legal Disclaimer',
                      'Aura is a metadata aggregator, media player, and add-on host client. It does not host, upload, archive, or distribute any video or media content itself. All streaming catalogs and links are resolved dynamically through third-party user-installed add-on manifests.',
                    );
                  },
                  icon: const Icon(Icons.shield_outlined, size: 14, color: AppTheme.primaryAccent),
                  label: const Text('Disclaimer', style: TextStyle(color: AppTheme.primaryAccent, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTextModal(BuildContext context, String title, String content) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
