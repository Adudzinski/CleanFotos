import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

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

  runApp(const CleanPicsApp());
}

class CleanPicsApp extends StatefulWidget {
  const CleanPicsApp({super.key});

  @override
  State<CleanPicsApp> createState() => _CleanPicsAppState();
}

class _CleanPicsAppState extends State<CleanPicsApp>
    with WidgetsBindingObserver {
  late final AppProvider _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _provider = AppProvider()..init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // System light/dark switch: make screens re-read the AppTheme palette.
    _provider.refreshTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final platformDark =
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark;
          final dark = switch (provider.themePref) {
            'dark' => true,
            'light' => false,
            _ => platformDark,
          };

          // Screens read colors via AppTheme getters; set the mode before
          // they build.
          AppTheme.isDark = dark;

          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                dark ? Brightness.light : Brightness.dark,
          ));

          return MaterialApp(
            title: 'CleanFotos',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: switch (provider.themePref) {
              'dark' => ThemeMode.dark,
              'light' => ThemeMode.light,
              _ => ThemeMode.system,
            },
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
          );
        },
      ),
    );
  }
}
