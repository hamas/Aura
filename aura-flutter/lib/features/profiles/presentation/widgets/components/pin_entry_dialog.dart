import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/presentation/primitives/aura_card.dart';
import '../../../domain/entities/user_profile.dart';

class PinEntryDialog extends StatefulWidget {
  final UserProfile targetProfile;
  final ValueChanged<String> onPinSubmitted;

  const PinEntryDialog({
    super.key,
    required this.targetProfile,
    required this.onPinSubmitted,
  });

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _hasError = false;

  void _onKeyTap(String value) {
    if (_pinController.text.length < 4) {
      setState(() {
        _pinController.text += value;
        _hasError = false;
      });

      if (_pinController.text.length == 4) {
        if (widget.targetProfile.verifyPin(_pinController.text)) {
          widget.onPinSubmitted(_pinController.text);
          Navigator.of(context).pop();
        } else {
          setState(() {
            _hasError = true;
            _pinController.clear();
          });
        }
      }
    }
  }

  void _onBackspace() {
    if (_pinController.text.isNotEmpty) {
      setState(() {
        _pinController.text =
            _pinController.text.substring(0, _pinController.text.length - 1);
        _hasError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(
            color: _hasError
                ? AppColors.statusError
                : AppColors.accentPink.withValues(alpha: 0.4),
          ),
        ),
        child: AuraCard(
          padding: const EdgeInsets.all(AppTokens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter PIN for ${widget.targetProfile.name}',
                style: context.auraText.sectionTitle
                    .copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Text(
                _hasError ? 'Incorrect PIN. Try again.' : 'Protected profile',
                style: context.auraText.caption.copyWith(
                  color:
                      _hasError ? AppColors.statusError : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppTokens.spacingMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _pinController.text.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spacingSm),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? AppColors.accentPink
                          : AppColors.surfaceElevated,
                      border: Border.all(
                        color:
                            filled ? AppColors.accentPink : AppColors.textMuted,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppTokens.spacingLg),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                mainAxisSpacing: AppTokens.spacingSm,
                crossAxisSpacing: AppTokens.spacingSm,
                children: [
                  ...List.generate(9, (index) {
                    final number = '${index + 1}';
                    return IconButton(
                      onPressed: () => _onKeyTap(number),
                      icon: Text(
                        number,
                        style: context.auraText.itemTitle
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    );
                  }),
                  const SizedBox.shrink(),
                  IconButton(
                    onPressed: () => _onKeyTap('0'),
                    icon: Text(
                      '0',
                      style: context.auraText.itemTitle
                          .copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                  IconButton(
                    onPressed: _onBackspace,
                    icon: const Icon(Icons.backspace_outlined,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
