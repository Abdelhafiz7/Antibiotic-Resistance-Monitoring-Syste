import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/sensor_data.dart';
import '../services/ble_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  StreamSubscription<SensorData>? _dataSub;
  bool _lastWasRisk = false;

  final List<SensorData> _history = [];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeToData());
  }

  void _subscribeToData() {
    final ble = context.read<BleService>();
    _dataSub = ble.dataStream.listen((data) {
      setState(() {
        _history.add(data);
        if (_history.length > 20) _history.removeAt(0);
      });

      if (data.isRisk && !_lastWasRisk && mounted) {
        final lang = context.read<LanguageService>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            content: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.riskRed, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lang.translate('risk_snackbar'),
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ]),
            backgroundColor: AppTheme.riskRedBg,
          ),
        );
      }
      _lastWasRisk = data.isRisk;
    });

    ble.addListener(_checkConnection);
  }

  void _checkConnection() {
    final ble = context.read<BleService>();
    if (ble.state == BleState.disconnected && mounted) {
      final lang = context.read<LanguageService>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.translate('device_disconnected')),
          backgroundColor: AppTheme.navyPanel,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    final ble = context.read<BleService>();
    await ble.disconnect();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const ScannerScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a, child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _fadeCtrl.dispose();
    try {
      context.read<BleService>().removeListener(_checkConnection);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        CustomPaint(
          painter: GridBackgroundPainter(),
          child: Container(
            decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient),
          ),
        ),
        SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Consumer<BleService>(
              builder: (_, ble, __) {
                final connected = ble.state == BleState.connected;
                final data      = ble.latestData;
                return Column(children: [
                  _AppBar(
                    connected: connected,
                    onDisconnect: _disconnect,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppTheme.cyanBright,
                      backgroundColor: AppTheme.navyPanel,
                      onRefresh: () async {},
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: data == null
                            ? _WaitingForData(connected: connected)
                            : _DataBody(
                                data: data,
                                history: _history,
                              ),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
      ]),
    );
  }
}


class _AppBar extends StatelessWidget {
  final bool connected;
  final VoidCallback onDisconnect;

  const _AppBar({required this.connected, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(children: [
        const Icon(Icons.biotech, color: AppTheme.cyanBright, size: 24),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            lang.translate('live_monitor'),
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.white,
              letterSpacing: 2,
            ),
          ),
          Text(
            lang.translate('app_subtitle'),
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 11,
              color: AppTheme.cyanBright.withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
        ]),
        const Spacer(),
        const LanguageToggleButton(),
        const SizedBox(width: 12),
        ConnectionBadge(connected: connected),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onDisconnect,
          icon: const Icon(Icons.bluetooth_disabled, size: 22),
          color: AppTheme.whiteDim,
          tooltip: lang.translate('disconnect_tooltip'),
        ),
      ]),
    );
  }
}


class _WaitingForData extends StatefulWidget {
  final bool connected;
  const _WaitingForData({required this.connected});

  @override
  State<_WaitingForData> createState() => _WaitingForDataState();
}

class _WaitingForDataState extends State<_WaitingForData>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final ble = context.watch<BleService>();

    final hasSensorError = ble.state == BleState.error && ble.errorMessage.contains('DHT11');
    final String mainText = hasSensorError
        ? lang.translate('dht11_failed_error')
        : (widget.connected ? lang.translate('awaiting_data') : lang.translate('not_connected'));
    final String subText = hasSensorError
        ? (lang.locale == 'tr' 
            ? 'Arduino sensör hatası bildirdi. DHT11 donanım bağlantılarını kontrol edin.' 
            : 'Arduino reported sensor failure. Check your DHT11 hardware wiring.')
        : (widget.connected ? lang.translate('awaiting_data_sub') : lang.translate('not_connected_sub'));

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _ctrl,
              child: Icon(
                hasSensorError ? Icons.error_outline : Icons.radar,
                color: hasSensorError ? AppTheme.riskRed : AppTheme.cyanBright,
                size: 52,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              mainText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: hasSensorError ? AppTheme.riskRed : AppTheme.cyanBright,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 13,
                color: AppTheme.whiteDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _DataBody extends StatelessWidget {
  final SensorData data;
  final List<SensorData> history;

  const _DataBody({required this.data, required this.history});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final fmt = DateFormat('HH:mm:ss');
    final bool useTwoColumn = MediaQuery.of(context).size.width > 720 ||
        MediaQuery.of(context).orientation == Orientation.landscape;

    final Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: StatusBanner(key: ValueKey(data.isRisk), isRisk: data.isRisk),
        ),
        const SizedBox(height: 16),

        Row(children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: MetricCard(
                key: ValueKey(data.temperature.toStringAsFixed(1)),
                label: lang.translate('temperature'),
                value: data.temperature.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat_outlined,
                iconColor: data.temperature > 30
                    ? AppTheme.riskRed
                    : AppTheme.cyanBright,
                trailing: data.temperature > 30
                    ? const Icon(Icons.arrow_upward,
                        color: AppTheme.riskRed, size: 16)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: MetricCard(
                key: ValueKey(data.ldrValue),
                label: lang.translate('turbidity'),
                value: data.ldrValue.toString(),
                unit: 'ADC',
                icon: Icons.light_mode_outlined,
                iconColor: data.ldrValue < 500
                    ? AppTheme.riskOrange
                    : AppTheme.cyanBright,
                trailing: data.ldrValue < 500
                    ? const Icon(Icons.arrow_downward,
                        color: AppTheme.riskOrange, size: 16)
                    : null,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        GlowCard(
          child: LdrGaugeBar(value: data.ldrValue),
        ),
        if (history.length > 1) ...[
          const SizedBox(height: 16),
          _HistoryChart(history: history),
        ],
      ],
    );

    final Widget rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SystemStatusCard(data: data),
        const SizedBox(height: 16),

        _ConditionsCard(),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Icon(Icons.access_time,
              color: AppTheme.whiteDim, size: 14),
          const SizedBox(width: 6),
          Text(
            '${lang.translate('last_updated')}: ${fmt.format(data.timestamp)}',
            style: const TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 12,
              color: AppTheme.whiteDim,
            ),
          ),
          const Spacer(),
          PulsingDot(color: AppTheme.cyanBright, size: 7),
          const SizedBox(width: 6),
          Text(
            lang.translate('live'),
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.cyanBright,
              letterSpacing: 1,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        if (useTwoColumn)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftColumn),
              const SizedBox(width: 16),
              Expanded(child: rightColumn),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leftColumn,
              const SizedBox(height: 16),
              rightColumn,
            ],
          ),
      ],
    );
  }
}


class _SystemStatusCard extends StatelessWidget {
  final SensorData data;
  const _SystemStatusCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final color = data.isRisk ? AppTheme.riskRed : AppTheme.safeGreen;
    return GlowCard(
      glowColor: color,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          lang.translate('system_status'),
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.cyanBright,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        _StatusRow(
          label: lang.translate('temp_threshold_label'),
          pass: data.temperature <= 30,
          value: '${data.temperature.toStringAsFixed(1)} °C',
        ),
        const Divider(height: 20, color: AppTheme.gridLine),
        _StatusRow(
          label: lang.translate('ldr_threshold_label'),
          pass: data.ldrValue >= 500,
          value: '${data.ldrValue} ADC',
        ),
        const Divider(height: 20, color: AppTheme.gridLine),
        _StatusRow(
          label: lang.translate('arduino_status_flag'),
          pass: data.statusRaw != 'RISK',
          value: data.statusRaw == 'RISK'
              ? lang.translate('risk_text')
              : (data.statusRaw == 'NORMAL' ? lang.translate('safe') : data.statusRaw),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            lang.translate(data.isRisk ? 'risk_detected' : 'env_stable'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 2,
            ),
          ),
        ),
      ]),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool pass;
  final String value;

  const _StatusRow({
    required this.label,
    required this.pass,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(
      pass ? Icons.check_circle_outline : Icons.cancel_outlined,
      color: pass ? AppTheme.safeGreen : AppTheme.riskRed,
      size: 18,
    ),
    const SizedBox(width: 10),
    Expanded(
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 13,
          color: AppTheme.whiteAlpha,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    Text(
      value,
      style: TextStyle(
        fontFamily: 'ShareTechMono',
        fontSize: 13,
        color: pass ? AppTheme.safeGreen : AppTheme.riskRed,
      ),
    ),
  ]);
}


class _HistoryChart extends StatelessWidget {
  final List<SensorData> history;
  const _HistoryChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    return GlowCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          lang.translate('temp_trend'),
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.cyanBright,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 80,
          child: CustomPaint(
            painter: _SparklinePainter(history),
            size: Size.infinite,
          ),
        ),
      ]),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<SensorData> data;
  _SparklinePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final temps = data.map((d) => d.temperature).toList();
    final minT  = temps.reduce((a, b) => a < b ? a : b);
    final maxT  = temps.reduce((a, b) => a > b ? a : b);
    final range = (maxT - minT).clamp(1.0, double.infinity);

    final linePaint = Paint()
      ..color = AppTheme.cyanBright
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.cyanBright.withOpacity(0.3),
          AppTheme.cyanBright.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path     = Path();
    final areaPath = Path();
    final step     = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - ((temps[i] - minT) / range) * size.height * 0.9;
      if (i == 0) {
        path.moveTo(x, y);
        areaPath.moveTo(x, size.height);
        areaPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }
    areaPath.lineTo((data.length - 1) * step, size.height);
    areaPath.close();

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(path, linePaint);

    if (minT < 30 && maxT > 30) {
      final dangerY = size.height - ((30 - minT) / range) * size.height * 0.9;
      final dangerPaint = Paint()
        ..color = AppTheme.riskRed.withOpacity(0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final path2 = Path()
        ..moveTo(0, dangerY)
        ..lineTo(size.width, dangerY);
      canvas.drawPath(path2, dangerPaint);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.data != data;
}


class _ConditionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    return GlowCard(
      glowColor: AppTheme.whiteDim,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          lang.translate('risk_threshold_ref'),
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.whiteDim,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        _RefRow(
          icon: Icons.thermostat,
          label: lang.translate('temperature'),
          condition: '> 30 °C  →  ${lang.translate('risk')}',
          color: AppTheme.riskRed,
        ),
        const SizedBox(height: 8),
        _RefRow(
          icon: Icons.light_mode,
          label: lang.translate('ldr_value'),
          condition: '< 500 ADC  →  ${lang.translate('risk')}',
          color: AppTheme.riskOrange,
        ),
        const SizedBox(height: 8),
        _RefRow(
          icon: Icons.verified_outlined,
          label: lang.translate('both_in_range'),
          condition: lang.translate('safe_ref_message'),
          color: AppTheme.safeGreen,
        ),
      ]),
    );
  }
}

class _RefRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String condition;
  final Color color;

  const _RefRow({
    required this.icon,
    required this.label,
    required this.condition,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 16),
    const SizedBox(width: 10),
    Expanded(
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 13,
          color: AppTheme.whiteAlpha,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    Text(
      condition,
      style: TextStyle(
        fontFamily: 'Rajdhani',
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ),
  ]);
}
