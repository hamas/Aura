import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/primitives/aura_icon.dart';
import '../../../addons/domain/entities/addon_stream.dart';

class StreamPickerModal extends StatefulWidget {
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
  State<StreamPickerModal> createState() => _StreamPickerModalState();
}

class _StreamPickerModalState extends State<StreamPickerModal> {
  int _selectedTabIndex = 0; // 0: Direct Streams (Default), 1: All Streams / P2P

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

    if (upper.contains('DV') ||
        upper.contains('DOVI') ||
        upper.contains('DOLBY VISION')) {
      tags.add('DV');
    }
    if (upper.contains('HDR10+') ||
        upper.contains('HDR10') ||
        upper.contains('HDR')) {
      tags.add('HDR');
    }
    if (upper.contains('ATMOS')) {
      tags.add('Atmos');
    } else if (upper.contains('DTS-HD') || upper.contains('DTS')) {
      tags.add('DTS');
    } else if (upper.contains('DDP5.1') ||
        upper.contains('DD5.1') ||
        upper.contains('5.1')) {
      tags.add('5.1 Audio');
    }
    if (upper.contains('HEVC') ||
        upper.contains('H.265') ||
        upper.contains('X265')) {
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
    final filteredStreams = _selectedTabIndex == 0
        ? widget.streams.where((s) => (s.url ?? '').startsWith('http')).toList()
        : widget.streams;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF191A1E),
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
                    color:
                        AppTheme.primaryAccent.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const AuraIcon(
                    AppIcons.playCircle,
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
                if (widget.isLoading)
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
            const SizedBox(height: 14),

            // Filter Tabs (Direct Streams vs All Streams / P2P)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF111215),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withAlpha((0.05 * 255).round()),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0
                              ? AppTheme.primaryAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '⚡ Direct Streams',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedTabIndex == 0
                                ? Colors.black
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1
                              ? const Color(0xFF262C3A)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          'All Streams / P2P',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedTabIndex == 1
                                ? AppTheme.textPrimary
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Content Area
            if (widget.isLoading && widget.streams.isEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard.withAlpha((0.5 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E2638)),
                ),
                child: const Column(
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryAccent,
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Querying community add-ons...',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Resolving streams via Stremio v3 community protocol',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else if (!widget.isLoading && filteredStreams.isEmpty && _selectedTabIndex == 0 && widget.streams.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard.withAlpha((0.5 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E2638)),
                ),
                child: Column(
                  children: [
                    const AuraIcon(AppIcons.warning,
                        size: 36, color: AppTheme.warningAccent),
                    const SizedBox(height: 10),
                    const Text(
                      'No Direct Streams Found',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Available sources require a BitTorrent engine or Debrid service. Switch to "All Streams / P2P" tab to view them.',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.35),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF262C3A),
                        foregroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      onPressed: () => setState(() => _selectedTabIndex = 1),
                      child: const Text(
                        'View All Streams / P2P',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else if (!widget.isLoading && filteredStreams.isEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard.withAlpha((0.5 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E2638)),
                ),
                child: Column(
                  children: [
                    const AuraIcon(AppIcons.cloudOff,
                        size: 44, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    const Text(
                      'No streams found',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'No active engines returned streams for this title. Install additional Stremio community add-ons from the Add-on Hub.',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.35),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/addons');
                      },
                      icon: const AuraIcon(AppIcons.extension, size: 18),
                      label: const Text(
                        'Configure Add-ons',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filteredStreams.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    // Inject sample instant test stream at top of list
                    if (index == 0) {
                      const sampleStream = AddonStream(
                        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                        name: '⚡ Demo Free HD Stream 1080p',
                        title: '⚡ Demo Free HD Stream (Instant 1-Tap Playback)',
                        addonName: 'Free Community Engine',
                      );

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onStreamSelected(sampleStream);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF143026),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.successAccent.withAlpha((0.5 * 255).round()),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 64,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successAccent.withAlpha((0.2 * 255).round()),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.successAccent),
                                  ),
                                  child: const Text(
                                    '1080p',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.successAccent,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '⚡ Demo Free HD Stream (1080p)',
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '[1-TAP FREE STREAM] • Instant Playback',
                                        style: TextStyle(
                                          color: AppTheme.successAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const AuraIcon(
                                  AppIcons.playCircle,
                                  color: AppTheme.successAccent,
                                  size: 26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final stream = filteredStreams[index - 1];
                    final bool isDirect = (stream.url ?? '').startsWith('http');
                    final bool isP2pTorrent = stream.url == null && (stream.infoHash ?? '').isNotEmpty;
                    final rawTitle =
                        stream.title ?? stream.name ?? 'Stream ${index + 1}';
                    final fileSize = _extractFileSize(rawTitle);
                    final audioAndCodecs = _extractAudioAndCodecs(rawTitle);
                    final is4K = stream.resolution == '4K UHD';

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (isP2pTorrent) {
                            showDialog<void>(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                backgroundColor: const Color(0xFF191A1E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: AppTheme.warningAccent.withValues(alpha: 0.4)),
                                ),
                                title: const Row(
                                  children: [
                                    AuraIcon(AppIcons.warning, color: AppTheme.warningAccent, size: 22),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Direct Stream Gateway Required',
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                content: const Text(
                                  'Aura is a store-compliant media player and does not bundle a BitTorrent engine. To stream this title, configure an HTTPS debrid service (Real-Debrid, TorBox) in your add-on, or pick a direct stream.',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogCtx).pop(),
                                    child: const Text('Understood', style: TextStyle(color: Colors.white54)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      Navigator.of(dialogCtx).pop();
                                      Navigator.of(context).pop();
                                      context.push('/addons');
                                    },
                                    child: const Text('Configure Add-on'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).pop();
                          widget.onStreamSelected(stream);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard
                                .withAlpha((0.85 * 255).round()),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: is4K
                                  ? AppTheme.warningAccent
                                      .withAlpha((0.35 * 255).round())
                                  : const Color(0xFF222B3F),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Quality Badge
                              Container(
                                width: 64,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: is4K
                                        ? [
                                            const Color(0xFFE5A00D).withAlpha(
                                                (0.25 * 255).round()),
                                            const Color(0xFFE5A00D).withAlpha(
                                                (0.08 * 255).round()),
                                          ]
                                        : [
                                            AppTheme.primaryAccent.withAlpha(
                                                (0.25 * 255).round()),
                                            AppTheme.primaryAccent.withAlpha(
                                                (0.08 * 255).round()),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: is4K
                                        ? AppTheme.warningAccent
                                        : AppTheme.primaryAccent,
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
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        if ((stream.addonName ?? '').isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1B2335),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              stream.addonName ?? '',
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
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: AppTheme.successAccent
                                                    .withAlpha(
                                                        (0.3 * 255).round()),
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
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                        if (isDirect)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF143026),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: AppTheme.successAccent
                                                    .withAlpha(
                                                        (0.4 * 255).round()),
                                              ),
                                            ),
                                            child: const Text(
                                              '⚡ Direct Stream',
                                              style: TextStyle(
                                                color: AppTheme.successAccent,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        if (!isDirect)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF332014),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: AppTheme.warningAccent
                                                    .withAlpha(
                                                        (0.4 * 255).round()),
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                AuraIcon(
                                                  AppIcons.warning,
                                                  size: 11,
                                                  color: AppTheme.warningAccent,
                                                ),
                                                SizedBox(width: 3),
                                                Text(
                                                  '⚠️ P2P (Debrid Required)',
                                                  style: TextStyle(
                                                    color: AppTheme.warningAccent,
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),
                              AuraIcon(
                                AppIcons.playCircle,
                                color: isDirect ? AppTheme.primaryAccent : AppTheme.textMuted,
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
    );
  }
}
