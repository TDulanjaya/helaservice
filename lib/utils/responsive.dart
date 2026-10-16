import 'package:flutter/material.dart';

// responsive screen breakpoints and layout helpers
enum ScreenType {
  compact,
  medium,
  expanded,
}

class Responsive {
  static const double tabletShortestSide = 600.0;
  static const double desktopWidth = 1024.0;
  static const double wideLandscapeWidth = 720.0;

  static Size sizeOf(BuildContext context) => MediaQuery.sizeOf(context);

  static double width(BuildContext context) => sizeOf(context).width;

  static double height(BuildContext context) => sizeOf(context).height;

  static double shortestSide(BuildContext context) =>
      sizeOf(context).shortestSide;

  static Orientation orientation(BuildContext context) =>
      MediaQuery.orientationOf(context);

  static bool isLandscape(BuildContext context) =>
      orientation(context) == Orientation.landscape;

  // tablet requires shortest side >= 600 (both dimensions large enough)
  static bool isTablet(BuildContext context) =>
      shortestSide(context) >= tabletShortestSide;

  // desktop requires wide screen and large shortest side
  static bool isDesktop(BuildContext context) =>
      width(context) >= desktopWidth &&
      shortestSide(context) >= tabletShortestSide;

  // phone in landscape: landscape orientation with phone-sized shortest side (< 600)
  static bool isPhoneLandscape(BuildContext context) =>
      isLandscape(context) && shortestSide(context) < tabletShortestSide;

  // wide landscape: landscape and width >= 720
  static bool isWideLandscape(BuildContext context) =>
      isLandscape(context) && width(context) >= wideLandscapeWidth;

  // screen type categorizer
  static ScreenType screenType(BuildContext context) {
    final w = width(context);
    final side = shortestSide(context);
    if (w >= desktopWidth && side >= tabletShortestSide) {
      return ScreenType.expanded;
    }
    if (side >= tabletShortestSide) {
      return ScreenType.medium;
    }
    return ScreenType.compact;
  }
}

// centered container for responsive forms on tablet and desktop
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 560.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
