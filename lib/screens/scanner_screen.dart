import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../services/ble_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'dashboard_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onDeviceTap(BluetoothDevice device) async {
    final ble = context.read<BleService>();
    if (ble.state == BleState.connecting) return;

    if (ble.state == BleState.connected &&
        ble.connectedDevice?.remoteId == device.remoteId) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          _slideRoute(const DashboardScreen()),
        );
      }
      return;
    }

    await ble.connect(device);

    if (!mounted) return;
    if (ble.state == BleState.connected) {
      Navigator.of(context).pushReplacement(_slideRoute(const DashboardScreen()));
    } else {
      final lang = context.read<LanguageService>();
      String displayError = ble.errorMessage;
      if (displayError.isEmpty) {
        displayError = lang.translate('connection_failed');
      } else if (displayError.contains('DHT11 failed to read') || displayError.contains('DHT11')) {
        displayError = lang.translate('dht11_failed_error');
      } else if (displayError.contains('Connection failed')) {
        displayError = lang.translate('connection_failed');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayError),
          backgroundColor: AppTheme.riskRedBg,
        ),
      );
    }
  }

  Route<void> _slideRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, a, __) => page,
    transitionsBuilder: (_, a, __, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 400),
  );

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final lang = context.watch<LanguageService>();

    return Scaffold(
      body: Stack(children: [
        CustomPaint(
          painter: GridBackgroundPainter(),
          child: Container(
            decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
          ),
        ),

        SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                const SizedBox(height: 24),
                _buildHeader(lang),
                const SizedBox(height: 16),
                Expanded(
                  child: isLandscape
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    _buildScanArea(lang),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                            const VerticalDivider(color: AppTheme.gridLine, width: 1),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 6,
                              child: _buildDeviceList(lang),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildScanArea(lang),
                            const SizedBox(height: 24),
                            Expanded(
                              child: _buildDeviceList(lang),
                            ),
                          ],
                        ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader(LanguageService lang) => Column(children: [
    Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cyanBright.withOpacity(0.4)),
          color: AppTheme.cyanBright.withOpacity(0.07),
        ),
        child: const Icon(Icons.biotech, color: AppTheme.cyanBright, size: 26),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          lang.translate('app_name'),
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.white,
            letterSpacing: 2,
          ),
        ),
        Text(
          lang.translate('app_subtitle'),
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 12,
            color: AppTheme.cyanBright.withOpacity(0.7),
            letterSpacing: 1,
          ),
        ),
      ]),
      const Spacer(),
      const LanguageToggleButton(),
    ]),
    const SizedBox(height: 24),
    const Divider(color: AppTheme.gridLine),
  ]);

  Widget _buildScanArea(LanguageService lang) => Consumer<BleService>(
    builder: (_, ble, __) {
      final scanning    = ble.state == BleState.scanning;
      final connecting  = ble.state == BleState.connecting;
      final busy        = scanning || connecting;

      return Column(children: [
        if (busy) ...[
          ScannerRing(size: connecting ? 120 : 160),
          const SizedBox(height: 20),
          Text(
            scanning ? lang.translate('scanning_for_devices') : lang.translate('connecting'),
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.cyanBright,
              letterSpacing: 2,
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.bluetooth_searching, size: 20),
            label: Text(lang.translate('scan_for_devices')),
            onPressed: () => context.read<BleService>().startScan(),
          ),
          const SizedBox(height: 8),
          Text(
            lang.translate('make_sure_power'),
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 13,
              color: AppTheme.whiteDim,
            ),
          ),
        ],
      ]);
    },
  );

  Widget _buildDeviceList(LanguageService lang) => Consumer<BleService>(
    builder: (_, ble, __) {
      final results = ble.scanResults;

      if (results.isEmpty && ble.state != BleState.scanning) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bluetooth_disabled,
                  color: AppTheme.whiteDim.withOpacity(0.3), size: 48),
              const SizedBox(height: 12),
              Text(
                lang.translate('no_devices_found'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 15,
                  color: AppTheme.whiteDim,
                ),
              ),
            ],
          ),
        );
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (results.isNotEmpty) ...[
          Text(
            '${lang.translate('nearby_devices')} (${results.length})',
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.cyanBright,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _DeviceTile(
              result: results[i],
              onTap: () => _onDeviceTap(results[i].device),
              isConnecting: ble.state == BleState.connecting &&
                  ble.connectedDevice?.remoteId == results[i].device.remoteId,
            ),
          ),
        ),
      ]);
    },
  );
}


class _DeviceTile extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onTap;
  final bool isConnecting;

  const _DeviceTile({
    required this.result,
    required this.onTap,
    this.isConnecting = false,
  });

  Color get _rssiColor {
    final rssi = result.rssi;
    if (rssi >= -60) return AppTheme.safeGreen;
    if (rssi >= -80) return AppTheme.cyanBright;
    return AppTheme.whiteDim;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final rawName = result.device.platformName;
    final isHm10 = rawName.toLowerCase().contains('hm') ||
        rawName.toLowerCase().contains('ble') ||
        rawName.toLowerCase().contains('mlg');
    final displayName = rawName.isNotEmpty ? rawName : lang.translate('unknown_device');

    return GestureDetector(
      onTap: isConnecting ? null : onTap,
      child: GlowCard(
        glowColor: isHm10 ? AppTheme.cyanBright : AppTheme.whiteDim,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isHm10 ? AppTheme.cyanBright : AppTheme.whiteDim)
                  .withOpacity(0.1),
            ),
            child: Icon(
              isHm10 ? Icons.bluetooth : Icons.device_unknown,
              color: isHm10 ? AppTheme.cyanBright : AppTheme.whiteDim,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
                  ),
                ),
                if (isHm10) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppTheme.cyanBright.withOpacity(0.1),
                      border: Border.all(
                          color: AppTheme.cyanBright.withOpacity(0.4)),
                    ),
                    child: const Text(
                      'HM-10',
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.cyanBright,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Text(
                result.device.remoteId.str,
                style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 11,
                  color: AppTheme.whiteDim,
                ),
              ),
            ],
          )),
          if (isConnecting)
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.cyanBright,
              ),
            )
          else
            Column(children: [
              Icon(Icons.signal_wifi_4_bar,
                  color: _rssiColor, size: 16),
              const SizedBox(height: 2),
              Text(
                '${result.rssi} dBm',
                style: TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 10,
                  color: _rssiColor,
                ),
              ),
            ]),
        ]),
      ),
    );
  }
}
