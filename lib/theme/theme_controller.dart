import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A selectable accent identity: the highlight color plus the dark hero
/// gradient used at the top of the Home dashboard.
class AccentPreset {
  final String name;
  final Color accent;
  final List<Color> heroGrad;
  const AccentPreset(this.name, this.accent, this.heroGrad);
}

const List<AccentPreset> kAccents = [
  AccentPreset('Forest', Color(0xFF2ECC71), [Color(0xFF12280F), Color(0xFF2D5A2D)]),
  AccentPreset('Ocean', Color(0xFF3498DB), [Color(0xFF0C1E33), Color(0xFF1E4A6B)]),
  AccentPreset('Sunset', Color(0xFFF39C12), [Color(0xFF3A2408), Color(0xFF7A4E12)]),
  AccentPreset('Grape', Color(0xFF9B59B6), [Color(0xFF241038), Color(0xFF4A2D6B)]),
  AccentPreset('Rose', Color(0xFFE74C3C), [Color(0xFF330F0C), Color(0xFF6B1E1A)]),
  AccentPreset('Slate', Color(0xFF5D7891), [Color(0xFF161D24), Color(0xFF31414F)]),
];

class ThemeController extends ChangeNotifier {
  int _accentIndex = 0;
  bool _dark = false;

  int get accentIndex => _accentIndex;
  bool get dark => _dark;
  AccentPreset get preset =>
      kAccents[_accentIndex.clamp(0, kAccents.length - 1)];

  void load() {
    try {
      final box = Hive.box('budget');
      _accentIndex = (box.get('themeAccent', defaultValue: 0) as num).toInt();
      _dark = box.get('themeDark', defaultValue: false) as bool;
    } catch (_) {
      _accentIndex = 0;
      _dark = false;
    }
  }

  void setAccent(int i) {
    _accentIndex = i;
    Hive.box('budget').put('themeAccent', i);
    notifyListeners();
  }

  void setDark(bool v) {
    _dark = v;
    Hive.box('budget').put('themeDark', v);
    notifyListeners();
  }
}

final ThemeController themeController = ThemeController();

// ── Context-free palette getters (read live theme state) ────────────────────
Color get cAccent => themeController.preset.accent;
List<Color> get cHeroGrad => themeController.preset.heroGrad;
Color get cBg =>
    themeController.dark ? const Color(0xFF0E140E) : const Color(0xFFF5F7F5);
Color get cSurface =>
    themeController.dark ? const Color(0xFF18211A) : Colors.white;
Color get cInk =>
    themeController.dark ? const Color(0xFFEAF2EA) : const Color(0xFF1A2E1A);
Color get cSubtext =>
    themeController.dark ? Colors.white70 : Colors.black45;
Color get cFaint =>
    themeController.dark ? Colors.white38 : Colors.black38;
Color get cHairline => themeController.dark
    ? Colors.white.withOpacity(0.08)
    : const Color(0xFF1A2E1A).withOpacity(0.06);

ThemeData buildAppTheme() {
  final dark = themeController.dark;
  final accent = themeController.preset.accent;
  final base = dark ? ThemeData.dark() : ThemeData.light();
  final scheme = (dark ? const ColorScheme.dark() : const ColorScheme.light())
      .copyWith(
    primary: accent,
    secondary: accent,
    surface: cSurface,
  );
  return base.copyWith(
    useMaterial3: true,
    scaffoldBackgroundColor: cBg,
    canvasColor: cBg,
    cardColor: cSurface,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: cBg,
      foregroundColor: cInk,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    iconTheme: IconThemeData(color: cInk),
    dividerColor: cHairline,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: cInk, displayColor: cInk),
  );
}
