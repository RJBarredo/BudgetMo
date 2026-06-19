import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_controller.dart';

Color get kAppBg => cBg;

PreferredSizeWidget appHeader(BuildContext context, String title,
    {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: Colors.white,
    centerTitle: false,
    title: Text(
      title,
      style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white),
    ),
    actions: actions,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF12280F), Color(0xFF2D5A2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
  );
}

Widget phoneWrap(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: child,
      ),
    );
