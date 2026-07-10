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

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize photo manager log level
  PhotoManager.setLog(false);
  // Make sure we never bypass the permission flow — doing so breaks photo
  // listing and deletion on Android.
  await PhotoManager.setIgnorePermissionCheck(false);

  runApp(const CleanPicsApp());
}

class CleanPicsApp extends StatelessWidget {
  const CleanPicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'CleanPics',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
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
