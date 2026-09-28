import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/subtitle_style_config.dart';

/// Interactive modal sheet to customize subtitle appearance with live preview.
class SubtitleStylingModal extends StatefulWidget {
  final SubtitleStyleConfig initialConfig;
  final ValueChanged<SubtitleStyleConfig> onConfigChanged;

  const SubtitleStylingModal({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
  });

  static Future<SubtitleStyleConfig?> show({
    required BuildContext context,
    required SubtitleStyleConfig initialConfig,
    required ValueChanged<SubtitleStyleConfig> onConfigChanged,
  }) {
    return showModalBottomSheet<SubtitleStyleConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SubtitleStylingModal(
        initialConfig: initialConfig,
        onConfigChanged: onConfigChanged,
      ),
    );
  }

  @override
  State<SubtitleStylingModal> createState() => _SubtitleStylingModalState();
}

class _SubtitleStylingModalState extends State<SubtitleStylingModal> {
  late SubtitleStyleConfig _config;

  final List<Color> _availableColors = const [
    Colors.white,
    Color(0xFFFFEB3B), // Netflix Yellow
    Color(0xFF80D8FF), // Cyan
    Color(0xFFB9F6CA), // Mint
    Color(0xFFFF8A80), // Coral
  ];

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  void _updateConfig(SubtitleStyleConfig newConfig) {
    setState(() => _config = newConfig);
    widget.onConfigChanged(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16171B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtitle Appearance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(_config),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Live Preview Surface
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accentPink.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  image: const DecorationImage(
                    image: AssetImage('assets/branding/app_icon.png'),
                    opacity: 0.05,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'PREVIEW',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _config.effectiveBackgroundColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: _config.hasTextShadow
                            ? [
                                const BoxShadow(
                                  color: Colors.black87,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'This is how your subtitles will look.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _config.textColor,
                          fontSize: _config.fontSize,
                          fontWeight: _config.isBold ? FontWeight.bold : FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Presets
              const Text(
                'PRESETS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPresetButton(
                    label: 'Netflix White',
                    config: SubtitleStyleConfig.netflixWhite,
                  ),
                  const SizedBox(width: 8),
                  _buildPresetButton(
                    label: 'Yellow Sub',
                    config: SubtitleStyleConfig.netflixYellow,
                  ),
                  const SizedBox(width: 8),
                  _buildPresetButton(
                    label: 'Clean Outline',
                    config: SubtitleStyleConfig.cleanOutline,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Font Size Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Font Size',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${_config.fontSize.toInt()}sp',
                    style: const TextStyle(color: AppColors.accentPink, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: _config.fontSize,
                min: 12.0,
                max: 32.0,
                divisions: 10,
                activeColor: AppColors.accentPink,
                inactiveColor: Colors.white12,
                onChanged: (val) {
                  _updateConfig(_config.copyWith(fontSize: val));
                },
              ),
              const SizedBox(height: 12),

              // Text Color Picker
              const Text(
                'Text Color',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: _availableColors.map((col) {
                  final isSelected = _config.textColor == col;
                  return GestureDetector(
                    onTap: () => _updateConfig(_config.copyWith(textColor: col)),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.accentPink : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.accentPink.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(Icons.check, size: 18, color: col == Colors.white ? Colors.black : Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Background Opacity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Background Box Opacity',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${(_config.backgroundOpacity * 100).toInt()}%',
                    style: const TextStyle(color: AppColors.accentPink, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: _config.backgroundOpacity,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                activeColor: AppColors.accentPink,
                inactiveColor: Colors.white12,
                onChanged: (val) {
                  _updateConfig(_config.copyWith(backgroundOpacity: val));
                },
              ),
              const SizedBox(height: 12),

              // Bold text & Shadow Toggles
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.accentPink,
                title: const Text('Bold Text', style: TextStyle(color: Colors.white, fontSize: 14)),
                value: _config.isBold,
                onChanged: (val) => _updateConfig(_config.copyWith(isBold: val)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.accentPink,
                title: const Text('Drop Shadow', style: TextStyle(color: Colors.white, fontSize: 14)),
                value: _config.hasTextShadow,
                onChanged: (val) => _updateConfig(_config.copyWith(hasTextShadow: val)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton({
    required String label,
    required SubtitleStyleConfig config,
  }) {
    final isSelected = _config.fontSize == config.fontSize &&
        _config.textColor == config.textColor &&
        _config.backgroundOpacity == config.backgroundOpacity;

    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.accentPink.withValues(alpha: 0.15) : Colors.transparent,
          side: BorderSide(
            color: isSelected ? AppColors.accentPink : Colors.white24,
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => _updateConfig(config),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accentPink : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
