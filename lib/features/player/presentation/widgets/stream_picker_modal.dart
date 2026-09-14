import 'dart:ui';
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

  String? _extractFileSize(String text) {
    final match = RegExp(
      r'(\d+(?:\.\d+)?\s*(?:GB|GiB|MB|MiB))',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(1);
  }

  List<String> _extractAudioAndCodecs(String text) {
    final tags = <String>[];
    final upper = text.toUpperCase();

    if (upper.contains('DV') || upper.contains('DOVI') || upper.contains('DOLBY VISION')) {
      tags.add('DV');
    }
    if (upper.contains('HDR10+') || upper.contains('HDR10') || upper.contains('HDR')) {
      tags.add('HDR');
    }
    if (upper.contains('ATMOS')) {
      tags.add('Atmos');
    } else if (upper.contains('DTS-HD') || upper.contains('DTS')) {
      tags.add('DTS');
    } else if (upper.contains('DDP5.1') || upper.contains('DD5.1') || upper.contains('5.1')) {
      tags.add('5.1 Audio');
    }
    if (upper.contains('HEVC') || upper.contains('H.265') || upper.contains('X265')) {
      tags.add('HEVC');
    } else if (upper.contains('AV1')) {
      tags.add('AV1');
    } else if (upper.contains('H.264') || upper.contains('X264')) {
      tags.add('AVC');
    }

    return tags;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: const Color(0xEB0E1320),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withAlpha((0.08 * 255).round()),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withAlpha((0.4 * 255).round()),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withAlpha((0.15 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: AppTheme.primaryAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Stream Source',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Aggregated from active Stremio v3 add-ons',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Content Area
              if (!isLoading && streams.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard.withAlpha((0.5 * 255).round()),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E2638)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 40, color: AppTheme.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'No streams found for this media',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ensure you have configured active Stremio add-ons in the Add-ons tab.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: streams.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final stream = streams[index];
                      final isTorrent = stream.isTorrent;
                      final rawTitle = stream.title ?? stream.name ?? 'Stream ${index + 1}';
                      final fileSize = _extractFileSize(rawTitle);
                      final audioAndCodecs = _extractAudioAndCodecs(rawTitle);
                      final is4K = stream.resolution == '4K UHD';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            onStreamSelected(stream);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCard.withAlpha((0.85 * 255).round()),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: is4K
                                    ? AppTheme.warningAccent.withAlpha((0.35 * 255).round())
                                    : const Color(0xFF222B3F),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Quality Badge
                                Container(
                                  width: 64,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: is4K
                                          ? [
                                              const Color(0xFFE5A00D).withAlpha((0.25 * 255).round()),
                                              const Color(0xFFE5A00D).withAlpha((0.08 * 255).round()),
                                            ]
                                          : [
                                              AppTheme.primaryAccent.withAlpha((0.25 * 255).round()),
                                              AppTheme.primaryAccent.withAlpha((0.08 * 255).round()),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: is4K ? AppTheme.warningAccent : AppTheme.primaryAccent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        stream.resolution,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: is4K
                                              ? AppTheme.warningAccent
                                              : AppTheme.primaryAccent,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Stream Details Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rawTitle,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          height: 1.25,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),

                                      // Tags Row (Provider, Size, Audio, Torrent/Direct)
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          if (stream.addonName != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1B2335),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                stream.addonName!,
                                                style: const TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          if (fileSize != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF162A24),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: AppTheme.successAccent.withAlpha((0.3 * 255).round()),
                                                ),
                                              ),
                                              child: Text(
                                                fileSize,
                                                style: const TextStyle(
                                                  color: AppTheme.successAccent,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          for (final tag in audioAndCodecs)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 1.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1E283E),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                tag,
                                                style: const TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          if (isTorrent)
                                            const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.bolt,
                                                  size: 13,
                                                  color: AppTheme.warningAccent,
                                                ),
                                                Text(
                                                  'P2P',
                                                  style: TextStyle(
                                                    color: AppTheme.warningAccent,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: AppTheme.primaryAccent,
                                  size: 26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
