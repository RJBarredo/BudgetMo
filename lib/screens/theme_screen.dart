import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_controller.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        foregroundColor: cInk,
        title: Text('Appearance',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, color: cInk)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          // Live preview
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: cHeroGrad,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                    color: cAccent, borderRadius: BorderRadius.circular(30)),
                child: Text('Preview',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Accent',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800, color: cInk)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(kAccents.length, (i) {
              final p = kAccents[i];
              final selected = themeController.accentIndex == i;
              return GestureDetector(
                onTap: () {
                  themeController.setAccent(i);
                  setState(() {});
                },
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: cSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: selected ? p.accent : cHairline,
                        width: selected ? 2 : 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: p.accent, shape: BoxShape.circle),
                        child: selected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(p.name,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: cInk)),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
                color: cSurface, borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: cAccent,
              title: Text('Dark mode',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, color: cInk)),
              subtitle: Text('Easier on the eyes at night',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5, color: cSubtext)),
              value: themeController.dark,
              onChanged: (v) {
                themeController.setDark(v);
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Dark mode currently styles the Home dashboard and navigation. '
            'Other screens are being rolled over to it.',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: cSubtext, height: 1.4),
          ),
        ],
      ),
    );
  }
}
