import 'package:flutter/material.dart';
import '../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/user_profile.dart';
import '../../data/services/profile_manager.dart';

class EditProfileSubPage extends StatefulWidget {
  final UserProfile? initialProfile;
  final ProfileManager profileManager;
  final VoidCallback onSaved;
  final VoidCallback onBack;

  const EditProfileSubPage({
    super.key,
    this.initialProfile,
    required this.profileManager,
    required this.onSaved,
    required this.onBack,
  });

  @override
  State<EditProfileSubPage> createState() => _EditProfileSubPageState();
}

class _EditProfileSubPageState extends State<EditProfileSubPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _pinController;

  late String _selectedPaletteId;
  late bool _isKids;
  late bool _hasPin;
  late String _displayLanguage;
  late String _audioLanguage;
  late String _subtitleLanguage;
  late String _subtitleSize;
  late bool _autoPlayNext;
  late bool _autoPlayPreviews;
  String? _errorMessage;

  bool get _isEditing => widget.initialProfile != null;
  bool get _canDelete => _isEditing && widget.profileManager.getProfiles().length > 1;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameController = TextEditingController(text: p?.name ?? '');
    _pinController = TextEditingController();
    _selectedPaletteId = p?.avatarPaletteId ?? 'electric_violet';
    _isKids = p?.isKids ?? false;
    _hasPin = p?.hasPin ?? false;
    _displayLanguage = p?.displayLanguage ?? 'English';
    _audioLanguage = p?.audioLanguage ?? 'English';
    _subtitleLanguage = p?.subtitleLanguage ?? 'English';
    _subtitleSize = p?.subtitleSize ?? '100%';
    _autoPlayNext = p?.autoPlayNext ?? true;
    _autoPlayPreviews = p?.autoPlayPreviews ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profiles = widget.profileManager.getProfiles();
    if (!_isEditing && profiles.length >= ProfileManager.maxProfiles) {
      setState(() => _errorMessage = 'Maximum limit of ${ProfileManager.maxProfiles} profiles reached.');
      return;
    }

    final trimmedName = _nameController.text.trim();
    String? pinHash = widget.initialProfile?.pinHash;

    if (_hasPin) {
      if (_pinController.text.isNotEmpty) {
        if (_pinController.text.length != 4) {
          setState(() => _errorMessage = 'PIN must be exactly 4 digits.');
          return;
        }
        pinHash = UserProfile.hashPin(_pinController.text);
      }
    } else {
      pinHash = null;
    }

    final profile = UserProfile(
      id: widget.initialProfile?.id ?? 'profile_${DateTime.now().millisecondsSinceEpoch}',
      name: trimmedName,
      avatarPaletteId: _selectedPaletteId,
      isPrimary: false,
      isKids: _isKids,
      pinHash: pinHash,
      displayLanguage: _displayLanguage,
      audioLanguage: _audioLanguage,
      subtitleLanguage: _subtitleLanguage,
      subtitleSize: _subtitleSize,
      autoPlayNext: _autoPlayNext,
      autoPlayPreviews: _autoPlayPreviews,
      createdAt: widget.initialProfile?.createdAt ?? DateTime.now(),
    );

    final success = await widget.profileManager.saveProfile(profile);
    if (success) {
      widget.onSaved();
      widget.onBack();
    } else {
      setState(() => _errorMessage = 'Failed to save profile.');
    }
  }

  Future<void> _deleteProfile() async {
    if (!_canDelete) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Delete Profile', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${widget.initialProfile!.name}"? Watch history and watchlist for this profile will be permanently removed.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusError),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.initialProfile != null) {
      await widget.profileManager.deleteProfile(widget.initialProfile!.id);
      widget.onSaved();
      widget.onBack();
    }
  }

  List<Color> _getPaletteColors(String paletteId) {
    final matches = ProfileAvatarPalette.curatedPalettes.where(
      (p) => p['id'] == paletteId,
    );
    if (matches.isNotEmpty) {
      final colors = (matches.first['colors'] as List).cast<int>();
      return colors.map((c) => Color(c)).toList();
    }
    return [const Color(0xFF8A2BE2), const Color(0xFF4A00E0)];
  }

  @override
  Widget build(BuildContext context) {
    final avatarColors = _getPaletteColors(_selectedPaletteId);

    return Material(
      color: Colors.transparent,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.statusError.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.statusError.withValues(alpha: 0.4)),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.statusError, fontSize: 13)),
              ),
            ],

            // Avatar & Name Card Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: avatarColors,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: avatarColors.first.withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _nameController.text.trim().isNotEmpty
                              ? UserProfile(
                                  id: 'temp',
                                  name: _nameController.text.trim(),
                                  createdAt: DateTime.now(),
                                ).initials
                              : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const AuraIcon(AppIcons.edit, color: Colors.black, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Name TextField matching design
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: TextFormField(
                      controller: _nameController,
                      maxLength: 20,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        hintText: 'Enter profile name',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Color Palette Selector
            Text('Avatar Color Palette', style: context.auraText.caption.copyWith(color: Colors.white70)),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ProfileAvatarPalette.curatedPalettes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final item = ProfileAvatarPalette.curatedPalettes[i];
                  final paletteId = item['id'] as String;
                  final colors = (item['colors'] as List).cast<int>().map((c) => Color(c)).toList();
                  final isSelected = paletteId == _selectedPaletteId;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedPaletteId = paletteId),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: colors),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: isSelected
                          ? const Center(child: AuraIcon(AppIcons.check, color: Colors.white, size: 18))
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Settings Options List matching Netflix layout style
            Column(
              children: [
                // Viewing Restrictions
                _buildPreferenceTile(
                  icon: AppIcons.shield,
                  title: 'Viewing Restrictions',
                  subtitle: _isKids ? 'Kids Profile (Strict G, PG, TV-14 filter)' : 'No restrictions (All Content)',
                  trailing: Switch(
                    value: _isKids,
                    activeTrackColor: Colors.white,
                    activeThumbColor: Colors.black,
                    onChanged: (val) => setState(() => _isKids = val),
                  ),
                ),
                const SizedBox(height: 10),

                // Profile Lock
                _buildPreferenceTile(
                  icon: AppIcons.lock,
                  title: 'Profile Lock (4-Digit PIN)',
                  subtitle: _hasPin ? 'PIN Lock Enabled' : 'Off',
                  trailing: Switch(
                    value: _hasPin,
                    activeTrackColor: Colors.white,
                    activeThumbColor: Colors.black,
                    onChanged: (val) => setState(() => _hasPin = val),
                  ),
                ),
                if (_hasPin) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      hintText: _isEditing && (widget.initialProfile?.hasPin ?? false)
                          ? 'Leave blank to keep existing PIN'
                          : 'Enter 4-digit numeric PIN',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      counterStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // Display Language
                _buildPreferenceTile(
                  icon: AppIcons.language,
                  title: 'Display Language',
                  subtitle: _displayLanguage,
                  trailing: DropdownButton<String>(
                    value: _displayLanguage,
                    dropdownColor: const Color(0xFF1F1F1F),
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: ['English', 'Spanish', 'French', 'German'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _displayLanguage = val);
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Audio & Subtitle Languages
                _buildPreferenceTile(
                  icon: AppIcons.audiotrack,
                  title: 'Audio Language',
                  subtitle: _audioLanguage,
                  trailing: DropdownButton<String>(
                    value: _audioLanguage,
                    dropdownColor: const Color(0xFF1F1F1F),
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: ['English', 'Spanish', 'French', 'German', 'Original'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _audioLanguage = val);
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle Appearance & Language
                _buildPreferenceTile(
                  icon: AppIcons.subtitles,
                  title: 'Subtitle Language & Size',
                  subtitle: '$_subtitleLanguage ($_subtitleSize)',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<String>(
                        value: _subtitleLanguage,
                        dropdownColor: const Color(0xFF1F1F1F),
                        underline: const SizedBox.shrink(),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: ['English', 'Spanish', 'French', 'German'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _subtitleLanguage = val);
                        },
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _subtitleSize,
                        dropdownColor: const Color(0xFF1F1F1F),
                        underline: const SizedBox.shrink(),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: ['75%', '100%', '125%', '150%'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _subtitleSize = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Autoplay Next Episode
                _buildPreferenceTile(
                  icon: AppIcons.playCircle,
                  title: 'Autoplay Next Episode',
                  subtitle: 'On all devices for this profile',
                  trailing: Switch(
                    value: _autoPlayNext,
                    activeTrackColor: Colors.white,
                    activeThumbColor: Colors.black,
                    onChanged: (val) => setState(() => _autoPlayNext = val),
                  ),
                ),
                const SizedBox(height: 10),

                // Autoplay Previews
                _buildPreferenceTile(
                  icon: AppIcons.history,
                  title: 'Autoplay Previews',
                  subtitle: 'Autoplay trailer previews while browsing',
                  trailing: Switch(
                    value: _autoPlayPreviews,
                    activeTrackColor: Colors.white,
                    activeThumbColor: Colors.black,
                    onChanged: (val) => setState(() => _autoPlayPreviews = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                if (_canDelete)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusError,
                        side: const BorderSide(color: AppColors.statusError),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _deleteProfile,
                      child: const Text('Delete Profile'),
                    ),
                  ),
                if (_canDelete) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _saveProfile,
                    child: Text(
                      _isEditing ? 'Save Changes' : 'Create Profile',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: AuraIcon(icon, color: Colors.white, size: 18),
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
          trailing,
        ],
      ),
    );
  }
}
