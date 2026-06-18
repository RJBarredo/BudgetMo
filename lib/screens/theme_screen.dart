import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        final p = AppPalette.of(context);
        return Scaffold(
          backgroundColor: p.bg,
          appBar: appHeader(context, 'Appearance'),
          body: phoneWrap(ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
            children: [
              // Live preview
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [p.grad1, p.grad2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Preview',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70, fontSize: 12)),
                    Text('₱1,250 left this week',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: p.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Accent',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('Theme',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: p.ink)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: List.generate(kThemePresets.length, (i) {
                  final preset = kThemePresets[i];
                  final selected = themeController.presetIndex == i;
                  return GestureDetector(
                    onTap: () => themeController.setPreset(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? preset.accent
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6)
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [preset.grad1, preset.grad2],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                    color: preset.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white,
                                        width: 2)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(preset.name,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: p.ink)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 22),
              Container(
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  activeColor: p.accent,
                  title: Text('Dark mode',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: p.ink)),
                  subtitle: Text(
                      'Rolling out across screens — core screens supported',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5, color: p.subtext)),
                  value: themeController.isDark,
                  onChanged: (v) => themeController.setDark(v),
                ),
              ),
            ],
          )),
        );
      },
    );
  }
}
