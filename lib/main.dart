import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Diagnostic: show the real error on screen instead of a blank page.
  ErrorWidget.builder = (FlutterErrorDetails details) => Material(
        color: const Color(0xFFFFEBEE),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Text(
                'BudgetMo error:\n\n${details.exception}\n\n${details.stack}',
                style: const TextStyle(
                    color: Color(0xFFB71C1C), fontSize: 12, height: 1.4),
              ),
            ),
          ),
        ),
      );

  await StorageService.init();
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
    return MaterialApp(
      title: 'BudgetMo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2ECC71)),
        scaffoldBackgroundColor: const Color(0xFFF5F7F5),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}
