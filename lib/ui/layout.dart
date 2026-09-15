import 'package:flutter/widgets.dart';

abstract final class Breakpoints {
  /// Width at which the three-panel desktop layout replaces the phone layout.
  static const desktop = 920.0;
}

bool isDesktopLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= Breakpoints.desktop;
