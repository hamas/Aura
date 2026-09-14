import 'package:flutter/material.dart';
import '../../../../core/theme/aura_theme.dart';
import '../../../../core/presentation/primitives/aura_card.dart';
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

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final token = await widget.authService.getToken();
    setState(() => _isConnected = token != null);
  }

  Future<void> _startPairing() async {
    setState(() => _isLoading = true);
    final code = await widget.authService.generateDeviceCode();
    setState(() {
      _deviceCode = code;
      _isLoading = false;
    });
  }

  Future<void> _disconnect() async {
    await widget.authService.disconnect();
    setState(() {
      _isConnected = false;
      _deviceCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuraCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_rounded, color: AppColors.primaryAccent),
              const SizedBox(width: 10),
              const Text(
                'Trakt.tv Integration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isConnected ? 'CONNECTED' : 'DISCONNECTED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isConnected
                ? 'Your watch history, ratings, and playback progress are synchronizing in real time.'
                : 'Connect your Trakt account to automatically scrobble plays and sync watchlists.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (_deviceCode != null && !_isConnected) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryAccent),
              ),
              child: Column(
                children: [
                  const Text(
                    'Go to trakt.tv/activate and enter code:',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _deviceCode!.userCode,
                    style: const TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isConnected ? Colors.redAccent : AppColors.primaryAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: _isLoading
                  ? null
                  : (_isConnected
                      ? _disconnect
                      : (_deviceCode == null ? _startPairing : _checkStatus)),
              child: Text(
                _isConnected
                    ? 'Disconnect Trakt Account'
                    : (_deviceCode == null
                        ? 'Connect Trakt.tv Account'
                        : 'I Have Confirmed Code'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
