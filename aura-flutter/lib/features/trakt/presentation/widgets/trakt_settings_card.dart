import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/presentation/primitives/aura_icon.dart';
import 'package:aura/features/trakt/data/services/trakt_auth_service.dart';

class TraktSettingsCard extends StatefulWidget {
  final TraktAuthService authService;

  const TraktSettingsCard({
    super.key,
    required this.authService,
  });

  @override
  State<TraktSettingsCard> createState() => _TraktSettingsCardState();
}

class _TraktSettingsCardState extends State<TraktSettingsCard> {
  bool _isConnected = false;
  TraktDeviceCodeResponse? _deviceCode;
  bool _isLoading = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final token = await widget.authService.getToken();
    if (mounted) {
      setState(() => _isConnected = token != null);
    }
  }

  Future<void> _startPairing() async {
    setState(() => _isLoading = true);
    final code = await widget.authService.generateDeviceCode();
    if (mounted) {
      setState(() {
        _deviceCode = code;
        _isLoading = false;
      });
      if (code != null) {
        _startPolling(code);
      }
    }
  }

  void _startPolling(TraktDeviceCodeResponse code) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      Duration(seconds: code.interval > 0 ? code.interval : 5),
      (timer) async {
        final token = await widget.authService.pollForToken(code.deviceCode);
        if (token != null && mounted) {
          timer.cancel();
          setState(() {
            _isConnected = true;
            _deviceCode = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.surfaceElevated,
              content: Text('Successfully linked Trakt.tv account!'),
            ),
          );
        }
      },
    );
  }

  Future<void> _disconnect() async {
    _pollingTimer?.cancel();
    await widget.authService.disconnect();
    if (mounted) {
      setState(() {
        _isConnected = false;
        _deviceCode = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text('Disconnected Trakt.tv account.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const AuraIcon(AppIcons.history, color: AppColors.accentPink, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Trakt.tv Integration',
                    style: context.auraText.bodyOverview.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isConnected
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: _isConnected
                        ? Colors.greenAccent
                        : const Color(0x1AFFFFFF),
                    width: 1,
                  ),
                ),
                child: Text(
                  _isConnected ? 'Connected' : 'Not Linked',
                  style: TextStyle(
                    color: _isConnected ? Colors.greenAccent : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isConnected
                ? 'Your watch progress and playback scrobbles are automatically synchronizing with your Trakt.tv account.'
                : 'Connect your Trakt.tv account to automatically track your watch history, continue watching progress, and sync ratings across devices.',
            style: context.auraText.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 16),
          if (_deviceCode != null && !_isConnected) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentPink.withValues(alpha: 0.6)),
              ),
              child: Column(
                children: [
                  const Text(
                    '1. Visit trakt.tv/activate on your phone or computer\n2. Enter the verification code below:',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    _deviceCode!.userCode,
                    style: const TextStyle(
                      color: AppColors.accentPink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Waiting for confirmation...',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isConnected
                    ? AppColors.statusError.withValues(alpha: 0.85)
                    : Colors.white,
                foregroundColor: _isConnected ? Colors.white : Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading
                  ? null
                  : (_isConnected
                      ? _disconnect
                      : (_deviceCode == null ? _startPairing : _checkStatus)),
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : AuraIcon(
                      _isConnected ? AppIcons.logout : AppIcons.login,
                      size: 16,
                      color: _isConnected ? Colors.white : Colors.black,
                    ),
              label: Text(
                _isConnected
                    ? 'Disconnect Trakt Account'
                    : (_deviceCode == null
                        ? 'Link Trakt.tv Account'
                        : 'Check Authorization'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
