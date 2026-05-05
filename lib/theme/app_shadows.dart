import 'package:flutter/material.dart';

/// Shadow system - EXACT specification from Zen POS design
class AppShadows {
  // Level 1 - Subtle elevation (list items)
  static const BoxShadow level1 = BoxShadow(
    color: Color(0x0A000000), // black.opacity(0.04)
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  // Level 2 - Card elevation (standard cards)
  static const BoxShadow level2 = BoxShadow(
    color: Color(0x14000000), // black.opacity(0.08)
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  // Level 3 - Floating elements (floating buttons)
  static const BoxShadow level3 = BoxShadow(
    color: Color(0x1F000000), // black.opacity(0.12)
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  // Level 4 - Modal overlays
  static const BoxShadow level4 = BoxShadow(
    color: Color(0x29000000), // black.opacity(0.16)
    blurRadius: 24,
    offset: Offset(0, 8),
  );
}
