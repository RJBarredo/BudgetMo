import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../widgets/expense_card.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';
import 'expenses_screen.dart';
import 'savings_screen.dart';
import 'charts_screen.dart';
import 'settings_screen.dart';
import '../widgets/animations.dart';
import '../widgets/mascot_advisor.dart';
import '../widgets/ui_kit.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _homeKey = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      _HomeTab(key: ValueKey(_homeKey)),
      const ExpensesScreen(),
      const ChartsScreen(),
      const SavingsScreen(),
    ];
    return Scaffold(
      backgroundColor: cBg,
      body: screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: cAccent,
              foregroundColor: Colors.white,
              elevation: 3,
              onPressed: () async {
                final r = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddExpenseScreen()));
                if (r == true) setState(() => _homeKey++);
              },
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: cAccent,
        unselectedItemColor: cSubtext,
        type: BottomNavigationBarType.fixed,
        backgroundColor: cSurface,
        elevation: 12,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded), label: 'Expenses'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded), label: 'Charts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.savings_rounded), label: 'Savings'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab({super.key});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  double _weeklyBudget = 1500;
  double _spentWeek = 0;
  double _spentToday = 0;
  double _incomeWeek = 0;
  Map<String, dynamic>? _recap;
  List<Expense> _recent = [];
  Map<String, dynamic> _savings = {};
  String _userName = 'there';
  String _userAvatar = UserAvatars.defaultId;
  List<double> _weekDaily = [];
  Map<String, double> _catSpend = {};

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowReminder();
    });
  }

  void _maybeShowReminder() {
    if (!mounted) return;
    if (!StorageService.shouldShowReminderNow(_spentToday)) return;
    StorageService.markReminderShownToday();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CoinMascot(size: 70, mood: MascotMood.neutral),
            const SizedBox(height: 14),
            Text("Don't forget to log!",
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: cInk)),
            const SizedBox(height: 8),
            Text(
              "You haven't logged any spending today. Want to add it now so I can keep your week accurate?",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5, height: 1.4, color: cSubtext),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later',
                style: GoogleFonts.plusJakartaSans(
                    color: cSubtext, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: cAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
              if (result == true) _load();
            },
            child: Text('Log now',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _load() {
    final box = Hive.box('budget');
    setState(() {
      _userName = box.get('userName', defaultValue: 'there');
      _userAvatar = box.get('userAvatar', defaultValue: UserAvatars.defaultId);
      _weeklyBudget = StorageService.getWeeklyBudget();
      _spentWeek = StorageService.getTotalSpentThisWeek();
      _spentToday = StorageService.getTotalSpentToday();
      _incomeWeek = StorageService.getTotalIncomeThisWeek();
      _recap = StorageService.getPendingRecap();
      _recent = StorageService.getExpenses().take(4).toList();
      _savings = StorageService.getSavingsGoal();
      _catSpend = StorageService.getWeeklyCategorySpending();
      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final daily = List<double>.filled(7, 0.0);
      for (final e in StorageService.getExpenses()) {
        if (!e.date.isBefore(monday)) {
          final idx = e.date.weekday - 1;
          if (idx >= 0 && idx < 7) daily[idx] += e.amount;
        }
      }
      _weekDaily = daily;
    });
  }

  String _getWeekRange() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final fmt = DateFormat('MMM d');
    return '${fmt.format(monday)} – ${fmt.format(sunday)}';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _pisoTip() {
    if (_incomeWeek > 0) {
      final rate = (_incomeWeek - _spentWeek) / _incomeWeek * 100;
      if (rate >= 0) {
        return "You're keeping ${rate.toStringAsFixed(0)}% of your income this week — nice work!";
      }
      return "Spending outran income this week. Let's ease up a little.";
    }
    final rem = _weeklyBudget - _spentWeek;
    if (rem > 0) {
      return "₱${rem.toStringAsFixed(0)} left in your weekly budget — you've got this!";
    }
    return "Over budget this week. Tomorrow's a fresh start.";
  }

  void _changeAvatar() async {
    final picked = await showAvatarPicker(context, current: _userAvatar);
    if (picked != null) {
      await Hive.box('budget').put('userAvatar', picked);
      _load();
    }
  }

  void _claimRecap() async {
    final moved = await StorageService.claimRecapToSavings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(moved > 0
              ? '₱${moved.toStringAsFixed(0)} moved to savings 🎉'
              : 'All set for the new week!'),
          backgroundColor: cAccent,
        ),
      );
    }
    _load();
  }

  void _dismissRecap() async {
    await StorageService.clearPendingRecap();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final weekRemaining = _weeklyBudget - _spentWeek;
    final over = weekRemaining < 0;
    final weekProgress =
        _weeklyBudget > 0 ? (_spentWeek / _weeklyBudget).clamp(0.0, 1.0) : 0.0;
    final topPad = MediaQuery.of(context).padding.top;

    return RefreshIndicator(
      color: cAccent,
      onRefresh: () async => _load(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(18, topPad + 14, 18, 120),
        children: [
          _greetingRow(),
          const SizedBox(height: 18),
          _pisoTipCard(),
          const SizedBox(height: 16),
          _netCard(weekRemaining, over, weekProgress),
          if (_recap != null) ...[
            const SizedBox(height: 16),
            _recapCard(),
          ],
          const SizedBox(height: 24),
          _sectionLabel('Your money'),
          const SizedBox(height: 12),
          _moneyCards(weekProgress),
          if (_catSpend.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel('By category'),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ChartsScreen())),
                  child: Row(children: [
                    Text('See all',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: cAccent,
                            fontWeight: FontWeight.w700)),
                    Icon(Icons.chevron_right_rounded, size: 18, color: cAccent),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _categoryBreakdown(),
          ],
          const SizedBox(height: 24),
          _searchBar(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _sectionLabel('Recent'),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ExpensesScreen())),
                child: Row(
                  children: [
                    Text('See all',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: cAccent,
                            fontWeight: FontWeight.w700)),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: cAccent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recent.isEmpty)
            _emptyState()
          else
            ..._recent.map((e) => ExpenseCard(expense: e)),
        ],
      ),
    );
  }

  // ── GREETING ──────────────────────────────────────────────
  Widget _greetingRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getGreeting(),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cInk,
                      height: 1.1)),
              const SizedBox(height: 2),
              Text(_userName,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: cSubtext)),
              Text(DateFormat('EEEE, MMM d').format(DateTime.now()),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5, color: cSubtext)),
            ],
          ),
        ),
        GestureDetector(
          onTap: _changeAvatar,
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
              child: Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                    color: cSurface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6)
                    ]),
                child: Icon(Icons.settings_rounded, color: cSubtext, size: 22),
              ),
            ),
            UserAvatar(id: _userAvatar, size: 46),
          ]),
        ),
      ],
    );
  }

  // ── PISO TIP CARD ─────────────────────────────────────────
  Widget _pisoTipCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: _softCard(),
      child: Row(
        children: [
          const CoinMascot(size: 46, mood: MascotMood.happy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Piso says',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: cInk)),
                  const SizedBox(width: 6),
                  Icon(Icons.eco_rounded, size: 15, color: cAccent),
                ]),
                const SizedBox(height: 3),
                Text(_pisoTip(),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5, height: 1.35, color: cSubtext)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── NET / REMAINING CARD ──────────────────────────────────
  Widget _netCard(double remaining, bool over, double progress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: _softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Remaining this week',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: cInk)),
              Text(_getWeekRange(),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5, color: cSubtext)),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedCount(
            value: remaining.abs(),
            prefix: over ? '-₱' : '₱',
            decimals: 2,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                color: over ? const Color(0xFFE74C3C) : cInk),
          ),
          const SizedBox(height: 12),
          Builder(builder: (_) {
            final pts = <double>[];
            double run = _weeklyBudget;
            final todayIdx = DateTime.now().weekday;
            for (var i = 0; i < todayIdx && i < _weekDaily.length; i++) {
              run -= _weekDaily[i];
              pts.add(run);
            }
            if (pts.length >= 2) {
              return Sparkline(
                points: pts,
                color: over ? const Color(0xFFE74C3C) : cAccent,
                height: 46,
              );
            }
            return Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                      color: cInk.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8)),
                ),
                FractionallySizedBox(
                  widthFactor: progress == 0 ? 0.02 : progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                        color: over ? const Color(0xFFE74C3C) : cAccent,
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statPill('Income', _incomeWeek,
                    Icons.south_west_rounded, const Color(0xFF2ECC71)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statPill('Spent', _spentWeek,
                    Icons.north_east_rounded, const Color(0xFFE74C3C)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color.withOpacity(0.85))),
                Text('₱${value.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTION LABEL ─────────────────────────────────────────
  Widget _categoryBreakdown() {
    final entries = _catSpend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(4).toList();
    final maxVal = top.isEmpty ? 1.0 : top.first.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _softCard(),
      child: Column(
        children: [
          for (var i = 0; i < top.length; i++)
            _catRow(top[i].key, top[i].value, maxVal, i == top.length - 1),
        ],
      ),
    );
  }

  Widget _catRow(String cat, double amount, double maxVal, bool last) {
    final data = ExpenseCard.categoryData[cat] ??
        ExpenseCard.categoryData['Other'] ??
        const {'icon': '📦', 'color': Color(0xFF95A5A6)};
    final color = data['color'] as Color;
    final icon = data['icon'] as String;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: cInk.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(11)),
            child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 19))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: cInk)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (amount / maxVal).clamp(0.05, 1.0),
                    minHeight: 5,
                    backgroundColor: cInk.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('₱${amount.toStringAsFixed(0)}',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5, fontWeight: FontWeight.w800, color: cInk)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: cInk));
  }

  // ── MONEY CARDS (budget + savings) ────────────────────────
  Widget _moneyCards(double weekProgress) {
    final saved = ((_savings['saved'] ?? 0.0) as num).toDouble();
    final target = ((_savings['target'] ?? 3000.0) as num).toDouble();
    final savingsProgress = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _miniCard(
            ring: _ringStat(weekProgress, cAccent),
            title: 'Budget',
            value: '₱${_spentWeek.toStringAsFixed(0)}',
            sub: 'of ₱${_weeklyBudget.toStringAsFixed(0)}',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChartsScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniCard(
            ring: _ringStat(savingsProgress, const Color(0xFF2ECC71)),
            title: 'Savings',
            value: '₱${saved.toStringAsFixed(0)}',
            sub: 'of ₱${target.toStringAsFixed(0)}',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SavingsScreen())),
          ),
        ),
      ],
    );
  }

  Widget _miniCard({
    required Widget ring,
    required String title,
    required String value,
    required String sub,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _softCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ring,
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: cSubtext),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: cSubtext)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: cInk)),
            Text(sub,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5, color: cSubtext)),
          ],
        ),
      ),
    );
  }

  Widget _ringStat(double progress, Color color) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: progress == 0 ? 0.02 : progress,
              strokeWidth: 5,
              backgroundColor: color.withOpacity(0.14),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text('${(progress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: cInk)),
        ],
      ),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────────
  Widget _searchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ExpensesScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _softCard(),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: cSubtext, size: 20),
            const SizedBox(width: 10),
            Text('Search transactions',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: cSubtext)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: cAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.tune_rounded, color: cAccent, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ── RECAP CARD (preserved logic) ──────────────────────────
  Widget _recapCard() {
    final recap = _recap!;
    final saved = ((recap['leftover'] ?? 0.0) as num).toDouble();
    final range = (recap['range'] ?? '') as String;
    final canRoll = saved > 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cGrad1, cGrad2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🎉', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Week wrapped!',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(range,
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70, fontSize: 11)),
          ]),
          const SizedBox(height: 10),
          Text(
              canRoll
                  ? "You finished ₱${saved.toStringAsFixed(0)} under budget. Roll it into savings?"
                  : "A new week has started. Here's a clean slate!",
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, fontSize: 13, height: 1.35)),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: _dismissRecap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(canRoll ? 'Skip' : 'Got it',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
              if (canRoll) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _claimRecap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('Move to savings',
                        style: GoogleFonts.plusJakartaSans(
                            color: cInk,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────
  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: _softCard(),
      child: Column(
        children: [
          const CoinMascot(size: 64, mood: MascotMood.happy),
          const SizedBox(height: 14),
          Text('No expenses yet',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: cInk)),
          const SizedBox(height: 6),
          Text('Tap the + button to log your first one.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: cSubtext)),
        ],
      ),
    );
  }

  BoxDecoration _softCard() => BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      );
}
