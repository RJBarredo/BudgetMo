import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../models/expense.dart';

// ─── INSIGHTS CARD ───────────────────────────────────────────────────────────

class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key});

  _InsightData _getInsight() {
    final byCategory = StorageService.getSpendingByCategory();
    final weeklyBudget = StorageService.getWeeklyBudget();
    final spentWeek = StorageService.getTotalSpentThisWeek();
    final spentToday = StorageService.getTotalSpentToday();
    final safeToday = StorageService.getSafeToSpendToday();
    final savings = StorageService.getSavingsGoal();
    final saved = ((savings['saved'] ?? 0.0) as num).toDouble();
    final target = ((savings['target'] ?? 1.0) as num).toDouble();

    if (byCategory.isEmpty) {
      return _InsightData(
        text: "Start logging your expenses to get personalized spending insights!",
        color: const Color(0xFF2ECC71),
        icon: Icons.lightbulb_rounded,
      );
    }

    final progress =
    weeklyBudget > 0 ? spentWeek / weeklyBudget : 0.0;

    if (progress >= 1.0) {
      return _InsightData(
        text: "You've exceeded your weekly budget by ₱${(spentWeek - weeklyBudget).toStringAsFixed(0)}. Try to avoid spending until next week!",
        color: const Color(0xFFE74C3C),
        icon: Icons.warning_rounded,
      );
    }
    if (progress >= 0.8) {
      return _InsightData(
        text: "You've used ${(progress * 100).toStringAsFixed(0)}% of your weekly budget. Only ₱${(weeklyBudget - spentWeek).toStringAsFixed(0)} left — spend wisely!",
        color: const Color(0xFFF39C12),
        icon: Icons.warning_amber_rounded,
      );
    }
    if (byCategory.isNotEmpty) {
      final topCategory = byCategory.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      if (spentWeek > 0 &&
          topCategory.value / spentWeek > 0.6) {
        return _InsightData(
          text: "${topCategory.key} takes up ${(topCategory.value / weeklyBudget * 100).toStringAsFixed(0)}% of your budget. Consider reducing ${topCategory.key.toLowerCase()} spending.",
          color: const Color(0xFF3498DB),
          icon: Icons.pie_chart_rounded,
        );
      }
    }
    if (target > 0 && saved / target >= 0.5) {
      return _InsightData(
        text: "You're ${(saved / target * 100).toStringAsFixed(0)}% of the way to your savings goal! Keep it up!",
        color: const Color(0xFFF39C12),
        icon: Icons.savings_rounded,
      );
    }
    if (progress < 0.5) {
      return _InsightData(
        text: "Great job! You're on track this week. You've only used ${(progress * 100).toStringAsFixed(0)}% of your budget.",
        color: const Color(0xFF2ECC71),
        icon: Icons.thumb_up_rounded,
      );
    }
    if (spentToday > safeToday && safeToday > 0) {
      return _InsightData(
        text: "You've spent more than your daily safe limit today. Try to cut back tomorrow.",
        color: const Color(0xFFF39C12),
        icon: Icons.access_time_rounded,
      );
    }
    return _InsightData(
      text: "You're managing your budget well this week. Keep logging your expenses!",
      color: const Color(0xFF2ECC71),
      icon: Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final insight = _getInsight();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insight.color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: insight.color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: insight.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(insight.icon,
                color: insight.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart Insight',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: insight.color)),
                const SizedBox(height: 3),
                Text(insight.text,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.black45,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightData {
  final String text;
  final Color color;
  final IconData icon;
  _InsightData(
      {required this.text,
        required this.color,
        required this.icon});
}

// ─── STREAK CARD ─────────────────────────────────────────────────────────────

class StreakCard extends StatelessWidget {
  const StreakCard({super.key});

  int _calculateStreak() {
    final expenses = StorageService.getExpenses();
    if (expenses.isEmpty) return 0;
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final dayStart =
      DateTime(day.year, day.month, day.day);
      final dayEnd =
      dayStart.add(const Duration(days: 1));
      final hasExpense = expenses.any((e) =>
      e.date.isAfter(dayStart) &&
          e.date.isBefore(dayEnd));
      if (hasExpense) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final streak = _calculateStreak();
    if (streak == 0) return const SizedBox.shrink();

    String message;
    if (streak >= 7) {
      message = 'Full week streak! You\'re a pro! 🏆';
    } else if (streak >= 3) {
      message = 'Keep it up! You\'re on a roll!';
    } else {
      message = 'Good start! Keep logging daily.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const Text('🔥',
              style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$streak Day Streak!',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text(message,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── QUICK LOG CARD ───────────────────────────────────────────────────────────

class QuickLogCard extends StatelessWidget {
  final VoidCallback onExpenseAdded;

  const QuickLogCard({super.key, required this.onExpenseAdded});

  static const List<Map<String, dynamic>> _templates = [
    {
      'title': 'Jeep Fare',
      'amount': 14.0,
      'category': 'Transport',
      'icon': Icons.directions_bus_rounded,
      'color': Color(0xFF3498DB),
      'bg': Color(0xFFEBF5FB),
    },
    {
      'title': 'Lunch',
      'amount': 65.0,
      'category': 'Food',
      'icon': Icons.lunch_dining_rounded,
      'color': Color(0xFF2ECC71),
      'bg': Color(0xFFEAF9F0),
    },
    {
      'title': 'Snack',
      'amount': 25.0,
      'category': 'Food',
      'icon': Icons.cookie_rounded,
      'color': Color(0xFFF39C12),
      'bg': Color(0xFFFEF9E7),
    },
    {
      'title': 'Bus Fare',
      'amount': 30.0,
      'category': 'Transport',
      'icon': Icons.directions_transit_rounded,
      'color': Color(0xFF3498DB),
      'bg': Color(0xFFEBF5FB),
    },
    {
      'title': 'Drinks',
      'amount': 35.0,
      'category': 'Food',
      'icon': Icons.local_drink_rounded,
      'color': Color(0xFF9B59B6),
      'bg': Color(0xFFF5EEF8),
    },
    {
      'title': 'Printing',
      'amount': 20.0,
      'category': 'Supplies',
      'icon': Icons.print_rounded,
      'color': Color(0xFF95A5A6),
      'bg': Color(0xFFF2F3F4),
    },
  ];

  Future<void> _logExpense(
      BuildContext context, Map<String, dynamic> t, double amount) async {
    await StorageService.addExpense(
      Expense(
        title: t['title'] as String,
        amount: amount,
        category: t['category'] as String,
        date: DateTime.now(),
        note: 'Quick log',
      ),
    );
    onExpenseAdded();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t['title']} logged — ₱${amount.toStringAsFixed(0)}',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF2ECC71),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showEditAmountDialog(
      BuildContext context, Map<String, dynamic> t) async {
    final ctrl = TextEditingController(
        text: ((t['amount'] as num).toDouble()).toStringAsFixed(0));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (t['bg'] as Color),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(t['icon'] as IconData,
                  color: t['color'] as Color, size: 20),
            ),
            const SizedBox(width: 10),
            Text(t['title'] as String,
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter amount:',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.black45, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                prefixText: '₱ ',
                prefixStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2ECC71)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.black45)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Log it!',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final amount = double.tryParse(ctrl.text);
      if (amount != null && amount > 0) {
        await _logExpense(context, t, amount);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('⚡ Quick Log',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: const Color(0xFF1A2E1A))),
            const SizedBox(width: 8),
            Text('Hold to edit amount',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: Colors.black26)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length,
            itemBuilder: (context, i) {
              final t = _templates[i];
              return GestureDetector(
                // Tap = log with default amount
                onTap: () async {
                  final confirmed =
                  await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(20)),
                      title: Text('Quick Log',
                          style:
                          GoogleFonts.plusJakartaSans(
                              fontWeight:
                              FontWeight.w700)),
                      content: Text(
                          'Log "${t['title']}" for ₱${t['amount']}?',
                          style: GoogleFonts
                              .plusJakartaSans()),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(
                                  context, false),
                          child: Text('Cancel',
                              style: GoogleFonts
                                  .plusJakartaSans(
                                  color:
                                  Colors.black45)),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(
                                  context, true),
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF2ECC71),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    10)),
                          ),
                          child: Text('Log it!',
                              style: GoogleFonts
                                  .plusJakartaSans(
                                  fontWeight:
                                  FontWeight
                                      .w700)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true &&
                      context.mounted) {
                    await _logExpense(
                        context, t, (t['amount'] as num).toDouble());
                  }
                },
                // Long press = edit amount first
                onLongPress: () =>
                    _showEditAmountDialog(context, t),
                child: Container(
                  width: 82,
                  margin:
                  const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(14),
                    border: Border(
                        top: BorderSide(
                            color: t['color'] as Color,
                            width: 3)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black
                              .withOpacity(0.04),
                          blurRadius: 6)
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: t['bg'] as Color,
                          borderRadius:
                          BorderRadius.circular(8),
                        ),
                        child: Icon(
                            t['icon'] as IconData,
                            color: t['color'] as Color,
                            size: 18),
                      ),
                      const SizedBox(height: 5),
                      Text(t['title'] as String,
                          style: GoogleFonts
                              .plusJakartaSans(
                              fontSize: 10,
                              fontWeight:
                              FontWeight.w600,
                              color: const Color(
                                  0xFF1A2E1A)),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis),
                      Text(
                          '₱${((t['amount'] as num).toDouble()).toStringAsFixed(0)}',
                          style: GoogleFonts
                              .plusJakartaSans(
                              fontSize: 10,
                              color: t['color']
                              as Color,
                              fontWeight:
                              FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}