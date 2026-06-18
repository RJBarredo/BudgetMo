import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Legacy constant kept for screens not yet migrated to the palette.
const Color kAppBg = Color(0xFFF5F7F5);

/// A gradient app bar matching the Home hero, themed via the active palette.
PreferredSizeWidget appHeader(BuildContext context, String title,
    {List<Widget>? actions}) {
  final p = AppPalette.of(context);
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.grad1, p.grad2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
  );
}

/// Centers content in a phone-width column so it looks right on wide screens.
Widget phoneWrap(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: child,
      ),
    );
