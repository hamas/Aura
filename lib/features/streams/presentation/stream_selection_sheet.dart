import 'package:aura/core/presentation/primitives/aura_badge.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_tokens.dart';
import 'package:aura/core/theme/app_typography.dart';
import 'package:aura/features/streams/domain/entities/scraped_stream_item.dart';
import 'package:flutter/material.dart';

class StreamSelectionSheet extends StatelessWidget {
  final List<ScrapedStreamItem> streams;
  final ScrapedStreamItem? selectedStream;
  final ValueChanged<ScrapedStreamItem> onStreamSelected;
  final bool isLoading;

  const StreamSelectionSheet({
    super.key,
    required this.streams,
    this.selectedStream,
    required this.onStreamSelected,
    this.isLoading = false,
  });

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
                'Available Streams',
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
          const SizedBox(height: 8),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: AppColors.accentPink),
              ),
            )
          else if (streams.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No streams found for this media.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: streams.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white12, height: 1),
                itemBuilder: (context, index) {
                  final stream = streams[index];
                  final isSelected = selectedStream?.id == stream.id;

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    onTap: () => onStreamSelected(stream),
                    title: Text(
                      stream.title,
                      style: context.auraText.bodyOverview.copyWith(
                        color: isSelected ? AppColors.accentPink : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          AuraBadge(
                            label: stream.resolution,
                            backgroundColor:
                                AppColors.accentPink.withValues(alpha: 0.2),
                            textColor: AppColors.accentPink,
                          ),
                          if (stream.isHdr)
                            const AuraBadge(
                              label: 'HDR',
                              backgroundColor: Color(0x33FF9800),
                              textColor: Colors.orange,
                            ),
                          if (stream.isDolbyVision)
                            const AuraBadge(
                              label: 'DV',
                              backgroundColor: Color(0x339C27B0),
                              textColor: Colors.purpleAccent,
                            ),
                          if (stream.isRemux)
                            const AuraBadge(
                              label: 'REMUX',
                              backgroundColor: Color(0x332196F3),
                              textColor: Colors.blueAccent,
                            ),
                          if (stream.sizeGb > 0)
                            AuraBadge(
                              label: '${stream.sizeGb.toStringAsFixed(1)} GB',
                              backgroundColor: AppColors.surfaceElevated,
                            ),
                          if (stream.isCached)
                            const AuraBadge(
                              label: 'RD+',
                              backgroundColor: Color(0x334CAF50),
                              textColor: Colors.greenAccent,
                            ),
                        ],
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: AppColors.accentPink)
                        : const Icon(Icons.play_arrow_rounded,
                            color: AppColors.textMuted),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
