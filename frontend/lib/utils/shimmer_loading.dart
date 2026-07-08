import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'app_theme.dart';

/// Shimmer loading placeholder widgets
class ShimmerLoading {
  ShimmerLoading._();

  static const Color _baseColor = Color(0xFFE2E8F0);
  static const Color _highlightColor = Color(0xFFF1F5F9);

  /// Shimmer wrapper
  static Widget shimmer({required Widget child}) {
    return Shimmer.fromColors(
      baseColor: _baseColor,
      highlightColor: _highlightColor,
      child: child,
    );
  }

  /// Shimmer placeholder for item list cards (home screen)
  static Widget itemListShimmer({int count = 4}) {
    return Column(
      children: List.generate(count, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: shimmer(
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Row(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.radiusLarge),
                        bottomLeft: Radius.circular(AppTheme.radiusLarge),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(height: 14, width: 140, color: Colors.white),
                          const SizedBox(height: 10),
                          Container(height: 10, width: 100, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(height: 10, width: 120, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(height: 10, width: 80, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Shimmer for category chips
  static Widget categoryShimmer() {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: shimmer(
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shimmer for detail page
  static Widget detailShimmer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          shimmer(
            child: Container(height: 280, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                shimmer(child: Container(height: 28, width: 200, color: Colors.white)),
                const SizedBox(height: 16),
                shimmer(child: Container(height: 16, width: 140, color: Colors.white)),
                const SizedBox(height: 24),
                shimmer(
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                shimmer(child: Container(height: 80, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer for claim cards
  static Widget claimCardShimmer({int count = 3}) {
    return Column(
      children: List.generate(count, (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: shimmer(
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
            ),
          ),
        );
      }),
    );
  }
}
