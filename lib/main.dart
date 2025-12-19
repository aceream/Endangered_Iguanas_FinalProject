import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Endangered Iguanas',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final baseTheme = ThemeData(brightness: brightness);
    
    return baseTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E3932), // Deep Jungle Green
        brightness: brightness,
        primary: const Color(0xFF1E3932),
        secondary: const Color(0xFFC7F464), // Bright Lime
        tertiary: const Color(0xFFFF9F1C), // Solar Orange Accent
        surface: const Color(0xFFF4F7F6), // Soft White/Grey
        surfaceTint: const Color(0xFF1E3932),
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F7F6),
      
      // Typography
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
          textStyle: baseTheme.textTheme.displayLarge,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.poppins(
          textStyle: baseTheme.textTheme.displayMedium,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.poppins(
          textStyle: baseTheme.textTheme.displaySmall,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: GoogleFonts.poppins(
          textStyle: baseTheme.textTheme.headlineLarge,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.poppins(
          textStyle: baseTheme.textTheme.headlineMedium,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.poppins(
          textStyle: baseTheme.textTheme.headlineSmall,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.poppins(
          textStyle: baseTheme.textTheme.titleLarge,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: Colors.white,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF1E3932),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E3932)),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3932),
          foregroundColor: const Color(0xFFC7F464), // Text/Icon color
          elevation: 4,
          shadowColor: const Color(0xFF1E3932).withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFC7F464),
        foregroundColor: Color(0xFF1E3932),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}

