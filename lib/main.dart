import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/scanner_screen.dart';
import 'services/ble_service.dart';
import 'services/language_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.navyDeep,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const AntibioticMonitorApp());
}

class AntibioticMonitorApp extends StatelessWidget {
  const AntibioticMonitorApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BleService()),
          ChangeNotifierProvider(create: (_) => LanguageService()),
        ],
        child: Consumer<LanguageService>(
          builder: (context, lang, _) => MaterialApp(
            title: lang.translate('title'),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            home: const ScannerScreen(),
          ),
        ),
      );
}
