import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../catalog/domain/entities/media_item.dart';
import '../../domain/entities/download_task.dart';
import '../bloc/downloads_bloc.dart';
import '../bloc/downloads_event.dart';
import '../bloc/downloads_state.dart';

class DownloadActionButton extends StatelessWidget {
  final int mediaId;
  final MediaType mediaType;
  final int? seasonNumber;
  final int? episodeNumber;
  final VoidCallback onStartDownload;
  final VoidCallback? onPlayOffline;
  final double iconSize;
  final bool showLabel;

  const DownloadActionButton({
    super.key,
    required this.mediaId,
    required this.mediaType,
    this.seasonNumber,
    this.episodeNumber,
    required this.onStartDownload,
    this.onPlayOffline,
    this.iconSize = 22,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadsBloc, DownloadsState>(
      builder: (context, state) {
        final task = state.getMediaTask(
          mediaId: mediaId,
          mediaType: mediaType,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
        );

        if (task == null || task.isFailed) {
          return _buildNotDownloaded(context);
        }

        if (task.isDownloading || task.isQueued) {
          return _buildDownloading(context, task);
        }

        if (task.isPaused) {
          return _buildPaused(context, task);
        }

        if (task.isCompleted) {
          return _buildCompleted(context, task);
        }

        return _buildNotDownloaded(context);
      },
    );
  }

  Widget _buildNotDownloaded(BuildContext context) {
    if (showLabel) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.glassWhite,
          side: const BorderSide(color: Colors.white24, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onPressed: onStartDownload,
        icon: Icon(
          Icons.arrow_circle_down_rounded,
          size: iconSize,
          color: AppColors.textPrimary,
        ),
        label: const Text(
          'Download',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    return IconButton(
      iconSize: iconSize,
      icon: const Icon(
        Icons.arrow_circle_down_rounded,
        color: AppColors.textSecondary,
      ),
      tooltip: 'Download Offline',
      onPressed: onStartDownload,
    );
  }

  Widget _buildDownloading(BuildContext context, DownloadTask task) {
    final percentage = task.progressPercentage;

    if (showLabel) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentPink,
          backgroundColor: AppColors.surfaceElevated,
          side: const BorderSide(color: AppColors.accentPink, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onPressed: () {
          context.read<DownloadsBloc>().add(PauseDownloadEvent(task.id));
        },
        icon: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            strokeWidth: 2,
            color: AppColors.accentPink,
          ),
        ),
        label: Text(
          '${(percentage * 100).toInt()}%',
          style: const TextStyle(
            color: AppColors.accentPink,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        context.read<DownloadsBloc>().add(PauseDownloadEvent(task.id));
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: iconSize + 4,
              height: iconSize + 4,
              child: CircularProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                strokeWidth: 2.5,
                backgroundColor: const Color(0x33FFFFFF),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.accentPink),
              ),
            ),
            Icon(
              Icons.pause_rounded,
              size: iconSize * 0.7,
              color: AppColors.accentPink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaused(BuildContext context, DownloadTask task) {
    if (showLabel) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          backgroundColor: AppColors.surfaceElevated,
          side: const BorderSide(color: Colors.white24, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onPressed: () {
          context.read<DownloadsBloc>().add(ResumeDownloadEvent(task.id));
        },
        icon: const Icon(
          Icons.play_arrow_rounded,
          size: 18,
          color: AppColors.textSecondary,
        ),
        label: const Text(
          'Resume',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    return IconButton(
      iconSize: iconSize,
      icon: const Icon(
        Icons.play_circle_outline_rounded,
        color: AppColors.textSecondary,
      ),
      tooltip: 'Resume Download',
      onPressed: () {
        context.read<DownloadsBloc>().add(ResumeDownloadEvent(task.id));
      },
    );
  }

  Widget _buildCompleted(BuildContext context, DownloadTask task) {
    if (showLabel) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentPink,
          backgroundColor: const Color(0x1EB877FF),
          side: const BorderSide(color: AppColors.accentPink, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onPressed: onPlayOffline ?? () => _showDownloadedOptions(context, task),
        icon: const Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: AppColors.accentPink,
        ),
        label: const Text(
          'Downloaded',
          style: TextStyle(
            color: AppColors.accentPink,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    return IconButton(
      iconSize: iconSize,
      icon: const Icon(
        Icons.check_circle_rounded,
        color: AppColors.accentPink,
      ),
      tooltip: 'Downloaded (Ready Offline)',
      onPressed: () => _showDownloadedOptions(context, task),
    );
  }

  void _showDownloadedOptions(BuildContext context, DownloadTask task) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.play_circle_filled_rounded,
                      color: AppColors.accentPink),
                  title: const Text('Play Offline',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(task.formattedTotalSize,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    if (onPlayOffline != null) {
                      onPlayOffline!();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.errorAccent),
                  title: const Text('Delete Download',
                      style: TextStyle(color: AppColors.errorAccent)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context
                        .read<DownloadsBloc>()
                        .add(DeleteDownloadEvent(task.id));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
