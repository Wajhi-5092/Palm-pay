import 'package:flutter/material.dart';

/// Layout helpers only. Does not change app logic.
class AppLayout {
  AppLayout._();

  static const double contentMaxWidth = 480;

  static Size sizeOf(BuildContext context) => MediaQuery.sizeOf(context);

  static bool isNarrow(BuildContext context) => sizeOf(context).width < 360;

  static bool isShort(BuildContext context) => sizeOf(context).height < 700;

  static bool isWide(BuildContext context) => sizeOf(context).width >= 600;

  static double horizontalPadding(BuildContext context) {
    final w = sizeOf(context).width;
    if (w < 360) return 16;
    if (w >= 600) return 32;
    return 24;
  }

  static double titleSize(BuildContext context) => isNarrow(context) ? 26 : 32;

  static double sectionTitleSize(BuildContext context) =>
      isNarrow(context) ? 16 : 18;

  static double pageTopGap(BuildContext context) =>
      isShort(context) ? 16 : 32;

  /// Caps huge system font sizes so layouts don't overflow.
  static TextScaler clampedTextScaler(BuildContext context) {
    return MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.2,
    );
  }
}

/// Centers content on tablets; keeps phones full-width.
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: AppLayout.horizontalPadding(context),
              ),
          child: child,
        ),
      ),
    );
  }
}
