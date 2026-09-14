import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../addons/domain/entities/addon_stream.dart';

class StreamPickerModal extends StatelessWidget {
  final List<AddonStream> streams;
  final bool isLoading;
  final ValueChanged<AddonStream> onStreamSelected;

  const StreamPickerModal({
    super.key,
    required this.streams,
    this.isLoading = false,
    required this.onStreamSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withAlpha((0.4 * 255).round()),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.stream, color: AppTheme.primaryAccent, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Available Streams',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isLoading && streams.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No streams found. Ensure active Stremio add-ons are installed.',
                  style: TextStyle(color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: streams.length,
                separatorBuilder: (_, __) => const Divider(color: Color(0xFF1F293D)),
                itemBuilder: (context, index) {
                  final stream = streams[index];
                  final isTorrent = stream.isTorrent;

                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      onStreamSelected(stream);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: stream.resolution == '4K UHD'
                                  ? AppTheme.warningAccent.withAlpha((0.2 * 255).round())
                                  : AppTheme.primaryAccent.withAlpha((0.2 * 255).round()),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: stream.resolution == '4K UHD'
                                    ? AppTheme.warningAccent
                                    : AppTheme.primaryAccent,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              stream.resolution,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: stream.resolution == '4K UHD'
                                    ? AppTheme.warningAccent
                                    : AppTheme.primaryAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stream.title ?? stream.name ?? 'Stream ${index + 1}',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (stream.addonName != null)
                                      Text(
                                        stream.addonName!,
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (isTorrent) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.bolt, size: 14, color: AppTheme.warningAccent),
                                      const Text(
                                        'P2P / Torrent',
                                        style: TextStyle(
                                          color: AppTheme.warningAccent,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.play_circle_outline, color: AppTheme.primaryAccent),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
