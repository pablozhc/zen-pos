import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class LandingScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onWaitlist;

  const LandingScreen({
    super.key,
    required this.onLogin,
    required this.onWaitlist,
  });

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _blobController;
  late AnimationController _fadeController;
  late AnimationController _roadmapController;
  bool _showRoadmap = false;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _roadmapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _blobController.dispose();
    _fadeController.dispose();
    _roadmapController.dispose();
    super.dispose();
  }

  void _openRoadmap() {
    setState(() => _showRoadmap = true);
    _roadmapController.forward();
  }

  void _closeRoadmap() {
    _roadmapController.reverse().then((_) {
      setState(() => _showRoadmap = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: Stack(
        children: [
          // Animated background — always running
          AnimatedBuilder(
            animation: _blobController,
            builder: (context, _) => CustomPaint(
              painter: _BlobPainter(_blobController.value),
              size: MediaQuery.of(context).size,
            ),
          ),

          // Noise overlay
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),

          // Main content
          FadeTransition(
            opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  const Spacer(),
                  _buildHero(),
                  const Spacer(),
                  _buildFooter(),
                ],
              ),
            ),
          ),

          // Roadmap overlay
          if (_showRoadmap)
            AnimatedBuilder(
              animation: _roadmapController,
              builder: (context, child) {
                final curve = CurvedAnimation(
                  parent: _roadmapController,
                  curve: Curves.easeOutCubic,
                );
                return FadeTransition(
                  opacity: curve,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(curve),
                    child: child,
                  ),
                );
              },
              child: _RoadmapOverlay(
                onClose: _closeRoadmap,
                blobController: _blobController,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('Z', style: TextStyle(
                    fontFamily: '.SF Pro Display',
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Color(0xFF080810), letterSpacing: -0.5,
                  )),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Zen POS', style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 17, fontWeight: FontWeight.w600,
                color: Colors.white, letterSpacing: -0.3,
              )),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _NavTile(label: 'Roadmap', onTap: _openRoadmap, filled: false),
              const SizedBox(width: 8),
              _NavTile(label: 'Waitlist', onTap: widget.onWaitlist, filled: false),
              const SizedBox(width: 8),
              _NavTile(label: 'Login', onTap: widget.onLogin, filled: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
            ),
            child: const Text('Point of Sale · Redefined', style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 12, fontWeight: FontWeight.w500,
              color: Colors.white70, letterSpacing: 0.3,
            )),
          ),
          const SizedBox(height: 28),
          const Text('The\nsmarter POS.', textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 64, fontWeight: FontWeight.w700,
              color: Colors.white, height: 1.05, letterSpacing: -3.0,
            )),
          const SizedBox(height: 20),
          Text('Beautifully simple. Remarkably powerful.\nBuilt for modern hospitality.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 17, fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.55),
              height: 1.5, letterSpacing: -0.2,
            )),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: widget.onWaitlist,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF5856D6).withOpacity(0.35),
                  blurRadius: 24, offset: const Offset(0, 8),
                )],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Join the waitlist', style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: Color(0xFF080810), letterSpacing: -0.3,
                  )),
                  const SizedBox(width: 8),
                  Icon(CupertinoIcons.arrow_right, size: 14,
                    color: const Color(0xFF080810).withOpacity(0.6)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FeaturePill(icon: CupertinoIcons.bolt_fill, label: 'Fast'),
          const SizedBox(width: 8),
          _FeaturePill(icon: CupertinoIcons.lock_fill, label: 'Secure'),
          const SizedBox(width: 8),
          _FeaturePill(icon: CupertinoIcons.rectangle, label: 'iPad ready'),
        ],
      ),
    );
  }
}

// ── Roadmap Overlay ──────────────────────────────────────────────────────────

class _RoadmapOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final AnimationController blobController;

  const _RoadmapOverlay({required this.onClose, required this.blobController});

  static const _phases = [
    _Phase(
      label: 'Shipped',
      period: 'Now',
      color: Color(0xFF30D158),
      items: [
        _RoadmapItem('iPad POS', 'Native Apple design, SF Pro, live orders', _Status.done),
        _RoadmapItem('Admin dashboard', 'Top nav, unified design system, warm palette', _Status.done),
        _RoadmapItem('Firebase backend', 'Firestore, Auth, real-time streams', _Status.done),
        _RoadmapItem('Repository architecture', 'Swappable data layer, testable ViewModels', _Status.done),
        _RoadmapItem('Landing page', 'Animated blob background, waitlist signup', _Status.done),
      ],
    ),
    _Phase(
      label: 'In progress',
      period: 'Q2 – Q3 2026',
      color: Color(0xFF5856D6),
      items: [
        _RoadmapItem('Bluetooth printing', 'Xprinter XP-C260H, kitchen & receipt tickets', _Status.active),
        _RoadmapItem('Happy Hours auto-apply', 'Discounts fire automatically in POS at set times', _Status.active),
        _RoadmapItem('iOS App Store release', 'TestFlight beta → production, bundle ID set', _Status.active),
        _RoadmapItem('Waitlist + onboarding flow', 'Email capture, invite system, first-run setup', _Status.next),
        _RoadmapItem('Offline mode', 'Local cache, sync on reconnect, zero data loss', _Status.next),
      ],
    ),
    _Phase(
      label: 'Coming soon',
      period: 'Q4 2026',
      color: Color(0xFFFF9F0A),
      items: [
        _RoadmapItem('Kitchen Display System', 'Live ticket board for kitchen staff, bump to complete', _Status.planned),
        _RoadmapItem('Table reservations', 'Booking flow, calendar view, guest notes', _Status.planned),
        _RoadmapItem('Split bill', 'By item or evenly, partial card payments', _Status.planned),
        _RoadmapItem('Advanced analytics', 'Hourly heatmaps, top products, staff performance', _Status.planned),
        _RoadmapItem('Multi-language', 'Czech, English, German — switch per device', _Status.planned),
      ],
    ),
    _Phase(
      label: 'Future',
      period: '2027',
      color: Color(0xFFBF5AF2),
      items: [
        _RoadmapItem('Multi-location', 'One admin, multiple venues, shared menu library', _Status.idea),
        _RoadmapItem('Customer loyalty', 'QR stamp cards, points, birthday rewards', _Status.idea),
        _RoadmapItem('Inventory auto-deduction', 'Products consume stock on sale automatically', _Status.idea),
        _RoadmapItem('Public API', 'Webhooks, integrations, Zapier connector', _Status.idea),
        _RoadmapItem('Self-order kiosk', 'Customer-facing iPad for walk-in orders', _Status.idea),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF080810).withOpacity(0.96),
      child: Stack(
        children: [
          // Subtle blob background
          AnimatedBuilder(
            animation: blobController,
            builder: (_, __) => CustomPaint(
              painter: _BlobPainter(blobController.value, opacity: 0.18),
              size: MediaQuery.of(context).size,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Roadmap', style: TextStyle(
                            fontFamily: '.SF Pro Display',
                            fontSize: 28, fontWeight: FontWeight.w700,
                            color: Colors.white, letterSpacing: -0.8,
                          )),
                          Text('Where Zen POS is headed', style: TextStyle(
                            fontFamily: '.SF Pro Text',
                            fontSize: 14, fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.4),
                          )),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.5),
                          ),
                          child: Icon(CupertinoIcons.xmark,
                            size: 14, color: Colors.white.withOpacity(0.7)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Phases
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Column(
                      children: _phases.asMap().entries.map((e) =>
                        _PhaseCard(phase: e.value, isLast: e.key == _phases.length - 1),
                      ).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final _Phase phase;
  final bool isLast;

  const _PhaseCard({required this.phase, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: phase.color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: phase.color.withOpacity(0.5), blurRadius: 8)],
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 20 + phase.items.length * 60.0,
                  color: Colors.white.withOpacity(0.08),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phase header
                Row(
                  children: [
                    Text(phase.label, style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: phase.color, letterSpacing: 0.1,
                    )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(phase.period, style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 11, fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.35),
                      )),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Items
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
                  ),
                  child: Column(
                    children: phase.items.asMap().entries.map((e) {
                      final item = e.value;
                      final isLast = e.key == phase.items.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                _StatusDot(status: item.status, phaseColor: phase.color),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.title, style: TextStyle(
                                        fontFamily: '.SF Pro Text',
                                        fontSize: 14, fontWeight: FontWeight.w600,
                                        color: item.status == _Status.done
                                            ? Colors.white.withOpacity(0.5)
                                            : Colors.white.withOpacity(0.9),
                                        letterSpacing: -0.2,
                                        decoration: item.status == _Status.done
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor: Colors.white.withOpacity(0.3),
                                      )),
                                      const SizedBox(height: 2),
                                      Text(item.description, style: TextStyle(
                                        fontFamily: '.SF Pro Text',
                                        fontSize: 12, fontWeight: FontWeight.w400,
                                        color: Colors.white.withOpacity(0.3),
                                        height: 1.4,
                                      )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            Divider(height: 1, thickness: 0.5,
                              color: Colors.white.withOpacity(0.06), indent: 44),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final _Status status;
  final Color phaseColor;

  const _StatusDot({required this.status, required this.phaseColor});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _Status.done:
        return Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF30D158).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(CupertinoIcons.checkmark, size: 11,
            color: Color(0xFF30D158)),
        );
      case _Status.active:
        return Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: phaseColor.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: phaseColor, width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: phaseColor, shape: BoxShape.circle),
            ),
          ),
        );
      case _Status.next:
        return Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Icon(CupertinoIcons.arrow_right, size: 9,
            color: Colors.white.withOpacity(0.4)),
        );
      case _Status.planned:
      case _Status.idea:
        return Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 5, height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
    }
  }
}

// ── Data models ──────────────────────────────────────────────────────────────

enum _Status { done, active, next, planned, idea }

class _Phase {
  final String label;
  final String period;
  final Color color;
  final List<_RoadmapItem> items;
  const _Phase({required this.label, required this.period, required this.color, required this.items});
}

class _RoadmapItem {
  final String title;
  final String description;
  final _Status status;
  const _RoadmapItem(this.title, this.description, this.status);
}

// ── Nav tile ─────────────────────────────────────────────────────────────────

class _NavTile extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _NavTile({required this.label, required this.onTap, required this.filled});

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.filled ? Colors.white : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: widget.filled ? null : Border.all(
              color: Colors.white.withOpacity(0.15), width: 0.5),
          ),
          child: Text(widget.label, style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14, fontWeight: FontWeight.w500,
            color: widget.filled ? const Color(0xFF080810) : Colors.white.withOpacity(0.85),
            letterSpacing: -0.2,
          )),
        ),
      ),
    );
  }
}

// ── Feature pill ─────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 12, fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.5),
          )),
        ],
      ),
    );
  }
}

// ── Blob painter ─────────────────────────────────────────────────────────────

class _BlobPainter extends CustomPainter {
  final double t;
  final double opacity;

  _BlobPainter(this.t, {this.opacity = 1.0});

  static const _blobs = [
    (baseX: 0.2,  baseY: 0.25, r: 0.55, dX: 0.12, dY: 0.10, pX: 0.0, pY: 1.2, spd: 1.0,  color: Color(0xFF5856D6), op: 0.55),
    (baseX: 0.78, baseY: 0.35, r: 0.50, dX: 0.10, dY: 0.08, pX: 2.1, pY: 0.5, spd: 0.85, color: Color(0xFFBF5AF2), op: 0.45),
    (baseX: 0.50, baseY: 0.70, r: 0.60, dX: 0.14, dY: 0.09, pX: 1.0, pY: 3.3, spd: 0.70, color: Color(0xFF007AFF), op: 0.35),
    (baseX: 0.15, baseY: 0.75, r: 0.40, dX: 0.09, dY: 0.12, pX: 3.5, pY: 0.9, spd: 1.1,  color: Color(0xFF30D158), op: 0.25),
    (baseX: 0.85, baseY: 0.80, r: 0.45, dX: 0.11, dY: 0.07, pX: 0.7, pY: 2.4, spd: 0.90, color: Color(0xFFFF375F), op: 0.22),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _blobs) {
      final angle = t * 2 * pi * b.spd;
      final cx = (b.baseX + sin(angle + b.pX) * b.dX) * size.width;
      final cy = (b.baseY + cos(angle + b.pY) * b.dY) * size.height;
      final radius = b.r * (size.width > size.height ? size.width : size.height) * 0.55;

      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()..shader = RadialGradient(
          colors: [b.color.withOpacity(b.op * opacity), b.color.withOpacity(0)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t || old.opacity != opacity;
}
