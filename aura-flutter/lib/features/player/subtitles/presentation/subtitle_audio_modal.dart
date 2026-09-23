import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_tokens.dart';
import 'package:aura/core/theme/app_typography.dart';
import 'package:aura/features/player/subtitles/domain/entities/subtitle_track_info.dart';
import 'package:flutter/material.dart';

class SubtitleAudioModal extends StatefulWidget {
  final List<SubtitleTrackInfo> subtitleTracks;
  final List<AudioTrackInfo> audioTracks;
  final SubtitleTrackInfo? selectedSubtitle;
  final AudioTrackInfo? selectedAudio;
  final double currentOffsetSeconds;
  final SubtitleFontSize fontSize;
  final SubtitleEdgeStyle edgeStyle;
  final ValueChanged<SubtitleTrackInfo?> onSubtitleSelected;
  final ValueChanged<AudioTrackInfo> onAudioSelected;
  final ValueChanged<double> onOffsetChanged;
  final ValueChanged<SubtitleFontSize> onFontSizeChanged;
  final ValueChanged<SubtitleEdgeStyle> onEdgeStyleChanged;

  const SubtitleAudioModal({
    super.key,
    required this.subtitleTracks,
    required this.audioTracks,
    this.selectedSubtitle,
    this.selectedAudio,
    this.currentOffsetSeconds = 0.0,
    this.fontSize = SubtitleFontSize.medium,
    this.edgeStyle = SubtitleEdgeStyle.solidBox,
    required this.onSubtitleSelected,
    required this.onAudioSelected,
    required this.onOffsetChanged,
    required this.onFontSizeChanged,
    required this.onEdgeStyleChanged,
  });

  @override
  State<SubtitleAudioModal> createState() => _SubtitleAudioModalState();
}

class _SubtitleAudioModalState extends State<SubtitleAudioModal> {
  late double _offset;
  late SubtitleFontSize _fontSize;
  late SubtitleEdgeStyle _edgeStyle;

  @override
  void initState() {
    super.initState();
    _offset = widget.currentOffsetSeconds;
    _fontSize = widget.fontSize;
    _edgeStyle = widget.edgeStyle;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Audio & Subtitles',
                style: context.auraText.sectionTitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subtitle Offset Sync Slider (-5.0s to +5.0s in 250ms steps)
          Text(
            'Subtitle Sync Offset (${_offset >= 0 ? "+" : ""}${_offset.toStringAsFixed(2)}s)',
            style: context.auraText.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          SliderTheme(
            data: const SliderThemeData(
              activeTrackColor: AppColors.accentPink,
              inactiveTrackColor: Colors.white24,
              thumbColor: AppColors.accentPink,
            ),
            child: Slider(
              value: _offset.clamp(-5.0, 5.0),
              min: -5.0,
              max: 5.0,
              divisions: 40,
              onChanged: (val) {
                setState(() => _offset = val);
                widget.onOffsetChanged(val);
              },
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle Styling (Font Size & Edge Style)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Font Size',
                      style: context.auraText.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<SubtitleFontSize>(
                      value: _fontSize,
                      dropdownColor: AppColors.surfaceCard,
                      style: const TextStyle(color: Colors.white),
                      isExpanded: true,
                      items: SubtitleFontSize.values.map((size) {
                        return DropdownMenuItem(
                          value: size,
                          child: Text(size.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _fontSize = val);
                          widget.onFontSizeChanged(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edge Style',
                      style: context.auraText.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<SubtitleEdgeStyle>(
                      value: _edgeStyle,
                      dropdownColor: AppColors.surfaceCard,
                      style: const TextStyle(color: Colors.white),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: SubtitleEdgeStyle.solidBox,
                          child: Text('Solid Black Box'),
                        ),
                        DropdownMenuItem(
                          value: SubtitleEdgeStyle.dropShadow,
                          child: Text('Drop Shadow'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _edgeStyle = val);
                          widget.onEdgeStyleChanged(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Audio Track Selection
          Text(
            'Audio Track',
            style: context.auraText.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: widget.audioTracks.map((track) {
              final isSelected = widget.selectedAudio?.id == track.id;
              return ChoiceChip(
                label: Text(track.label),
                selected: isSelected,
                selectedColor: AppColors.accentPink,
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => widget.onAudioSelected(track),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Subtitle Track Selection
          Text(
            'Subtitle Track',
            style: context.auraText.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Off'),
                selected: widget.selectedSubtitle == null,
                selectedColor: AppColors.accentPink,
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: TextStyle(
                  color: widget.selectedSubtitle == null
                      ? Colors.black
                      : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => widget.onSubtitleSelected(null),
              ),
              ...widget.subtitleTracks.map((track) {
                final isSelected = widget.selectedSubtitle?.id == track.id;
                return ChoiceChip(
                  label: Text(track.label),
                  selected: isSelected,
                  selectedColor: AppColors.accentPink,
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => widget.onSubtitleSelected(track),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
