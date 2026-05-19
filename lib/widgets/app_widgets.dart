import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';


class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulsingDot({super.key, required this.color, this.size = 10});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale   = Tween(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _opacity = Tween(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Opacity(
      opacity: _opacity.value,
      child: Transform.scale(
        scale: _scale.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [BoxShadow(color: widget.color.withOpacity(0.6), blurRadius: 8)],
          ),
        ),
      ),
    ),
  );
}

// ── Glowing border card 

class GlowCard extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;

  const GlowCard({
    super.key,
    required this.child,
    this.glowColor = AppTheme.cyanBright,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(16);
    return Container(
      decoration: BoxDecoration(
        borderRadius: br,
        color: AppTheme.navyPanel,
        border: Border.all(color: glowColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

// ── Metric chip (Temperature / LDR) 

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.iconColor = AppTheme.cyanBright,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => GlowCard(
    glowColor: iconColor,
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: iconColor,
              letterSpacing: 1.5,
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ]),
        const SizedBox(height: 14),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 36,
                color: AppTheme.white,
                height: 1,
              ),
            ),
            TextSpan(
              text: ' $unit',
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 16,
                color: AppTheme.whiteDim,
                fontWeight: FontWeight.w500,
              ),
            ),
          ]),
        ),
      ],
    ),
  );
}

// ── Status banner (SAFE / RISK) 

class StatusBanner extends StatefulWidget {
  final bool isRisk;
  const StatusBanner({super.key, required this.isRisk});

  @override
  State<StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends State<StatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isRisk) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StatusBanner old) {
    super.didUpdateWidget(old);
    if (widget.isRisk != old.isRisk) {
      if (widget.isRisk) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.stop();
        _ctrl.value = 1.0;
      }
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final color  = widget.isRisk ? AppTheme.riskRed  : AppTheme.safeGreen;
    final bgColor= widget.isRisk ? AppTheme.riskRedBg : AppTheme.safeGreenBg;
    final icon   = widget.isRisk ? Icons.warning_amber_rounded : Icons.verified_outlined;
    final title  = widget.isRisk ? lang.translate('risk_detected') : lang.translate('env_stable');
    final sub    = widget.isRisk
        ? lang.translate('risk_message')
        : lang.translate('safe_message');

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: widget.isRisk ? _opacity.value : 1.0,
        child: child,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: bgColor,
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.15), blurRadius: 24, spreadRadius: 2),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 13,
                  color: AppTheme.whiteAlpha,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )),
        ]),
      ),
    );
  }
}

// ── Animated scanner ring (used on scan page)

class ScannerRing extends StatefulWidget {
  final double size;
  const ScannerRing({super.key, this.size = 160});

  @override
  State<ScannerRing> createState() => _ScannerRingState();
}

class _ScannerRingState extends State<ScannerRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.size,
    height: widget.size,
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _ScannerPainter(_ctrl.value),
        child: Center(
          child: Container(
            width: widget.size * 0.45,
            height: widget.size * 0.45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.navyPanel,
              border: Border.all(color: AppTheme.cyanBright.withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.bluetooth_searching,
                color: AppTheme.cyanBright, size: 32),
          ),
        ),
      ),
    ),
  );
}

class _ScannerPainter extends CustomPainter {
  final double progress;
  _ScannerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR   = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final wave   = ((progress + i * 0.33) % 1.0);
      final radius = wave * maxR;
      final opacity= (1.0 - wave) * 0.5;
      final paint  = Paint()
        ..color  = AppTheme.cyanBright.withOpacity(opacity)
        ..style  = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, paint);
    }

    // Sweep line
    final sweepAngle = progress * 2 * math.pi;
    final rect = Rect.fromCircle(center: center, radius: maxR * 0.9);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [Colors.transparent, AppTheme.cyanBright.withOpacity(0.3)],
        startAngle: sweepAngle - 0.8,
        endAngle: sweepAngle,
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawArc(rect, sweepAngle - 0.8, 0.8, true, sweepPaint);
  }

  @override
  bool shouldRepaint(_ScannerPainter old) => old.progress != progress;
}

// ── LDR visual gauge bar

class LdrGaugeBar extends StatelessWidget {
  final int value; // 0–1023
  const LdrGaugeBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final ratio    = (value / 1023.0).clamp(0.0, 1.0);
    final isSafe   = value >= 500;
    final barColor = isSafe ? AppTheme.safeGreen : AppTheme.riskRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            lang.translate('light_level'),
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteDim,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Text(
            value >= 500 ? lang.translate('sufficient') : lang.translate('low'),
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: barColor,
              letterSpacing: 1,
            ),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppTheme.navyMid,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
        const SizedBox(height: 4),
        Row(children: [
          Text('0', style: _axisStyle),
          const Spacer(),
          Text('500', style: _axisStyle),
          const Spacer(),
          Text('1023', style: _axisStyle),
        ]),
      ],
    );
  }

  static const _axisStyle = TextStyle(
    fontFamily: 'ShareTechMono',
    fontSize: 10,
    color: AppTheme.whiteDim,
  );
}

// ── Connection state badge 

class ConnectionBadge extends StatelessWidget {
  final bool connected;
  const ConnectionBadge({super.key, required this.connected});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: (connected ? AppTheme.safeGreen : AppTheme.whiteDim).withOpacity(0.12),
        border: Border.all(
          color: (connected ? AppTheme.safeGreen : AppTheme.whiteDim).withOpacity(0.4),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        PulsingDot(
          color: connected ? AppTheme.safeGreen : AppTheme.whiteDim,
          size: 7,
        ),
        const SizedBox(width: 6),
        Text(
          connected ? lang.translate('connected') : lang.translate('offline'),
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: connected ? AppTheme.safeGreen : AppTheme.whiteDim,
            letterSpacing: 1.2,
          ),
        ),
      ]),
    );
  }
}

// ── Grid background painter

class GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.gridLine
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridBackgroundPainter _) => false;
}

// ── Language toggle button

class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final isEn = lang.locale == 'en';

    return GestureDetector(
      onTap: lang.toggleLanguage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cyanBright.withOpacity(0.3)),
          color: AppTheme.navyPanel,
          boxShadow: [
            BoxShadow(
              color: AppTheme.cyanBright.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 14, color: AppTheme.cyanBright),
            const SizedBox(width: 6),
            Text(
              isEn ? 'EN' : 'TR',
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

