import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ads (non-fatal if it fails)
  try {
    await AdService.instance.init();
  } catch (_) {}

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize photo manager log level
  PhotoManager.setLog(false);

  runApp(const CleanFotosApp());
}

class CleanFotosApp extends StatelessWidget {
  const CleanFotosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'CleanFotos',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
            builder: (context, child) {
              // Ensure font scaling doesn't break layout
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: MediaQuery.of(context)
                        .textScaler
                        .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.2)),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
