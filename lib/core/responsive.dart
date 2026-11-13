import 'package:flutter/material.dart';

/// Breakpoints and responsive helpers for the CRM app.
/// Usage:
///   Responsive.isMobile(context)
///   Responsive.isTablet(context)
///   Responsive.isDesktop(context)
///   Responsive.value(context, mobile: 16, tablet: 24, desktop: 32)
class Responsive {
  Responsive._();

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobileBreakpoint && w < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isWideDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  /// Pick a value based on the current screen width.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? desktop;
    return mobile;
  }

  /// Responsive padding helper — returns EdgeInsets based on screen size.
  static EdgeInsets screenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    }
    return const EdgeInsets.all(32);
  }

  /// Responsive font scale factor
  static double fontScale(BuildContext context) {
    if (isMobile(context)) return 0.85;
    if (isTablet(context)) return 0.92;
    return 1.0;
  }

  /// Screen width
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  /// Screen height
  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;
}

/// A responsive builder widget that provides the current breakpoint.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    ScreenType screenType,
  )
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        ScreenType screenType;
        if (constraints.maxWidth < Responsive.mobileBreakpoint) {
          screenType = ScreenType.mobile;
        } else if (constraints.maxWidth < Responsive.tabletBreakpoint) {
          screenType = ScreenType.tablet;
        } else {
          screenType = ScreenType.desktop;
        }
        return builder(context, constraints, screenType);
      },
    );
  }
}

enum ScreenType { mobile, tablet, desktop }
