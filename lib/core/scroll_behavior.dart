import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

/// Lets desktop users drag the horizontal carousel with a mouse or trackpad.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
