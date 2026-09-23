import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';

import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../../auth/presentation/bloc/auth_state.dart';
import '../../../../auth/presentation/widgets/sign_in_modal.dart';

class SettingsAccountCard extends StatelessWidget {
  const SettingsAccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        return Card(
          color: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
            side: const BorderSide(color: AppColors.surfaceElevated),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.surfaceElevated,
                      backgroundImage: user?.photoUrl != null
                          ? NetworkImage(user!.photoUrl!)
                          : null,
                      child: user?.photoUrl == null
                          ? const AuraIcon(
                              AppIcons.person,
                              color: AppColors.textMuted,
                              size: 28,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user != null ? user.displayName : 'Guest Session',
                            style: context.auraText.itemTitle.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spacingXs),
                          Text(
                            user != null
                                ? user.email
                                : 'Sign in to sync watchlist, history & add-ons to cloud',
                            style: context.auraText.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spacingMd),
                SizedBox(
                  width: double.infinity,
                  child: state.isAuthenticated
                      ? OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.statusError,
                            side:
                                const BorderSide(color: AppColors.statusError),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () =>
                              context.read<AuthBloc>().add(SignOutEvent()),
                          icon: const AuraIcon(AppIcons.logout, size: 18),
                          label: const Text('Sign Out of Google'),
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentPink,
                            foregroundColor: AppColors.surfaceBackground,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const SignInModal(),
                          ),
                          icon: const AuraIcon(AppIcons.login, size: 18),
                          label: const Text('Sign In to Account'),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
