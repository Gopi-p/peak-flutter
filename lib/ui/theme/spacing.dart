/// Spacing scale — mirrors `peak-web/tailwind.config.ts` spacing.
class PeakSpacing {
  PeakSpacing._();

  static const double gutter = 16; // between siblings
  static const double edge = 20;   // screen edge padding (mobile-tightened)
  static const double stack = 28;  // section gaps
  static const double tap = 52;    // minimum tap target (iOS HIG = 44; we go richer)
}
