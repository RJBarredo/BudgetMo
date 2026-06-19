import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import 'animations.dart';

enum MascotMood { happy, celebrate, worried, neutral }

class Advice {
  final String text;
  final MascotMood mood;
  const Advice(this.text, this.mood);
}

/// Turns the user's real numbers into a prioritized list of friendly tips.
class AdviceEngine {
  static List<Advice> generate() {
    final budget = StorageService.getWeeklyBudget();
    final spentWeek = StorageService.getTotalSpentThisWeek();
    final spentToday = StorageService.getTotalSpentToday();
    final incomeWeek = StorageService.getTotalIncomeThisWeek();
    final net = StorageService.getNetThisWeek();
    final safeToday = StorageService.getSafeToSpendToday();
    final goals = StorageService.getAllSavingsGoals();
    final byCat = StorageService.getSpendingByCategory();

    final tips = <Advice>[];
    final ratio = budget > 0 ? spentWeek / budget : 0.0;

    // ── Budget status ──
    if (budget > 0 && spentWeek > budget) {
      tips.add(Advice(
          "Whoa — you're ₱${(spentWeek - budget).toStringAsFixed(0)} over budget this week. Let's ease up for a few days. 💪",
          MascotMood.worried));
    } else if (ratio >= 0.8) {
      tips.add(Advice(
          "You've used ${(ratio * 100).toStringAsFixed(0)}% of your weekly budget. Spend mindfully from here! 👀",
          MascotMood.worried));
    } else if (budget > 0 && spentWeek == 0) {
      tips.add(Advice(
          "Fresh week, ₱${budget.toStringAsFixed(0)} to work with. Log your first expense and I'll track it. ✨",
          MascotMood.happy));
    } else if (ratio <= 0.5 && spentWeek > 0) {
      tips.add(Advice(
          "Nice pacing — only ${(ratio * 100).toStringAsFixed(0)}% of your budget used. You're in control! 🌿",
          MascotMood.celebrate));
    }

    // ── Income / net ──
    if (incomeWeek == 0) {
      tips.add(const Advice(
          "No income logged this week yet. Tap 'Manage income' so I can show your true net. 💵",
          MascotMood.neutral));
    } else if (net < 0) {
      tips.add(Advice(
          "You're spending more than you've earned this week (net -₱${net.abs().toStringAsFixed(0)}). Worth a peek. 🧐",
          MascotMood.worried));
    } else if (net > 0) {
      tips.add(Advice(
          "You're ₱${net.toStringAsFixed(0)} in the green this week. Future you says salamat! 😎",
          MascotMood.celebrate));
    }

    // ── Today ──
    if (safeToday <= 0) {
      tips.add(const Advice(
          "You've reached today's safe-to-spend. Maybe call it for the day? 🛑",
          MascotMood.worried));
    } else if (spentToday == 0) {
      tips.add(const Advice(
          "Nothing logged today — a no-spend day is a quiet little win. 🏆",
          MascotMood.happy));
    }

    // ── Category budgets ──
    final catBudgets = StorageService.getCategoryBudgets();
    if (catBudgets.isNotEmpty) {
      final catSpent = StorageService.getWeeklyCategorySpending();
      for (final entry in catBudgets.entries) {
        final spent = catSpent[entry.key] ?? 0;
        if (spent > entry.value) {
          tips.add(Advice(
              "${entry.key} is over its ₱${entry.value.toStringAsFixed(0)} weekly cap (₱${spent.toStringAsFixed(0)} so far). 🧾",
              MascotMood.worried));
          break;
        }
      }
    }

    // ── Daily reminder ──
    if (StorageService.getReminderEnabled() &&
        DateTime.now().hour >= StorageService.getReminderHour() &&
        spentToday == 0) {
      tips.add(const Advice(
          "It's getting late and nothing's logged today. Want to add your spending? ⏰",
          MascotMood.neutral));
    }

    // ── No-spend streak ──
    final streak = StorageService.getNoSpendStreak();
    if (streak >= 2) {
      tips.add(Advice(
          "$streak-day no-spend streak! 🔥 Keep it rolling.",
          MascotMood.celebrate));
    }

    // ── Savings ──
    if (goals.isEmpty) {
      tips.add(const Advice(
          "No savings goal yet. Even ₱20 a week adds up — want to set one? 🎯",
          MascotMood.neutral));
    } else {
      final g = goals[0];
      final saved = (g['saved'] as num?)?.toDouble() ?? 0.0;
      final target = (g['target'] as num?)?.toDouble() ?? 0.0;
      final name = (g['name'] ?? 'your goal').toString();
      if (target > 0) {
        final p = (saved / target * 100).clamp(0, 100).toDouble();
        if (p >= 100) {
          tips.add(Advice("🎉 You hit '$name'! Time to dream up the next goal.",
              MascotMood.celebrate));
        } else if (p >= 50) {
          tips.add(Advice(
              "You're ${p.toStringAsFixed(0)}% to '$name'. Over halfway — keep stacking! 📈",
              MascotMood.happy));
        } else {
          tips.add(Advice(
              "Every peso toward '$name' counts. Small and steady wins. 🐢",
              MascotMood.happy));
        }
      }
    }

    // ── Top category ──
    if (byCat.isNotEmpty) {
      final top =
          byCat.entries.reduce((a, b) => a.value > b.value ? a : b);
      tips.add(Advice(
          "Your biggest spend lately is ${top.key} (₱${top.value.toStringAsFixed(0)}). One to keep an eye on. 📊",
          MascotMood.neutral));
    }

    if (tips.isEmpty) {
      tips.add(const Advice(
          "Hi! I'm Piso. Log your spending and I'll share tips to stretch your budget. 👋",
          MascotMood.happy));
    }
    return tips;
  }
}

/// The advisor card: animated coin + a speech bubble. Tap to cycle tips.
class MascotAdvisorCard extends StatefulWidget {
  const MascotAdvisorCard({super.key});

  @override
  State<MascotAdvisorCard> createState() => _MascotAdvisorCardState();
}

class _MascotAdvisorCardState extends State<MascotAdvisorCard> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final tips = AdviceEngine.generate();
    final idx = _i % tips.length;
    final advice = tips[idx];

    return FadeSlideIn(
      child: Pressable(
        onTap: () => setState(() => _i = (_i + 1) % tips.length),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF1FAF2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF2ECC71).withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF2ECC71).withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              CoinMascot(size: 60, mood: advice.mood),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Piso',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: const Color(0xFF1A2E1A))),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF2ECC71).withOpacity(0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('your money buddy',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E8E4E))),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text('${idx + 1}/${tips.length}',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: Colors.black26,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 3),
                            const Icon(Icons.refresh_rounded,
                                size: 15, color: Colors.black26),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SizeTransition(
                            sizeFactor: anim,
                            axisAlignment: -1,
                            child: child),
                      ),
                      child: Text(
                        advice.text,
                        key: ValueKey('${idx}_${advice.text.hashCode}'),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            height: 1.35,
                            color: const Color(0xFF35433A)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round gold peso-coin character that gently bobs and blinks.
class CoinMascot extends StatefulWidget {
  final double size;
  final MascotMood mood;
  const CoinMascot({super.key, this.size = 64, this.mood = MascotMood.happy});

  @override
  State<CoinMascot> createState() => _CoinMascotState();
}

class _CoinMascotState extends State<CoinMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final bob = math.sin(t * 2 * math.pi) * 3.0;
        final blink = t > 0.90 && t < 0.955;
        return Transform.translate(
          offset: Offset(0, bob),
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CoinPainter(mood: widget.mood, blink: blink),
          ),
        );
      },
    );
  }
}

class _CoinPainter extends CustomPainter {
  final MascotMood mood;
  final bool blink;
  _CoinPainter({required this.mood, required this.blink});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    const ink = Color(0xFF3B2B00);

    // ground shadow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(c.dx, size.height - r * 0.06),
          width: r * 1.3,
          height: r * 0.34),
      Paint()..color = Colors.black.withOpacity(0.08),
    );

    // coin body
    final bodyRect = Rect.fromCircle(center: c, radius: r * 0.9);
    canvas.drawCircle(
      c,
      r * 0.9,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFE9A8), Color(0xFFFFB300)],
          stops: [0.25, 1.0],
        ).createShader(bodyRect),
    );
    canvas.drawCircle(
      c,
      r * 0.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.10
        ..color = const Color(0xFFE69500),
    );
    canvas.drawCircle(
      c,
      r * 0.7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.035
        ..color = const Color(0xFFFFD662),
    );

    final eyeY = c.dy - r * 0.08;
    final eyeDx = r * 0.30;

    final cheek = Paint()..color = const Color(0xFFFF8A80).withOpacity(0.5);
    canvas.drawCircle(
        Offset(c.dx - eyeDx * 1.3, c.dy + r * 0.14), r * 0.095, cheek);
    canvas.drawCircle(
        Offset(c.dx + eyeDx * 1.3, c.dy + r * 0.14), r * 0.095, cheek);

    final pupil = Paint()..color = ink;

    if (blink) {
      final lp = Paint()
        ..color = ink
        ..strokeWidth = r * 0.06
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(c.dx - eyeDx - r * 0.08, eyeY),
          Offset(c.dx - eyeDx + r * 0.08, eyeY), lp);
      canvas.drawLine(Offset(c.dx + eyeDx - r * 0.08, eyeY),
          Offset(c.dx + eyeDx + r * 0.08, eyeY), lp);
    } else if (mood == MascotMood.celebrate) {
      _happyEye(canvas, Offset(c.dx - eyeDx, eyeY), r * 0.13, ink);
      _happyEye(canvas, Offset(c.dx + eyeDx, eyeY), r * 0.13, ink);
    } else {
      canvas.drawCircle(Offset(c.dx - eyeDx, eyeY), r * 0.09, pupil);
      canvas.drawCircle(Offset(c.dx + eyeDx, eyeY), r * 0.09, pupil);
      final hl = Paint()..color = Colors.white;
      canvas.drawCircle(
          Offset(c.dx - eyeDx + r * 0.03, eyeY - r * 0.03), r * 0.03, hl);
      canvas.drawCircle(
          Offset(c.dx + eyeDx + r * 0.03, eyeY - r * 0.03), r * 0.03, hl);
    }

    if (mood == MascotMood.worried) {
      final bp = Paint()
        ..color = ink
        ..strokeWidth = r * 0.05
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(c.dx - eyeDx - r * 0.10, eyeY - r * 0.24),
          Offset(c.dx - eyeDx + r * 0.10, eyeY - r * 0.15), bp);
      canvas.drawLine(Offset(c.dx + eyeDx + r * 0.10, eyeY - r * 0.24),
          Offset(c.dx + eyeDx - r * 0.10, eyeY - r * 0.15), bp);
    }

    final mY = c.dy + r * 0.34;
    final mW = r * 0.38;
    if (mood == MascotMood.celebrate) {
      final op = Path()
        ..moveTo(c.dx - mW, mY)
        ..quadraticBezierTo(c.dx, mY + r * 0.36, c.dx + mW, mY)
        ..close();
      canvas.drawPath(op, Paint()..color = ink);
    } else {
      final mouth = Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..strokeCap = StrokeCap.round;
      final path = Path();
      if (mood == MascotMood.worried) {
        path.moveTo(c.dx - mW, mY + r * 0.06);
        path.quadraticBezierTo(c.dx, mY - r * 0.12, c.dx + mW, mY + r * 0.06);
      } else {
        path.moveTo(c.dx - mW, mY - r * 0.02);
        path.quadraticBezierTo(c.dx, mY + r * 0.20, c.dx + mW, mY - r * 0.02);
      }
      canvas.drawPath(path, mouth);
    }
  }

  void _happyEye(Canvas canvas, Offset center, double w, Color color) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(center.dx - w, center.dy + w * 0.4)
      ..quadraticBezierTo(
          center.dx, center.dy - w * 0.6, center.dx + w, center.dy + w * 0.4);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_CoinPainter old) =>
      old.blink != blink || old.mood != mood;
}
