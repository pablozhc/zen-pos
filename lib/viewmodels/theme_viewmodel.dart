import 'package:flutter/foundation.dart';
import '../theme/app_colors.dart';

class ThemeViewModel extends ChangeNotifier {
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  void toggle() {
    _isDarkMode = !_isDarkMode;
    AppColors.isDark = _isDarkMode;
    notifyListeners();
  }
}
