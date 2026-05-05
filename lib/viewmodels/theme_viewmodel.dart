import 'package:flutter/foundation.dart';
import '../theme/app_colors.dart';

class ThemeViewModel extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeViewModel() {
    AppColors.isDark = _isDarkMode;
  }

  void toggle() {
    _isDarkMode = !_isDarkMode;
    AppColors.isDark = _isDarkMode;
    notifyListeners();
  }
}
