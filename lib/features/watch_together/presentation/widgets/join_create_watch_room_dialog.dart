import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/primitives/aura_icon.dart';
import '../../data/services/watch_together_service.dart';

class JoinCreateWatchRoomDialog extends StatefulWidget {
  final String mediaId;
  final String streamUrl;

  const JoinCreateWatchRoomDialog({
    super.key,
    required this.mediaId,
    required this.streamUrl,
  });

  @override
  State<JoinCreateWatchRoomDialog> createState() =>
      _JoinCreateWatchRoomDialogState();
}

class _JoinCreateWatchRoomDialogState extends State<JoinCreateWatchRoomDialog> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController =
      TextEditingController(text: 'Aura Viewer');
  bool _isCreating = false;
  bool _isJoining = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.surfaceElevated),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.primaryAccent.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const AuraIcon(
                    AppIcons.group,
                    color: AppTheme.primaryAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Watch Together',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Multi-User Real-Time Stream Sync',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Display Name Field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Your Display Name',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Create New Room Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isCreating
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        setState(() => _isCreating = true);
                        final service = WatchTogetherService();
                        final session = await service.createRoom(
                          mediaId: widget.mediaId,
                          streamUrl: widget.streamUrl,
                          hostDisplayName: _nameController.text.trim(),
                        );
                        if (mounted) {
                          navigator.pop(session);
                        }
                      },
                icon: const AuraIcon(AppIcons.add, size: 18),
                label: const Text(
                  'Create New Watch Room',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Row(
              children: [
                Expanded(child: Divider(color: AppTheme.surfaceElevated)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('OR JOIN',
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ),
                Expanded(child: Divider(color: AppTheme.surfaceElevated)),
              ],
            ),
            const SizedBox(height: 16),

            // Room Code Input & Join Button
            TextField(
              controller: _codeController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter Room Code (e.g. AURA-8F21)',
                hintStyle:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryAccent,
                  side: const BorderSide(color: AppTheme.primaryAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isJoining
                    ? null
                    : () async {
                        final code = _codeController.text.trim();
                        if (code.isEmpty) return;
                        final navigator = Navigator.of(context);
                        setState(() => _isJoining = true);
                        final service = WatchTogetherService();
                        final session = await service.joinRoom(
                          roomCode: code,
                          participantDisplayName: _nameController.text.trim(),
                          mediaId: widget.mediaId,
                          streamUrl: widget.streamUrl,
                        );
                        if (mounted) {
                          navigator.pop(session);
                        }
                      },
                icon: const AuraIcon(AppIcons.login, size: 18),
                label: const Text('Join Watch Room'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
