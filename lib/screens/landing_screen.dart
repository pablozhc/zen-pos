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
  }

  @override
  void dispose() {
    _blobController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _blobController,
            builder: (context, _) {
              return CustomPaint(
                painter: _BlobPainter(_blobController.value),
                size: MediaQuery.of(context).size,
              );
            },
          ),

          // Noise grain overlay
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

          // Content
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _fadeController,
              curve: Curves.easeOut,
            ),
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
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Z',
                    style: TextStyle(
                      fontFamily: '.SF Pro Display',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF080810),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Zen POS',
                style: TextStyle(
                  fontFamily: '.SF Pro Display',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Action tiles
          Row(
            children: [
              _NavTile(
                label: 'Waitlist',
                onTap: widget.onWaitlist,
                filled: false,
              ),
              const SizedBox(width: 8),
              _NavTile(
                label: 'Login',
                onTap: widget.onLogin,
                filled: true,
              ),
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
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 0.5,
              ),
            ),
            child: const Text(
              'Point of Sale · Redefined',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
                letterSpacing: 0.3,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Headline
          const Text(
            'The\nsmarter POS.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 64,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.05,
              letterSpacing: -3.0,
            ),
          ),

          const SizedBox(height: 20),

          // Subheadline
          Text(
            'Beautifully simple. Remarkably powerful.\nBuilt for modern hospitality.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.55),
              height: 1.5,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 40),

          // CTA
          GestureDetector(
            onTap: widget.onWaitlist,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5856D6).withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Join the waitlist',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF080810),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.arrow_right,
                    size: 14,
                    color: const Color(0xFF080810).withOpacity(0.6),
                  ),
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

class _NavTile extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _NavTile({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.filled
                ? Colors.white
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: widget.filled
                ? null
                : Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 0.5,
                  ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.filled
                  ? const Color(0xFF080810)
                  : Colors.white.withOpacity(0.85),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

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
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Blob background painter ──────────────────────────────────────────────────

class _BlobPainter extends CustomPainter {
  final double t;

  _BlobPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final blobs = [
      _Blob(
        baseX: 0.2,
        baseY: 0.25,
        radiusFactor: 0.55,
        driftX: 0.12,
        driftY: 0.10,
        phaseX: 0.0,
        phaseY: 1.2,
        speed: 1.0,
        color: const Color(0xFF5856D6),
        opacity: 0.55,
      ),
      _Blob(
        baseX: 0.78,
        baseY: 0.35,
        radiusFactor: 0.50,
        driftX: 0.10,
        driftY: 0.08,
        phaseX: 2.1,
        phaseY: 0.5,
        speed: 0.85,
        color: const Color(0xFFBF5AF2),
        opacity: 0.45,
      ),
      _Blob(
        baseX: 0.50,
        baseY: 0.70,
        radiusFactor: 0.60,
        driftX: 0.14,
        driftY: 0.09,
        phaseX: 1.0,
        phaseY: 3.3,
        speed: 0.70,
        color: const Color(0xFF007AFF),
        opacity: 0.35,
      ),
      _Blob(
        baseX: 0.15,
        baseY: 0.75,
        radiusFactor: 0.40,
        driftX: 0.09,
        driftY: 0.12,
        phaseX: 3.5,
        phaseY: 0.9,
        speed: 1.1,
        color: const Color(0xFF30D158),
        opacity: 0.25,
      ),
      _Blob(
        baseX: 0.85,
        baseY: 0.80,
        radiusFactor: 0.45,
        driftX: 0.11,
        driftY: 0.07,
        phaseX: 0.7,
        phaseY: 2.4,
        speed: 0.90,
        color: const Color(0xFFFF375F),
        opacity: 0.22,
      ),
    ];

    for (final blob in blobs) {
      final angle = t * 2 * pi * blob.speed;
      final cx = (blob.baseX + sin(angle + blob.phaseX) * blob.driftX) * w;
      final cy = (blob.baseY + cos(angle + blob.phaseY) * blob.driftY) * h;
      final radius = blob.radiusFactor * (w > h ? w : h) * 0.55;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blob.color.withOpacity(blob.opacity),
            blob.color.withOpacity(0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(cx, cy),
          radius: radius,
        ));

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}

class _Blob {
  final double baseX, baseY;
  final double radiusFactor;
  final double driftX, driftY;
  final double phaseX, phaseY;
  final double speed;
  final Color color;
  final double opacity;

  const _Blob({
    required this.baseX,
    required this.baseY,
    required this.radiusFactor,
    required this.driftX,
    required this.driftY,
    required this.phaseX,
    required this.phaseY,
    required this.speed,
    required this.color,
    required this.opacity,
  });
}
