import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/admin_login_screen.dart';
import 'theme/app_colors.dart';
import 'viewmodels/tables_viewmodel.dart';
import 'viewmodels/products_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'services/printer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppColors.isDark = false; // Admin always light
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ZenPOSAdmin());
}

class ZenPOSAdmin extends StatelessWidget {
  const ZenPOSAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => TablesViewModel()),
        ChangeNotifierProvider(create: (_) => ProductsViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => PrinterService()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVM, _) {
          AppColors.isDark = themeVM.isDarkMode;
          final base = GoogleFonts.interTextTheme(ThemeData.light().textTheme);
          return MaterialApp(
            title: 'Zen POS – Admin',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              textTheme: base,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
                primary: AppColors.primary,
                secondary: AppColors.primaryLight,
                surface: const Color(0xFFFFFFFF),
                error: AppColors.error,
              ),
              scaffoldBackgroundColor: const Color(0xFFFAF8F5),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: GoogleFonts.inter(color: const Color(0xFF1A0F0A), fontSize: 17, fontWeight: FontWeight.w600),
                iconTheme: const IconThemeData(color: Color(0xFF1A0F0A)),
              ),
              dividerTheme: const DividerThemeData(
                color: Color(0xFFEDE9E3),
                thickness: 0.5,
                space: 1,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  side: BorderSide(color: const Color(0xFFEDE9E3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFFF3F0EB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                hintStyle: GoogleFonts.inter(color: const Color(0xFF9A8F85), fontSize: 15),
                isDense: true,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 24,
                shadowColor: Colors.black.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1A0F0A)),
              ),
              snackBarTheme: SnackBarThemeData(
                backgroundColor: const Color(0xFF1A0F0A),
                contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              tabBarTheme: TabBarThemeData(
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF9A8F85),
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
                dividerColor: const Color(0xFFEDE9E3),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: const Color(0xFFF3F0EB),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                labelStyle: GoogleFonts.inter(fontSize: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                side: BorderSide.none,
              ),
              switchTheme: SwitchThemeData(
                thumbColor: WidgetStateProperty.all(Colors.white),
                trackColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected) ? AppColors.primary : const Color(0xFFDDD8D0)),
              ),
            ),
            home: const AdminLoginScreen(),
          );
        },
      ),
    );
  }
}
