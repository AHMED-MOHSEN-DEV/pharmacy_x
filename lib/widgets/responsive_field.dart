import 'package:flutter/material.dart';

/// يُحدد حجم الـ padding والـ font حسب عرض الشاشة
class ResponsiveLayout {
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768;

  static EdgeInsets pagePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    }
    return const EdgeInsets.all(16);
  }

  static double cardMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 560;
    return double.infinity;
  }

  static double labelSize(BuildContext context) {
    return isDesktop(context) ? 12 : 14;
  }

  static double inputFontSize(BuildContext context) {
    return isDesktop(context) ? 13 : 15;
  }

  static EdgeInsets fieldPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    }
    return const EdgeInsets.symmetric(horizontal: 14, vertical: 14);
  }
}