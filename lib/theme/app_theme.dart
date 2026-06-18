import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemePreset {
  final String name;
  final Color accent;
  final Color grad1;
  final Color grad2;
  const ThemePreset(this.name, this.accent, this.grad1, this.grad2);
}

const List<ThemePreset> kThemePresets = [
  ThemePreset('Honey', Color(0xFFE8920C), Color(0xFFE8920C), Color(0xFFF6B23E)),
  ThemePreset('Forest', Color(0xFF2ECC71), Color(0xFF1E5631), Color(0xFF2ECC71)),
  ThemePreset('Ocean', Color(0xFF2E86DE), Color(0xFF0A2540), Color(0xFF2E86DE)),
  ThemePreset('Sunset', Color(0xFFE67E22), Color(0xFF7A2E0E), Color(0xFFF39C12)),
  ThemePreset('Grape', Color(0xFF8E44AD), Color(0xFF2C1338), Color(0xFF9B59B6)),
  ThemePreset('Rose', Color(0xFFE84393), Color(0xFF4A1130), Color(0xFFFF6B9D)),
  ThemePreset('Slate', Color(0xFF1ABC9C), Color(0xFF1C2B2A), Color(0xFF16A085)),
];

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color accent;
  final Color grad1;
  final Color grad2;
  final Color bg;
  final Color surface;
  final Color ink;
  final Color subtext;

  const AppPalette({
    required this.accent,
    required this.grad1,
    required this.grad2,
    required this.bg,
    required this.surface,
    required this.ink,
    required this.subtext,
  });

  @override
  AppPalette copyWith({
    Color? accent,
    Color? grad1,
    Color? grad2,
    Color? bg,
    Color? surface,
    Color? ink,
    Color? subtext,
  }) =>
      AppPalette(
        accent: accent ?? this.accent,
        grad1: grad1 ?? this.grad1,
        grad2: grad2 ?? this.grad2,
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        ink: ink ?? this.ink,
        subtext: subtext ?? this.subtext,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      accent: Color.lerp(accent, other.accent, t)!,
      grad1: Color.lerp(grad1, other.grad1, t)!,
      grad2: Color.lerp(grad2, other.grad2, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      subtext: Color.lerp(subtext, other.subtext, t)!,
    );
  }

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ??
      build(kThemePresets.first, false);

  static AppPalette build(ThemePreset p, bool dark) => AppPalette(
        accent: p.accent,
        grad1: p.grad1,
        grad2: p.grad2,
        bg: dark ? const Color(0xFF0F1310) : const Color(0xFFF3ECDD),
        surface: dark ? const Color(0xFF1A211B) : Colors.white,
        ink: dark ? const Color(0xFFF1F5F1) : const Color(0xFF3D3528),
        subtext: dark ? const Color(0xFF9DB0A2) : const Color(0xFF9A8F7D),
      );
}

ThemeData buildAppTheme(ThemePreset preset, bool dark) {
  final palette = AppPalette.build(preset, dark);
  final scheme = ColorScheme.fromSeed(
    seedColor: preset.accent,
    brightness: dark ? Brightness.dark : Brightness.light,
  );
  final base = dark ? ThemeData.dark() : ThemeData.light();
  return base.copyWith(
    colorScheme: scheme.copyWith(
      surface: palette.surface,
      primary: preset.accent,
    ),
    scaffoldBackgroundColor: palette.bg,
    cardColor: palette.surface,
    canvasColor: palette.bg,
    extensions: [palette],
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: palette.ink, displayColor: palette.ink),
    bottomSheetTheme:
        BottomSheetThemeData(backgroundColor: palette.surface),
    dialogTheme: DialogThemeData(backgroundColor: palette.surface),
    snackBarTheme: SnackBarThemeData(backgroundColor: preset.accent),
  );
}

class ThemeController extends ChangeNotifier {
  int _presetIndex = 0;
  bool _dark = false;

  int get presetIndex => _presetIndex;
  bool get isDark => _dark;
  ThemePreset get preset => kThemePresets[_presetIndex];

  void load() {
    try {
      final box = Hive.box('meta');
      _presetIndex = (box.get('themePreset', defaultValue: 0) as int)
          .clamp(0, kThemePresets.length - 1);
      _dark = box.get('themeDark', defaultValue: false) as bool;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setPreset(int index) async {
    _presetIndex = index;
    notifyListeners();
    try {
      await Hive.box('meta').put('themePreset', index);
    } catch (_) {}
  }

  Future<void> setDark(bool dark) async {
    _dark = dark;
    notifyListeners();
    try {
      await Hive.box('meta').put('themeDark', dark);
    } catch (_) {}
  }
}

final themeController = ThemeController();

// Context-free color getters (read the global controller), for helper
// methods that don't receive a BuildContext.
AppPalette get _live =>
    AppPalette.build(themeController.preset, themeController.isDark);
Color get cAccent => themeController.preset.accent;
Color get cGrad1 => themeController.preset.grad1;
Color get cGrad2 => themeController.preset.grad2;
Color get cBg => _live.bg;
Color get cSurface => _live.surface;
Color get cInk => _live.ink;
Color get cSubtext => _live.subtext;
