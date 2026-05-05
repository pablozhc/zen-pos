/// Spacing system - EXACT specification from Zen POS design
class Spacing {
  static const double xxxs = 2.0; // Tight elements
  static const double xxs = 4.0; // Very close items
  static const double xs = 8.0; // Close items
  static const double sm = 12.0; // Card padding
  static const double md = 16.0; // Standard spacing
  static const double lg = 24.0; // Section spacing
  static const double xl = 32.0; // Large gaps
  static const double xxl = 48.0; // Hero spacing
  static const double xxxl = 64.0; // Massive spacing
}

/// Corner radius system - Larger, softer corners
class CornerRadius {
  static const double xs = 8.0; // Small badges
  static const double sm = 12.0; // Buttons, inputs
  static const double md = 16.0; // Cards
  static const double lg = 20.0; // Large cards
  static const double xl = 24.0; // Bottom sheets
  static const double xxl = 32.0; // Hero cards
  static const double full = 9999.0; // Pills, circular
}

/// Touch target sizes - Critical for bar environment (wet hands!)
class TouchTarget {
  static const double minimum = 44.0; // Apple HIG minimum
  static const double comfortable = 54.0; // Preferred for this app
  static const double large = 70.0; // Primary actions
  static const double hero = 100.0; // Product tiles

  // Icons
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconHero = 32.0;
}
