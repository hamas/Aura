import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/aura_theme_extension.dart';

/// Foundational interactive surface card with hover/focus scaling, glow rings, and clean radii.
class AuraCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool enableHoverScale;
  final double scaleFactor;
  final bool autofocus;
  final FocusNode? focusNode;

  const AuraCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.enableHoverScale = true,
    this.scaleFactor = 1.05,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<AuraCard> createState() => _AuraCardState();
}

class _AuraCardState extends State<AuraCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  bool get _isActive => (_isHovered || _isFocused) && widget.enableHoverScale;

  @override
  Widget build(BuildContext context) {
    final themeExt = context.auraTheme;
    final effectiveRadius = widget.borderRadius ?? AppTokens.borderRadiusSmall;
    final effectiveColor = widget.color ?? themeExt.cardBackground;

    return FocusableActionDetector(
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      onShowHoverHighlight: (hovered) {
        if (_isHovered != hovered) {
          setState(() => _isHovered = hovered);
        }
      },
      onShowFocusHighlight: (focused) {
        if (_isFocused != focused) {
          setState(() => _isFocused = focused);
        }
      },
      child: AnimatedScale(
        scale: _isActive ? widget.scaleFactor : 1.0,
        duration: AppTokens.focusAnimationDuration,
        curve: AppTokens.focusAnimationCurve,
        child: Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: effectiveRadius,
            border: Border.all(
              color:
                  _isActive ? themeExt.focusBorder : themeExt.unfocusedBorder,
              width: _isActive ? AppTokens.focusBorderWidth : 1.0,
            ),
            boxShadow: _isActive
                ? [
                    BoxShadow(
                      color: AppColors.accentPink.withAlpha(
                        (0.35 * 255).round(),
                      ),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: effectiveRadius,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              borderRadius: effectiveRadius,
              splashColor: AppColors.accentPink.withAlpha((0.15 * 255).round()),
              highlightColor:
                  AppColors.accentPink.withAlpha((0.08 * 255).round()),
              child: Padding(
                padding: widget.padding ?? EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: effectiveRadius,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
