import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'providers/data_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/questions_provider.dart';
import 'providers/deneme_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/note_images_provider.dart';
import 'services/ad_service.dart';
import 'services/timer_foreground_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FlutterForegroundTask başlangıç konfigürasyonu
  TimerForegroundService.init();
  // Arka plan isolate ile iletişim portunu başlat
  FlutterForegroundTask.initCommunicationPort();

  // Android durum çubuğunu şeffaf yap
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Dikey mod (portrait) kilitle
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => QuestionsProvider()),
        ChangeNotifierProvider(create: (_) => DenemeProvider()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(create: (_) => NoteImagesProvider()),
      ],
      child: const DgsRehberiApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(AdService.instance.initialize());
  });
}

class DgsRehberiApp extends StatelessWidget {
  const DgsRehberiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return WithForegroundTask(
      child: MaterialApp(
        title: 'DGS Rehberi',
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.themeMode,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF7F7F8),
          primaryColor: const Color(0xFF7F5AF0),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7F5AF0),
            brightness: Brightness.light,
            primary: const Color(0xFF7F5AF0),
            secondary: const Color(0xFF2CB67D),
            surface: Colors.white,
          ),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.light().textTheme.apply(
                  bodyColor: const Color(0xFF16161A),
                  displayColor: const Color(0xFF16161A),
                ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF7F5AF0).withValues(alpha: 0.15),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7F5AF0),
                );
              }
              return GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF16161A).withValues(alpha: 0.5),
              );
            }),
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F0E17),
          primaryColor: const Color(0xFF7F5AF0),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7F5AF0),
            brightness: Brightness.dark,
            primary: const Color(0xFF7F5AF0),
            secondary: const Color(0xFF2CB67D),
            surface: const Color(0xFF16161A),
          ),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.dark().textTheme.apply(
                  bodyColor: const Color(0xFFFFFFFE),
                  displayColor: const Color(0xFFFFFFFE),
                ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFF0D0B15),
            indicatorColor: const Color(0xFF7F5AF0).withValues(alpha: 0.2),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7F5AF0),
                );
              }
              return GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.4),
              );
            }),
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
