import 'package:flutter/material.dart';

/// Custom page transitions: Fade + Slide
class FadeSlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  FadeSlideRoute({
    required this.page,
    this.direction = SlideDirection.right,
    Duration duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final begin = _getOffset(direction);
            final tween = Tween(begin: begin, end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeIn));

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: SlideTransition(
                position: animation.drive(tween),
                child: child,
              ),
            );
          },
        );

  static Offset _getOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.right:
        return const Offset(0.15, 0);
      case SlideDirection.left:
        return const Offset(-0.15, 0);
      case SlideDirection.up:
        return const Offset(0, 0.15);
      case SlideDirection.down:
        return const Offset(0, -0.15);
    }
  }
}

enum SlideDirection { right, left, up, down }

/// Simple fade transition
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeRoute({
    required this.page,
    Duration duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: duration,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation.drive(
                Tween<double>(begin: 0.0, end: 1.0)
                    .chain(CurveTween(curve: Curves.easeIn)),
              ),
              child: child,
            );
          },
        );
}

/// Slide up transition (for bottom sheets / forms)
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpRoute({
    required this.page,
    Duration duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (_, animation, __, child) {
            final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}
