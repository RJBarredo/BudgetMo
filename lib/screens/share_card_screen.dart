import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';
import '../widgets/mascot_advisor.dart';
import '../theme/theme_controller.dart';

class ShareCardScreen extends StatelessWidget {
  const ShareCardScreen({super.key});

  String _weekRange() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final budget = StorageService.getWeeklyBudget();
    final spent = StorageService.getTotalSpentThisWeek();
    final income = StorageService.getTotalIncomeThisWeek();
    final net = StorageService.getNetThisWeek();
    final streak = StorageService.getNoSpendStreak();
    final goals = StorageService.getAllSavingsGoals();
    final saved = goals.isNotEmpty
        ? ((goals[0]['saved'] as num?)?.toDouble() ?? 0)
        : 0.0;
    final under = budget > 0 && spent <= budget;

    final mood = net > 0
        ? MascotMood.celebrate
        : (net < 0 ? MascotMood.worried : MascotMood.happy);

    String headline;
    if (streak >= 2) {
      headline = '$streak-day no-spend streak! 🔥';
    } else if (under && budget > 0) {
      headline = 'Stayed under budget this week 💪';
    } else if (net > 0) {
      headline = '₱${net.toStringAsFixed(0)} in the green 😎';
    } else {
      headline = 'Another week, tracked ✨';
    }

    final shareText =
        'My week on BudgetMo ($_weekRange()):\n'
        '💸 Spent ₱${spent.toStringAsFixed(0)}\n'
        '💵 Income ₱${income.toStringAsFixed(0)}\n'
        '📊 Net ₱${net.toStringAsFixed(0)}\n'
        '🐷 Saved ₱${saved.toStringAsFixed(0)}'
        '${streak >= 2 ? '\n🔥 $streak-day no-spend streak' : ''}';

    return Scaffold(
      backgroundColor: cBg,
      appBar: appHeader(context, 'Your Week'),
      body: phoneWrap(
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Screenshot this to share your week 📸',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.black45)),
              const SizedBox(height: 16),

              // The share card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF12280F), Color(0xFF2D5A2D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF1A2E1A).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CoinMascot(size: 56, mood: mood),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BudgetMo',
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20)),
                            Text(_weekRange(),
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white54,
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(headline,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _stat('Income', income, const Color(0xFF7BE495)),
                        _stat('Spent', spent, const Color(0xFFFF8A80)),
                        _stat('Net', net,
                            net >= 0
                                ? const Color(0xFF7BE495)
                                : const Color(0xFFFF8A80),
                            signed: true),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          _mini('🐷 Saved',
                              '₱${saved.toStringAsFixed(0)}'),
                          Container(
                              width: 1,
                              height: 26,
                              color: Colors.white24),
                          _mini('🔥 Streak',
                              '$streak ${streak == 1 ? 'day' : 'days'}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: cAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: shareText));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Summary copied — paste it anywhere'),
                            backgroundColor: Color(0xFF2ECC71)),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text('Copy summary text',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, double value, Color color,
      {bool signed = false}) {
    final prefix = signed && value < 0 ? '-₱' : '₱';
    return Expanded(
      child: Column(
        children: [
          Text('$prefix${value.abs().toStringAsFixed(0)}',
              style: GoogleFonts.plusJakartaSans(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 19)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _mini(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14)),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white54, fontSize: 10.5)),
      ],
    );
  }
}
