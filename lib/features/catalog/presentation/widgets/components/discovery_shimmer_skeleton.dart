import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';


class DiscoveryShimmerSkeleton extends StatelessWidget {
  const DiscoveryShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final heroHeight = MediaQuery.of(context).size.height * 0.58;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _buildShimmerBox(
                width: double.infinity,
                height: heroHeight,
                borderRadius: 0,
              ),
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(
                      width: 80,
                      height: 12,
                      borderRadius: AppTokens.radiusSmall,
                    ),
                    const SizedBox(height: 10),
                    _buildShimmerBox(
                      width: 240,
                      height: 28,
                      borderRadius: AppTokens.radiusSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildShimmerBox(
                          width: 50,
                          height: 20,
                          borderRadius: AppTokens.radiusSmall,
                        ),
                        const SizedBox(width: 8),
                        _buildShimmerBox(
                          width: 44,
                          height: 20,
                          borderRadius: AppTokens.radiusSmall,
                        ),
                        const SizedBox(width: 8),
                        _buildShimmerBox(
                          width: 60,
                          height: 20,
                          borderRadius: AppTokens.radiusSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildShimmerBox(
                          width: 110,
                          height: 38,
                          borderRadius: AppTokens.radiusSmall,
                        ),
                        const SizedBox(width: 10),
                        _buildShimmerBox(
                          width: 100,
                          height: 38,
                          borderRadius: AppTokens.radiusSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (int s = 0; s < 2; s++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _buildShimmerBox(
                width: 160,
                height: 18,
                borderRadius: AppTokens.radiusSmall,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) {
                  return _buildShimmerBox(
                    width: AppTokens.posterWidthMobile,
                    height: 180,
                    borderRadius: AppTokens.radiusSmall,
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.borderSubtle, width: 0.8),
      ),
    );
  }
}
