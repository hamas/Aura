import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

import '../../../debrid/data/repositories/debrid_repository_impl.dart';
import '../../../debrid/domain/entities/debrid_account.dart';
import '../widgets/components/settings_account_card.dart';
import '../widgets/components/settings_debrid_card.dart';
import '../widgets/components/settings_player_preferences_card.dart';

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
  bool _ambientAuraGlow = true;
  bool _autoSkipIntros = false;
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
      _hardwareAcceleration =
          prefs.getBool('pref_hardware_acceleration') ?? true;
      _ambientAuraGlow = prefs.getBool('pref_ambient_aura_glow') ?? true;
      _autoSkipIntros = prefs.getBool('pref_auto_skip_intros') ?? false;
      _defaultAudioLanguage =
          prefs.getString('pref_default_audio_lang') ?? 'eng';
      _defaultSubtitleLanguage =
          prefs.getString('pref_default_sub_lang') ?? 'eng';
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
            backgroundColor: AppColors.statusSuccess,
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
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 4;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(
              AppTokens.spacingMd,
              topPadding + AppTokens.spacingLg,
              AppTokens.spacingMd,
              AppTokens.spacingLg + 100,
            ),
            children: [
              // 1. Account Section
              _buildSectionHeader('Account & Cloud Continuity', AppIcons.cloudSync),
              const SizedBox(height: 10),
              const SettingsAccountCard(),
              const SizedBox(height: AppTokens.spacingLg),

              // 2. Streaming & Debrid Engine Section
              _buildSectionHeader('Debrid Engine & Multi-hoster', AppIcons.bolt),
              const SizedBox(height: 10),
              SettingsDebridCard(
                isLoadingDebrid: _isLoadingDebrid,
                debridAccount: _debridAccount,
                rdKeyController: _rdKeyController,
                onSaveDebridKey: _saveDebridKey,
                onDisconnectDebrid: () async {
                  await _debridRepo.removeToken();
                  setState(() => _debridAccount = null);
                },
              ),
              const SizedBox(height: AppTokens.spacingLg),

              // 3. Player Preferences Section
              _buildSectionHeader('Player Preferences', AppIcons.tune),
              const SizedBox(height: 10),
              SettingsPlayerPreferencesCard(
                hardwareAcceleration: _hardwareAcceleration,
                onHardwareAccelerationChanged: (val) {
                  setState(() => _hardwareAcceleration = val);
                  _savePreferenceBool('pref_hardware_acceleration', val);
                },
                ambientAuraGlow: _ambientAuraGlow,
                onAmbientAuraGlowChanged: (val) {
                  setState(() => _ambientAuraGlow = val);
                  _savePreferenceBool('pref_ambient_aura_glow', val);
                },
                autoSkipIntros: _autoSkipIntros,
                onAutoSkipIntrosChanged: (val) {
                  setState(() => _autoSkipIntros = val);
                  _savePreferenceBool('pref_auto_skip_intros', val);
                },
                defaultAudioLanguage: _defaultAudioLanguage,
                onDefaultAudioLanguageChanged: (newVal) {
                  if (newVal != null) {
                    setState(() => _defaultAudioLanguage = newVal);
                    _savePreferenceString('pref_default_audio_lang', newVal);
                  }
                },
                defaultSubtitleLanguage: _defaultSubtitleLanguage,
                onDefaultSubtitleLanguageChanged: (newVal) {
                  if (newVal != null) {
                    setState(() => _defaultSubtitleLanguage = newVal);
                    _savePreferenceString('pref_default_sub_lang', newVal);
                  }
                },
                languageOptions: _languageOptions,
              ),
              const SizedBox(height: AppTokens.spacingLg),

              // 4. About & Legal Section
              _buildSectionHeader('About & Legal', AppIcons.infoOutline),
              const SizedBox(height: 10),
              const SettingsAboutAndLegalCard(),
              const SizedBox(height: 40),
            ],
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuraAdaptiveAppBar(
              title: 'Settings & Preferences',
              opacity: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        AuraIcon(icon, color: AppColors.accentPink, size: 18),
        const SizedBox(width: AppTokens.spacingSm),
        Text(
          title.toUpperCase(),
          style: context.auraText.caption.copyWith(
            color: AppColors.accentPink,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
