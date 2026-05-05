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
              scaffoldBackgroundColor: const Color(0xFFF2F2F7),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE5E5EA), width: 1),
                ),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: GoogleFonts.inter(
                  color: const Color(0xFF1C1C1E),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                iconTheme:
                    const IconThemeData(color: Color(0xFF1C1C1E)),
              ),
              dividerTheme: const DividerThemeData(
                color: Color(0xFFE5E5EA),
                thickness: 1,
                space: 1,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: Color(0xFFE5E5EA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                fillColor: const Color(0xFFF2F2F7),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF8E8E93), fontSize: 15),
                isDense: true,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 8,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                titleTextStyle: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C1C1E),
                ),
              ),
              snackBarTheme: SnackBarThemeData(
                backgroundColor: const Color(0xFF1C1C1E),
                contentTextStyle: GoogleFonts.inter(
                    color: Colors.white, fontSize: 14),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              tabBarTheme: TabBarThemeData(
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF8E8E93),
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    GoogleFonts.inter(fontSize: 14),
                dividerColor: const Color(0xFFE5E5EA),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: const Color(0xFFF2F2F7),
                selectedColor:
                    AppColors.primary.withValues(alpha: 0.15),
                labelStyle: GoogleFonts.inter(fontSize: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                side: BorderSide.none,
              ),
              switchTheme: SwitchThemeData(
                thumbColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? Colors.white
                        : Colors.white),
                trackColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? AppColors.primary
                        : const Color(0xFFE5E5EA)),
              ),
            ),
            home: const AdminLoginScreen(),
          );
        },
      ),
    );
  }
}
