import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  themeController.load();
  await NotificationService.init();
  if (StorageService.getReminderEnabled()) {
    await NotificationService.scheduleDaily(
        StorageService.getReminderHour(),
        StorageService.getReminderMinute());
  }
  runApp(const BudgetTrackerApp());
}

class BudgetTrackerApp extends StatelessWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'BudgetMo',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(themeController.preset, false),
          darkTheme: buildAppTheme(themeController.preset, true),
          themeMode:
              themeController.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}
