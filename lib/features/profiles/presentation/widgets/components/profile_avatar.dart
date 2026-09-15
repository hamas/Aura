import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../domain/entities/user_profile.dart';

class ProfileAvatar extends StatelessWidget {
  final UserProfile profile;
  final double size;
  final bool isActive;
  final VoidCallback? onTap;
  final bool showBadge;

  const ProfileAvatar({
    super.key,
    required this.profile,
    this.size = 80.0,
    this.isActive = false,
    this.onTap,
    this.showBadge = true,
  });

  List<Color> get _paletteColors {
    final matches = ProfileAvatarPalette.curatedPalettes.where(
      (p) => p['id'] == profile.avatarPaletteId,
    );
    if (matches.isNotEmpty) {
      final colors = (matches.first['colors'] as List).cast<int>();
      return colors.map((c) => Color(c)).toList();
    }
    return [const Color(0xFF8A2BE2), const Color(0xFF4A00E0)];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _paletteColors;
    final primaryColor = colors.first;
    final secondaryColor = colors.length > 1 ? colors[1] : colors.first;
    final isKids = profile.isKids;

    Widget avatarContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isKids
              ? [const Color(0xFFFF9800), const Color(0xFFFF5722)]
              : [primaryColor, secondaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: (isKids ? const Color(0xFFFF9800) : primaryColor).withValues(alpha: isActive ? 0.5 : 0.25),
            blurRadius: isActive ? 16 : 10,
            spreadRadius: isActive ? 3 : 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
          width: isActive ? 2.5 : 1.5,
        ),
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Gloss Overlay
            Positioned(
              top: -size * 0.2,
              left: -size * 0.2,
              child: Container(
                width: size * 0.8,
                height: size * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
            // Center Avatar Content (Initial or Kids Icon)
            Center(
              child: isKids
                  ? Icon(
                      Icons.child_care_rounded,
                      size: size * 0.5,
                      color: Colors.white,
                    )
                  : Text(
                      profile.initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.38,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        shadows: const [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );

    if (showBadge) {
      avatarContent = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarContent,
          if (isKids)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.black, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: const Text(
                  'KIDS',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            )
          else if (profile.hasPin)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: const AuraIcon(
                  AppIcons.lock,
                  color: Colors.white,
                  size: 11,
                ),
              ),
            ),
        ],
      );
    }

    if (onTap == null) return avatarContent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      splashColor: Colors.white10,
      highlightColor: Colors.transparent,
      child: avatarContent,
    );
  }
}
