import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/kiosk_login_screen.dart';
import 'theme/app_colors.dart';
import 'viewmodels/tables_viewmodel.dart';
import 'viewmodels/products_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'services/printer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppColors.isDark = false;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF2F2F7),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ZenPOSApp());
}

class ZenPOSApp extends StatelessWidget {
  const ZenPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => TablesViewModel()),
        ChangeNotifierProvider(create: (_) => ProductsViewModel()),
        ChangeNotifierProvider(create: (_) => PrinterService()),
      ],
      child: MaterialApp(
        title: 'Zen POS',
        debugShowCheckedModeBanner: false,
        theme: _buildIOSTheme(),
        home: const KioskLoginScreen(),
      ),
    );
  }

  ThemeData _buildIOSTheme() {
    const iosBackground = Color(0xFFF2F2F7);
    const iosCard = Color(0xFFFFFFFF);
    const iosBorder = Color(0xFFC6C6C8);
    const iosLabel = Color(0xFF1C1C1E);
    const iosSecondaryLabel = Color(0xFF8E8E93);

    return ThemeData(
      useMaterial3: true,
      fontFamily: '.SF Pro Text', // native SF Pro on iOS/macOS
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: iosCard,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: iosBackground,

      // Cards — iOS grouped style
      cardTheme: CardThemeData(
        color: iosCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),

      // AppBar — iOS navigation bar style
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF2F2F7),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: '.SF Pro Text',
          color: iosLabel,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
        ),
        iconTheme: IconThemeData(color: AppColors.primary),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: iosBorder,
        thickness: 0.5,
        space: 0,
      ),

      // Buttons — iOS rounded
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
          minimumSize: const Size(0, 50),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      // Input — iOS style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: iosCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: iosBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: iosBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(
          fontFamily: '.SF Pro Text',
          color: iosSecondaryLabel,
          fontSize: 17,
        ),
      ),

      // Dialog — iOS alert style
      dialogTheme: DialogThemeData(
        backgroundColor: iosCard,
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: iosLabel,
          letterSpacing: -0.41,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: iosLabel,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1C1C1E),
        contentTextStyle: const TextStyle(
          fontFamily: '.SF Pro Text',
          color: Colors.white,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),

      // Switch — iOS style
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : const Color(0xFFE5E5EA)),
      ),
    );
  }
}
