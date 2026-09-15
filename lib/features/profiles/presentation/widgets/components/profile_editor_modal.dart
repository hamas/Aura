import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../data/services/profile_manager.dart';

class ProfileEditorModal extends StatefulWidget {
  final UserProfile? initialProfile;
  final ProfileManager profileManager;
  final VoidCallback onSaved;

  const ProfileEditorModal({
    super.key,
    this.initialProfile,
    required this.profileManager,
    required this.onSaved,
  });

  @override
  State<ProfileEditorModal> createState() => _ProfileEditorModalState();
}

class _ProfileEditorModalState extends State<ProfileEditorModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _pinController;

  late String _selectedPaletteId;
  late bool _isKids;
  late bool _hasPin;
  String? _errorMessage;

  bool get _isEditing => widget.initialProfile != null;
  bool get _isPrimary => widget.initialProfile?.isPrimary ?? false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile?.name ?? '');
    _pinController = TextEditingController();
    _selectedPaletteId = widget.initialProfile?.avatarPaletteId ?? 'electric_violet';
    _isKids = widget.initialProfile?.isKids ?? false;
    _hasPin = widget.initialProfile?.hasPin ?? false;
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
      isPrimary: _isPrimary,
      isKids: _isPrimary ? false : _isKids, // Primary owner cannot be kids mode
      pinHash: pinHash,
      createdAt: widget.initialProfile?.createdAt ?? DateTime.now(),
    );

    final success = await widget.profileManager.saveProfile(profile);
    if (success) {
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _errorMessage = 'Failed to save profile.');
    }
  }

  Future<void> _deleteProfile() async {
    if (_isPrimary) return;

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
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Profile' : 'Add Profile',
                    style: context.auraText.sectionTitle.copyWith(color: Colors.white, fontSize: 18),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const AuraIcon(AppIcons.close, color: Colors.white54, size: 20),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.statusError, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),

              // 1. Profile Name Input Field
              Text('Profile Name', style: context.auraText.caption.copyWith(color: Colors.white70)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                maxLength: 20,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  hintText: 'Enter profile name',
                  hintStyle: const TextStyle(color: Colors.white38),
                  counterStyle: const TextStyle(color: Colors.white38),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a valid profile name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. Avatar Palette Swatches Picker
              Text('Avatar Accent Palette', style: context.auraText.caption.copyWith(color: Colors.white70)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ProfileAvatarPalette.curatedPalettes.map((palette) {
                    final id = palette['id'] as String;
                    final isSelected = id == _selectedPaletteId;
                    final colors = (palette['colors'] as List).cast<int>().map((c) => Color(c)).toList();

                    return GestureDetector(
                      onTap: () => setState(() => _selectedPaletteId = id),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: colors,
                          ),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Kid Profile Switch (Disabled for Primary Account Owner)
              if (!_isPrimary) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: Colors.black,
                  activeTrackColor: Colors.white,
                  title: const Text('Kid Profile', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text(
                    'Strictly filter titles to G, PG, TV-Y, TV-G, TV-Y7, and TV-14 ratings',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: _isKids,
                  onChanged: (val) => setState(() => _isKids = val),
                ),
                const Divider(color: Color(0x1AFFFFFF), height: 20),
              ],

              // 4. PIN Security Lock Toggle & Entry Field
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: Colors.black,
                activeTrackColor: Colors.white,
                title: const Text('Require Profile PIN', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text(
                  'Require 4-digit PIN before switching into this profile',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                value: _hasPin,
                onChanged: (val) => setState(() => _hasPin = val),
              ),
              if (_hasPin) ...[
                const SizedBox(height: 10),
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
              const SizedBox(height: 24),

              // Action Buttons: Save & Delete
              Row(
                children: [
                  if (_isEditing && !_isPrimary)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.statusError,
                          side: const BorderSide(color: AppColors.statusError),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                        onPressed: _deleteProfile,
                        child: const Text('Delete Profile'),
                      ),
                    ),
                  if (_isEditing && !_isPrimary) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      onPressed: _saveProfile,
                      child: Text(_isEditing ? 'Save Changes' : 'Create Profile', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
