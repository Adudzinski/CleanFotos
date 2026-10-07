import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/noir.dart';

/// Largest text scale the layouts are built and tested for (was 1.4 before
/// 1.3). Above it text stops growing rather than breaking the screens.
const double kMaxTextScale = 2.0;

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
          // Respect the user's OS text size — low-vision users rely on it.
          // Never below our design size; up to 2x (Android's largest, and
          // well into iOS's accessibility "Larger Text" range). Every screen
          // is checked at 2x: see kMaxTextScale.
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.of(context)
                    .textScaler
                    .clamp(minScaleFactor: 1.0, maxScaleFactor: kMaxTextScale)),
            child: child!,
          );
        },
      ),
    );
  }
}
