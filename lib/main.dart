import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/noir.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ads are initialized later (with the consent flow) by AppProvider, and only
  // when the user isn't Pro — see AppProvider.init().

  // Initialize local notifications (non-fatal if it fails)
  try {
    await NotificationService.instance.init();
  } catch (_) {}

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize photo manager log level
  PhotoManager.setLog(false);
  // Make sure we never bypass the permission flow — doing so breaks photo
  // listing and deletion on Android.
  await PhotoManager.setIgnorePermissionCheck(false);

  runApp(const CleanFotosApp());
}

class CleanFotosApp extends StatefulWidget {
  const CleanFotosApp({super.key});

  @override
  State<CleanFotosApp> createState() => _CleanFotosAppState();
}

class _CleanFotosAppState extends State<CleanFotosApp> {
  late final AppProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = AppProvider()..init();
    // Noir is dark-only: light status-bar icons everywhere.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Android
      statusBarBrightness: Brightness.dark, // iOS
      systemNavigationBarColor: Noir.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: MaterialApp(
        title: 'CleanFotos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.noirTheme,
        darkTheme: AppTheme.noirTheme,
        // Dark-only since 1.3 (Noir). The old theme_pref key is simply ignored.
        themeMode: ThemeMode.dark,
        home: const HomeScreen(),
        builder: (context, child) {
          // Respect the user's OS font-size setting (helps low-vision
          // users), but never shrink below our design and cap the max so
          // layouts don't break.
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.of(context)
                    .textScaler
                    .clamp(minScaleFactor: 1.0, maxScaleFactor: 1.4)),
            child: child!,
          );
        },
      ),
    );
  }
}
