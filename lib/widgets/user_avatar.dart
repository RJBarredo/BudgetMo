import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';

enum AvatarFace { smile, grin, wink, star, calm, cool }
enum AvatarAccessory { none, sunglasses, glasses, headphones, cap }

class AvatarSpec {
  final String id;
  final Color bg1;
  final Color bg2;
  final Color skin;
  final AvatarFace face;
  final AvatarAccessory accessory;
  const AvatarSpec(
      this.id, this.bg1, this.bg2, this.skin, this.face, this.accessory);
}

class UserAvatars {
  static const List<AvatarSpec> all = [
    AvatarSpec('cool', Color(0xFF36D1DC), Color(0xFF5B86E5),
        Color(0xFFF2C79B), AvatarFace.cool, AvatarAccessory.sunglasses),
    AvatarSpec('sunny', Color(0xFFF7971E), Color(0xFFFFD200),
        Color(0xFFE8B98A), AvatarFace.grin, AvatarAccessory.none),
    AvatarSpec('mint', Color(0xFF11998E), Color(0xFF38EF7D),
        Color(0xFFF2C79B), AvatarFace.smile, AvatarAccessory.none),
    AvatarSpec('star', Color(0xFFDA22FF), Color(0xFF9733EE),
        Color(0xFFEEC1A2), AvatarFace.star, AvatarAccessory.none),
    AvatarSpec('chill', Color(0xFFFF6A88), Color(0xFFFF99AC),
        Color(0xFFE8B98A), AvatarFace.calm, AvatarAccessory.headphones),
    AvatarSpec('nerd', Color(0xFF2193B0), Color(0xFF6DD5ED),
        Color(0xFFF2C79B), AvatarFace.smile, AvatarAccessory.glasses),
    AvatarSpec('cap', Color(0xFF1A2E1A), Color(0xFF2ECC71),
        Color(0xFFE8B98A), AvatarFace.smile, AvatarAccessory.cap),
    AvatarSpec('wink', Color(0xFFF953C6), Color(0xFFB91D73),
        Color(0xFFEEC1A2), AvatarFace.wink, AvatarAccessory.none),
  ];

  static AvatarSpec? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  static const String defaultId = 'cool';
  static const String customId = 'custom';
}

/// Renders a user's avatar: a custom uploaded photo, a built-in 3D character,
/// or (legacy) an emoji fallback.
class UserAvatar extends StatelessWidget {
  final String id;
  final double size;
  const UserAvatar({super.key, required this.id, this.size = 46});

  @override
  Widget build(BuildContext context) {
    // Custom uploaded photo
    if (id == UserAvatars.customId) {
      final b64 = StorageService.getAvatarImage();
      if (b64 != null && b64.isNotEmpty) {
        try {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.30),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: size * 0.12,
                    offset: Offset(0, size * 0.06)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.30),
              child: Image.memory(
                base64Decode(b64),
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
          );
        } catch (_) {/* fall through */}
      }
    }

    final spec = UserAvatars.byId(id);
    if (spec == null) {
      // Legacy emoji or unknown — show it in a neutral rounded tile.
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF2ECC71).withOpacity(0.12),
          borderRadius: BorderRadius.circular(size * 0.30),
        ),
        child: Text(id, style: TextStyle(fontSize: size * 0.5)),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AvatarPainter(spec)),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final AvatarSpec s;
  _AvatarPainter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final rect = Offset.zero & size;
    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(w * 0.30));

    // soft drop shadow behind the whole tile (depth)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          rect.translate(0, w * 0.04), Radius.circular(w * 0.30)),
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, w * 0.05),
    );

    // gradient background
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          colors: [s.bg1, s.bg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    canvas.save();
    canvas.clipRRect(rrect);

    // top sheen + bottom vignette for a glossy, rounded feel
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.22),
            Colors.white.withOpacity(0.0),
            Colors.black.withOpacity(0.16),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect),
    );

    final cx = w / 2;
    final headCy = w * 0.52;
    final headR = w * 0.30;
    const ink = Color(0xFF3A2A1E);

    final lightSkin = Color.lerp(s.skin, Colors.white, 0.40)!;
    final darkSkin = Color.lerp(s.skin, Colors.black, 0.30)!;

    // contact shadow under the head/shoulders
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, w * 0.92),
          width: w * 0.78,
          height: w * 0.30),
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.03),
    );

    // shoulders (rounded, sphere-shaded)
    final shoulderRect =
        Rect.fromCircle(center: Offset(cx, w * 1.18), radius: w * 0.46);
    canvas.drawCircle(
      Offset(cx, w * 1.18),
      w * 0.46,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.6),
          radius: 1.0,
          colors: [lightSkin, s.skin, darkSkin],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(shoulderRect),
    );

    // ears
    canvas.drawCircle(
        Offset(cx - headR, headCy), w * 0.045, Paint()..color = s.skin);
    canvas.drawCircle(
        Offset(cx + headR, headCy), w * 0.045, Paint()..color = s.skin);

    // head as a shaded sphere
    final headRect = Rect.fromCircle(center: Offset(cx, headCy), radius: headR);
    canvas.drawCircle(
      Offset(cx, headCy),
      headR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.5),
          radius: 0.95,
          colors: [lightSkin, s.skin, darkSkin],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(headRect),
    );

    // specular highlight (the "3D" glint)
    canvas.drawCircle(
      Offset(cx - headR * 0.42, headCy - headR * 0.5),
      headR * 0.26,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.02),
    );

    final eyeY = headCy - w * 0.02;
    final eyeDx = w * 0.115;

    // cheeks
    final cheek = Paint()..color = const Color(0xFFFF8A80).withOpacity(0.5);
    canvas.drawCircle(
        Offset(cx - eyeDx * 1.3, headCy + w * 0.10), w * 0.085, cheek);
    canvas.drawCircle(
        Offset(cx + eyeDx * 1.3, headCy + w * 0.10), w * 0.085, cheek);

    final pupil = Paint()..color = ink;
    final coveredEyes = s.accessory == AvatarAccessory.sunglasses;

    if (!coveredEyes) {
      switch (s.face) {
        case AvatarFace.wink:
          _dotEye(canvas, Offset(cx - eyeDx, eyeY), w, ink);
          _lineEye(canvas, Offset(cx + eyeDx, eyeY), w, ink);
          break;
        case AvatarFace.star:
          _starEye(canvas, Offset(cx - eyeDx, eyeY), w * 0.06, ink);
          _starEye(canvas, Offset(cx + eyeDx, eyeY), w * 0.06, ink);
          break;
        case AvatarFace.calm:
          _arcEye(canvas, Offset(cx - eyeDx, eyeY), w, ink);
          _arcEye(canvas, Offset(cx + eyeDx, eyeY), w, ink);
          break;
        default:
          canvas.drawCircle(Offset(cx - eyeDx, eyeY), w * 0.032, pupil);
          canvas.drawCircle(Offset(cx + eyeDx, eyeY), w * 0.032, pupil);
          final hl = Paint()..color = Colors.white;
          canvas.drawCircle(
              Offset(cx - eyeDx + w * 0.012, eyeY - w * 0.014),
              w * 0.012, hl);
          canvas.drawCircle(
              Offset(cx + eyeDx + w * 0.012, eyeY - w * 0.014),
              w * 0.012, hl);
      }
    }

    if (s.accessory == AvatarAccessory.glasses) {
      _glasses(canvas, cx, eyeY, eyeDx, w, ink);
    } else if (s.accessory == AvatarAccessory.sunglasses) {
      _sunglasses(canvas, cx, eyeY, eyeDx, w);
    } else if (s.accessory == AvatarAccessory.headphones) {
      _headphones(canvas, cx, headCy, headR, w);
    } else if (s.accessory == AvatarAccessory.cap) {
      _cap(canvas, cx, headCy, headR, w);
    }

    // mouth
    final mY = headCy + w * 0.13;
    final mW = w * 0.11;
    if (s.face == AvatarFace.grin) {
      final p = Path()
        ..moveTo(cx - mW, mY - w * 0.01)
        ..quadraticBezierTo(cx, mY + w * 0.10, cx + mW, mY - w * 0.01)
        ..close();
      canvas.drawPath(p, Paint()..color = ink);
    } else {
      final mouth = Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.022
        ..strokeCap = StrokeCap.round;
      final path = Path();
      if (s.face == AvatarFace.cool) {
        path.moveTo(cx - mW, mY + w * 0.02);
        path.quadraticBezierTo(
            cx + w * 0.02, mY + w * 0.05, cx + mW, mY - w * 0.03);
      } else if (s.face == AvatarFace.calm) {
        path.moveTo(cx - mW * 0.7, mY);
        path.lineTo(cx + mW * 0.7, mY);
      } else {
        path.moveTo(cx - mW, mY - w * 0.01);
        path.quadraticBezierTo(cx, mY + w * 0.07, cx + mW, mY - w * 0.01);
      }
      canvas.drawPath(path, mouth);
    }

    canvas.restore();
  }

  void _dotEye(Canvas canvas, Offset c, double w, Color ink) {
    canvas.drawCircle(c, w * 0.032, Paint()..color = ink);
    canvas.drawCircle(Offset(c.dx + w * 0.012, c.dy - w * 0.014),
        w * 0.012, Paint()..color = Colors.white);
  }

  void _lineEye(Canvas canvas, Offset c, double w, Color ink) {
    final p = Paint()
      ..color = ink
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(c.dx - w * 0.04, c.dy), Offset(c.dx + w * 0.04, c.dy), p);
  }

  void _arcEye(Canvas canvas, Offset c, double w, Color ink) {
    final p = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(c.dx - w * 0.045, c.dy)
      ..quadraticBezierTo(c.dx, c.dy + w * 0.035, c.dx + w * 0.045, c.dy);
    canvas.drawPath(path, p);
  }

  void _starEye(Canvas canvas, Offset c, double r, Color ink) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final ang = (i * math.pi / 4) - math.pi / 2;
      final rad = i.isEven ? r : r * 0.42;
      final x = c.dx + rad * math.cos(ang);
      final y = c.dy + rad * math.sin(ang);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = ink);
  }

  void _sunglasses(
      Canvas canvas, double cx, double eyeY, double eyeDx, double w) {
    final lensRect = Rect.fromLTWH(cx - eyeDx * 2.1, eyeY - w * 0.06,
        eyeDx * 4.2, w * 0.12);
    final lens = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF3A4250), const Color(0xFF151A22)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(lensRect);
    final lensW = w * 0.135;
    final lensH = w * 0.105;
    RRect lShape(double dx) => RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx + dx, eyeY), width: lensW, height: lensH),
        Radius.circular(w * 0.035));
    canvas.drawRRect(lShape(-eyeDx), lens);
    canvas.drawRRect(lShape(eyeDx), lens);
    final bridge = Paint()
      ..color = const Color(0xFF222831)
      ..strokeWidth = w * 0.02;
    canvas.drawLine(Offset(cx - eyeDx + lensW * 0.4, eyeY),
        Offset(cx + eyeDx - lensW * 0.4, eyeY), bridge);
    final shine = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..strokeWidth = w * 0.014
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - eyeDx - lensW * 0.2, eyeY - lensH * 0.2),
        Offset(cx - eyeDx + lensW * 0.05, eyeY - lensH * 0.28), shine);
  }

  void _glasses(Canvas canvas, double cx, double eyeY, double eyeDx,
      double w, Color ink) {
    final frame = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018;
    canvas.drawCircle(Offset(cx - eyeDx, eyeY), w * 0.075, frame);
    canvas.drawCircle(Offset(cx + eyeDx, eyeY), w * 0.075, frame);
    canvas.drawLine(Offset(cx - eyeDx + w * 0.075, eyeY),
        Offset(cx + eyeDx - w * 0.075, eyeY), frame);
  }

  void _headphones(
      Canvas canvas, double cx, double headCy, double headR, double w) {
    final band = Paint()
      ..color = const Color(0xFF2B2B2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(
        center: Offset(cx, headCy - w * 0.02), radius: headR + w * 0.05);
    canvas.drawArc(rect, math.pi, math.pi, false, band);
    final cup = Paint()..color = const Color(0xFF2B2B2B);
    RRect cupShape(double dx) => RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx + dx, headCy + w * 0.02),
            width: w * 0.09,
            height: w * 0.16),
        Radius.circular(w * 0.03));
    canvas.drawRRect(cupShape(-(headR + w * 0.02)), cup);
    canvas.drawRRect(cupShape(headR + w * 0.02), cup);
  }

  void _cap(Canvas canvas, double cx, double headCy, double headR,
      double w) {
    final capPaint = Paint()..color = const Color(0xFFE74C3C);
    final top = headCy - headR;
    final dome = Rect.fromCircle(
        center: Offset(cx, headCy - w * 0.04), radius: headR);
    canvas.drawArc(dome, math.pi, math.pi, true, capPaint);
    canvas.drawRect(
        Rect.fromLTWH(cx - headR, top + w * 0.20, headR * 2, w * 0.05),
        capPaint);
    final brim = Path()
      ..moveTo(cx + w * 0.02, top + w * 0.22)
      ..quadraticBezierTo(cx + headR + w * 0.12, top + w * 0.20,
          cx + headR + w * 0.10, top + w * 0.30)
      ..quadraticBezierTo(
          cx + headR, top + w * 0.28, cx + w * 0.02, top + w * 0.28)
      ..close();
    canvas.drawPath(brim, capPaint);
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => old.s.id != s.id;
}

/// Bottom-sheet picker. Returns the chosen avatar id, or null if dismissed.
/// Includes an "Upload photo" option (stores the image and returns 'custom').
Future<String?> showAvatarPicker(BuildContext context,
    {String? current}) {
  String? selected = current;
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheet) {
        Future<void> upload() async {
          try {
            await PermissionService.requestPhotos();
            final XFile? f = await ImagePicker().pickImage(
              source: ImageSource.gallery,
              maxWidth: 320,
              maxHeight: 320,
              imageQuality: 80,
            );
            if (f != null) {
              final bytes = await f.readAsBytes();
              await StorageService.setAvatarImage(base64Encode(bytes));
              setSheet(() => selected = UserAvatars.customId);
            }
          } catch (_) {}
        }

        final hasCustom =
            (StorageService.getAvatarImage() ?? '').isNotEmpty;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Choose your avatar',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A2E1A))),
                const SizedBox(height: 16),

                // Upload row
                GestureDetector(
                  onTap: upload,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF2ECC71)
                              .withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_a_photo_rounded,
                            color: Color(0xFF1E8E4E)),
                        const SizedBox(width: 12),
                        Text(
                            hasCustom
                                ? 'Change uploaded photo'
                                : 'Upload your own photo',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A2E1A))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    if (hasCustom)
                      _pickTile(
                        selected == UserAvatars.customId,
                        const UserAvatar(
                            id: UserAvatars.customId, size: 62),
                        () => setSheet(
                            () => selected = UserAvatars.customId),
                      ),
                    ...UserAvatars.all.map((spec) => _pickTile(
                          selected == spec.id,
                          UserAvatar(id: spec.id, size: 62),
                          () => setSheet(() => selected = spec.id),
                        )),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Save',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}

Widget _pickTile(bool selected, Widget avatar, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? const Color(0xFF2ECC71) : Colors.transparent,
          width: 3,
        ),
      ),
      child: avatar,
    ),
  );
}
