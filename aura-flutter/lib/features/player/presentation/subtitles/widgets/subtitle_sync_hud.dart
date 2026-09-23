import 'package:flutter/material.dart';

class SubtitleSyncHud extends StatelessWidget {
  final double currentOffset;
  final ValueChanged<double> onOffsetChanged;
  final ValueChanged<double> onNudgeOffset;
  final VoidCallback onReset;

  const SubtitleSyncHud({
    super.key,
    required this.currentOffset,
    required this.onOffsetChanged,
    required this.onNudgeOffset,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final formattedOffset =
        (currentOffset >= 0 ? '+' : '') + currentOffset.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xCC141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtitle Sync Offset',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${formattedOffset}s',
                style: const TextStyle(
                  color: Color(0xFFE50914),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _NudgeButton(
                label: '-0.5s',
                onPressed: () => onNudgeOffset(-0.5),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFE50914),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: currentOffset.clamp(-10.0, 10.0),
                    min: -10.0,
                    max: 10.0,
                    divisions: 40,
                    onChanged: onOffsetChanged,
                  ),
                ),
              ),
              _NudgeButton(
                label: '+0.5s',
                onPressed: () => onNudgeOffset(0.5),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onReset,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NudgeButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _NudgeButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
