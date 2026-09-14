import 'package:flutter/material.dart';
import '../../../../core/theme/aura_theme.dart';
import '../../../../core/presentation/primitives/aura_card.dart';

class AuraPinModal extends StatefulWidget {
  final String title;
  final bool Function(String pin) onVerifyPin;

  const AuraPinModal({
    super.key,
    this.title = 'Enter 4-Digit PIN',
    required this.onVerifyPin,
  });

  static Future<bool?> show(
    BuildContext context, {
    required bool Function(String pin) onVerifyPin,
    String title = 'Enter 4-Digit PIN',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AuraPinModal(title: title, onVerifyPin: onVerifyPin),
    );
  }

  @override
  State<AuraPinModal> createState() => _AuraPinModalState();
}

class _AuraPinModalState extends State<AuraPinModal> {
  final List<String> _enteredPin = [];
  bool _hasError = false;

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin.add(digit);
        _hasError = false;
      });

      if (_enteredPin.length == 4) {
        final pin = _enteredPin.join();
        final isValid = widget.onVerifyPin(pin);
        if (isValid) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _hasError = true;
            _enteredPin.clear();
          });
        }
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _hasError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceBackground,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAccent.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? AppColors.primaryAccent
                        : AppColors.surfaceCard,
                    border: Border.all(
                      color: _hasError
                          ? Colors.redAccent
                          : AppColors.primaryAccent,
                    ),
                  ),
                );
              }),
            ),
            if (_hasError) ...[
              const SizedBox(height: 12),
              const Text(
                'Incorrect PIN. Try again.',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),

            // Keypad Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index == 9) {
                  return const SizedBox.shrink(); // Empty slot
                }
                if (index == 11) {
                  return IconButton(
                    onPressed: _onBackspace,
                    icon: const Icon(Icons.backspace_outlined,
                        color: Colors.white),
                  );
                }
                final digit = index == 10 ? '0' : '${index + 1}';
                return InkWell(
                  onTap: () => _onKeyPress(digit),
                  borderRadius: BorderRadius.circular(10),
                  child: AuraCard(
                    padding: EdgeInsets.zero,
                    child: Center(
                      child: Text(
                        digit,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
