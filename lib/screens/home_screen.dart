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
import '../widgets/mascot_advisor.dart';
import '../widgets/user_avatar.dart';
import '../widgets/budget_ring.dart';
import '../theme/theme_controller.dart';

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
                final r = await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
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
        selectedLabelStyle:
            GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
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
  double _dailyBudget = 0;
  double _monthlyBudget = 0;
  double _spentWeek = 0;
  double _spentToday = 0;
  double _spentMonth = 0;
  double _incomeWeek = 0;
  Map<String, dynamic>? _recap;
  List<Expense> _recent = [];
  Map<String, dynamic> _savings = {};
  String _userName = 'there';
  String _userAvatar = UserAvatars.defaultId;
  List<double> _weekDaily = [];
  List<MapEntry<String, double>> _topCats = [];
  double _weekCatTotal = 0;
  int _txCountWeek = 0;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowReminder();
    });
  }

  void _load() {
    final box = Hive.box('budget');
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final daily = List<double>.filled(7, 0.0);
    final catMap = <String, double>{};
    var count = 0;
    for (final e in StorageService.getExpenses()) {
      if (!e.date.isBefore(monday)) {
        final idx = e.date.weekday - 1;
        if (idx >= 0 && idx < 7) daily[idx] += e.amount;
        catMap[e.category] = (catMap[e.category] ?? 0) + e.amount;
        count++;
      }
    }
    final entries = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    setState(() {
      _userName = box.get('userName', defaultValue: 'there');
      _userAvatar = box.get('userAvatar', defaultValue: UserAvatars.defaultId);
      _weeklyBudget = StorageService.getWeeklyBudget();
      _dailyBudget = StorageService.getDailyBudget();
      _monthlyBudget = StorageService.getMonthlyBudget();
      _spentWeek = StorageService.getTotalSpentThisWeek();
      _spentToday = StorageService.getTotalSpentToday();
      _spentMonth = StorageService.getTotalSpentThisMonth();
      _incomeWeek = StorageService.getTotalIncomeThisWeek();
      _recap = StorageService.getPendingRecap();
      _recent = StorageService.getExpenses().take(5).toList();
      _savings = StorageService.getSavingsGoal();
      _weekDaily = daily;
      _topCats = entries.take(3).toList();
      _weekCatTotal = catMap.values.fold(0.0, (a, b) => a + b);
      _txCountWeek = count;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CoinMascot(size: 70, mood: MascotMood.neutral),
            const SizedBox(height: 14),
            Text("Don't forget to log!",
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800, fontSize: 18, color: cInk)),
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
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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

  void _addQuick(String title, double amount, String category) async {
    await StorageService.addExpense(Expense(
        title: title, amount: amount, category: category, date: DateTime.now()));
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Added $title · ₱${amount.toStringAsFixed(0)}'),
        backgroundColor: cAccent,
        duration: const Duration(milliseconds: 1200),
      ));
    }
  }

  void _claimRecap() async {
    final moved = await StorageService.claimRecapToSavings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(moved > 0
            ? '₱${moved.toStringAsFixed(0)} moved to savings 🎉'
            : 'All set for the new week!'),
        backgroundColor: cAccent,
      ));
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _greenHero(topPad, weekRemaining, over, weekProgress),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _todayStrip(),
                  const SizedBox(height: 16),
                  _pisoTipCard(over),
                  const SizedBox(height: 16),
                  _flowCard(over),
                  if (_recap != null) ...[
                    const SizedBox(height: 16),
                    _recapCard(),
                  ],
                  const SizedBox(height: 24),
                  _quickLogSection(),
                  const SizedBox(height: 24),
                  _sectionLabel('Budgets'),
                  const SizedBox(height: 12),
                  _budgetPeriods(),
                  const SizedBox(height: 24),
                  _sectionLabel('Where it went'),
                  const SizedBox(height: 12),
                  _topCategories(),
                  const SizedBox(height: 24),
                  _sectionLabel('Your money'),
                  const SizedBox(height: 12),
                  _moneyCards(weekProgress),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionLabel('Recent activity'),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const ExpensesScreen())),
                        child: Row(children: [
                          Text('See all',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: cAccent,
                                  fontWeight: FontWeight.w700)),
                          Icon(Icons.chevron_right_rounded,
                              size: 18, color: cAccent),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_recent.isEmpty)
                    _emptyState()
                  else
                    ..._recent.map(_recentRow),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── RECENT ROW (lightweight, no swipe — full management on Expenses) ──
  Widget _recentRow(Expense e) {
    final data = ExpenseCard.categoryData[e.category] ??
        ExpenseCard.categoryData['Other']!;
    final color = data['color'] as Color;
    final icon = data['icon'] as String;
    final now = DateTime.now();
    final that = DateTime(e.date.year, e.date.month, e.date.day);
    final diff = DateTime(now.year, now.month, now.day).difference(that).inDays;
    final timeStr = DateFormat('h:mm a').format(e.date);
    final dateLabel = diff == 0
        ? 'Today · $timeStr'
        : diff == 1
            ? 'Yesterday · $timeStr'
            : '${DateFormat('MMM d').format(e.date)} · $timeStr';
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ExpensesScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _softCard(),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(13)),
              child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: cInk)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(7)),
                      child: Text(e.category,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5, color: cSubtext)),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('-₱${e.amount.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: const Color(0xFFE74C3C))),
          ],
        ),
      ),
    );
  }

  // ── BUDGET PERIODS (daily / weekly / monthly) ─────────────
  Widget _budgetPeriods() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _softCard(),
      child: Column(
        children: [
          _budgetRow('Daily', _spentToday, _dailyBudget, Icons.today_rounded),
          const SizedBox(height: 16),
          _budgetRow('Weekly', _spentWeek, _weeklyBudget,
              Icons.date_range_rounded),
          const SizedBox(height: 16),
          _budgetRow('Monthly', _spentMonth, _monthlyBudget,
              Icons.calendar_month_rounded),
        ],
      ),
    );
  }

  Widget _budgetRow(String label, double spent, double budget, IconData icon) {
    final hasBudget = budget > 0;
    final frac = hasBudget ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final over = hasBudget && spent > budget;
    final barColor = over ? const Color(0xFFE74C3C) : cAccent;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: cAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 19, color: cAccent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: cInk)),
                  Text(
                      hasBudget
                          ? '₱${spent.toStringAsFixed(0)} / ₱${budget.toStringAsFixed(0)}'
                          : 'No budget set',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: over ? const Color(0xFFE74C3C) : cSubtext)),
                ],
              ),
              const SizedBox(height: 6),
              Stack(children: [
                Container(
                    height: 7,
                    decoration: BoxDecoration(
                        color: cHairline,
                        borderRadius: BorderRadius.circular(8))),
                FractionallySizedBox(
                  widthFactor: hasBudget ? frac.clamp(0.02, 1.0) : 0.0,
                  child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(8))),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  // ── GREEN HERO ────────────────────────────────────────────
  Widget _greenHero(double topPad, double remaining, bool over, double progress) {
    final daysLeft = (8 - DateTime.now().weekday).clamp(1, 7);
    final safeToday = remaining > 0 ? remaining / daysLeft : 0.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cHeroGrad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
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
                            color: Colors.white,
                            height: 1.1)),
                    const SizedBox(height: 2),
                    Text(_userName,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.75))),
                    Text(DateFormat('EEEE, MMM d').format(DateTime.now()),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: Colors.white.withOpacity(0.55))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
                child: Container(
                  width: 42,
                  height: 42,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.settings_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
              GestureDetector(
                  onTap: _changeAvatar,
                  child: UserAvatar(id: _userAvatar, size: 46)),
            ],
          ),
          const SizedBox(height: 18),
          BudgetRing(
            percent: progress,
            size: 210,
            stroke: 16,
            colors: [
              Colors.white,
              Color.lerp(cAccent, Colors.white, 0.35)!,
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('LEFT THIS WEEK',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.white.withOpacity(0.6))),
                const SizedBox(height: 4),
                Text('₱${remaining.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0)),
                const SizedBox(height: 4),
                Text('of ₱${_weeklyBudget.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: Colors.white.withOpacity(0.55))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(_getWeekRange(),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5, color: Colors.white.withOpacity(0.55))),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                  child: _heroStat(
                      'Safe today', '₱${safeToday.toStringAsFixed(0)}')),
              _heroDivider(),
              Expanded(
                  child:
                      _heroStat('Spent', '₱${_spentWeek.toStringAsFixed(0)}')),
              _heroDivider(),
              Expanded(child: _heroStat('Days left', '$daysLeft')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: Colors.white.withOpacity(0.55))),
      ],
    );
  }

  Widget _heroDivider() =>
      Container(width: 1, height: 32, color: Colors.white.withOpacity(0.18));

  // ── TODAY STRIP ───────────────────────────────────────────
  Widget _todayStrip() {
    final net = _incomeWeek - _spentWeek;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: _softCard(),
      child: Row(
        children: [
          Expanded(
              child: _todayCell('Today', '₱${_spentToday.toStringAsFixed(0)}',
                  Icons.today_rounded, cAccent)),
          _todayDivider(),
          Expanded(
              child: _todayCell('This week', '₱${_spentWeek.toStringAsFixed(0)}',
                  Icons.date_range_rounded, const Color(0xFF3498DB))),
          _todayDivider(),
          Expanded(
              child: _todayCell(
                  'Net',
                  '${net < 0 ? '-' : ''}₱${net.abs().toStringAsFixed(0)}',
                  net >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  net >= 0
                      ? const Color(0xFF2ECC71)
                      : const Color(0xFFE74C3C))),
        ],
      ),
    );
  }

  Widget _todayCell(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5, fontWeight: FontWeight.w800, color: cInk)),
        const SizedBox(height: 1),
        Text(label,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: cSubtext)),
      ],
    );
  }

  Widget _todayDivider() => Container(width: 1, height: 34, color: cHairline);

  // ── PISO TIP CARD ─────────────────────────────────────────
  Widget _pisoTipCard(bool over) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _softCard(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoinMascot(
              size: 52,
              mood: over ? MascotMood.worried : MascotMood.happy),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Piso',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: cInk)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: cAccent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('your money buddy',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: cAccent)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(_pisoTip(),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5, height: 1.35, color: cSubtext)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FLOW CARD (sparkline + income/spent) ──────────────────
  Widget _flowCard(bool over) {
    final pts = <double>[];
    double run = _weeklyBudget;
    final todayIdx = DateTime.now().weekday;
    for (var i = 0; i < todayIdx && i < _weekDaily.length; i++) {
      run -= _weekDaily[i];
      pts.add(run);
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('This week',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w800, color: cInk)),
              Text('$_txCountWeek logged',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: cSubtext)),
            ],
          ),
          const SizedBox(height: 14),
          if (pts.length >= 2)
            SizedBox(
              height: 48,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size(double.infinity, 48),
                  painter: _SparkPainter(
                      pts, over ? const Color(0xFFE74C3C) : cAccent),
                ),
              ),
            )
          else
            Stack(children: [
              Container(
                  height: 8,
                  decoration: BoxDecoration(
                      color: cHairline,
                      borderRadius: BorderRadius.circular(8))),
              FractionallySizedBox(
                widthFactor: _weeklyBudget > 0
                    ? (_spentWeek / _weeklyBudget).clamp(0.02, 1.0)
                    : 0.02,
                child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                        color: over ? const Color(0xFFE74C3C) : cAccent,
                        borderRadius: BorderRadius.circular(8))),
              ),
            ]),
          const SizedBox(height: 16),
          Row(children: [
            _flowPill('Income', _incomeWeek, Icons.south_west_rounded,
                const Color(0xFF2ECC71)),
            const SizedBox(width: 10),
            _flowPill('Spent', _spentWeek, Icons.north_east_rounded,
                const Color(0xFFE74C3C)),
          ]),
        ],
      ),
    );
  }

  Widget _flowPill(String label, double value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ]),
            const SizedBox(height: 4),
            Text('₱${value.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  // ── QUICK LOG ─────────────────────────────────────────────
  Widget _quickLogSection() {
    final items = <Map<String, dynamic>>[
      {
        'title': 'Jeep Fare',
        'amount': 14.0,
        'cat': 'Transport',
        'icon': Icons.directions_bus_filled_rounded,
        'color': const Color(0xFF3498DB),
      },
      {
        'title': 'Lunch',
        'amount': 65.0,
        'cat': 'Food',
        'icon': Icons.lunch_dining_rounded,
        'color': const Color(0xFF2ECC71),
      },
      {
        'title': 'Snack',
        'amount': 25.0,
        'cat': 'Food',
        'icon': Icons.cookie_rounded,
        'color': const Color(0xFFF39C12),
      },
      {
        'title': 'Bus Fare',
        'amount': 30.0,
        'cat': 'Transport',
        'icon': Icons.train_rounded,
        'color': const Color(0xFF9B59B6),
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFF39C12), size: 20),
          const SizedBox(width: 4),
          _sectionLabel('Quick Log'),
          const SizedBox(width: 8),
          Text('tap to add instantly',
              style:
                  GoogleFonts.plusJakartaSans(fontSize: 11.5, color: cFaint)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final it = items[i];
              final color = it['color'] as Color;
              return GestureDetector(
                onTap: () => _addQuick(it['title'] as String,
                    it['amount'] as double, it['cat'] as String),
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(top: BorderSide(color: color, width: 3)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04), blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(11)),
                        child:
                            Icon(it['icon'] as IconData, color: color, size: 20),
                      ),
                      Text(it['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: cInk)),
                      Text('₱${(it['amount'] as double).toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: color)),
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

  // ── TOP CATEGORIES ────────────────────────────────────────
  Widget _topCategories() {
    if (_topCats.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
        decoration: _softCard(),
        child: Row(children: [
          Icon(Icons.insights_rounded, color: cFaint, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('No spending logged this week yet.',
                style:
                    GoogleFonts.plusJakartaSans(fontSize: 13, color: cSubtext)),
          ),
        ]),
      );
    }
    final maxVal = _topCats.first.value;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _softCard(),
      child: Column(
        children: List.generate(_topCats.length, (i) {
          final entry = _topCats[i];
          final data = ExpenseCard.categoryData[entry.key] ??
              ExpenseCard.categoryData['Other']!;
          final color = data['color'] as Color;
          final icon = data['icon'] as String;
          final pct = _weekCatTotal > 0
              ? (entry.value / _weekCatTotal * 100)
              : 0.0;
          final barFrac = maxVal > 0 ? (entry.value / maxVal) : 0.0;
          return Padding(
            padding: EdgeInsets.only(bottom: i == _topCats.length - 1 ? 0 : 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                      child:
                          Text(icon, style: const TextStyle(fontSize: 19))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: cInk)),
                          Text('₱${entry.value.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: cInk)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Stack(children: [
                        Container(
                            height: 7,
                            decoration: BoxDecoration(
                                color: cHairline,
                                borderRadius: BorderRadius.circular(8))),
                        FractionallySizedBox(
                          widthFactor: barFrac.clamp(0.04, 1.0),
                          child: Container(
                              height: 7,
                              decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8))),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('${pct.toStringAsFixed(0)}% of this week',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: cSubtext)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── SECTION LABEL ─────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w800, color: cInk));
  }

  // ── MONEY CARDS (budget + savings) ────────────────────────
  Widget _moneyCards(double weekProgress) {
    final saved = ((_savings['saved'] ?? 0.0) as num).toDouble();
    final target = ((_savings['target'] ?? 3000.0) as num).toDouble();
    final savingsProgress = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
    final budgetLeft = _weeklyBudget - _spentWeek;
    final toGo = target - saved;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _moneyCard(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF3498DB),
            title: 'Budget',
            progress: weekProgress,
            ringColor: budgetLeft < 0 ? const Color(0xFFE74C3C) : cAccent,
            value: '₱${_spentWeek.toStringAsFixed(0)}',
            sub: 'of ₱${_weeklyBudget.toStringAsFixed(0)} this week',
            footLabel: budgetLeft < 0 ? 'Over by' : 'Left',
            footValue: '₱${budgetLeft.abs().toStringAsFixed(0)}',
            footColor:
                budgetLeft < 0 ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChartsScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _moneyCard(
            icon: Icons.savings_rounded,
            iconColor: const Color(0xFF9B59B6),
            title: 'Savings',
            progress: savingsProgress,
            ringColor: const Color(0xFF9B59B6),
            value: '₱${saved.toStringAsFixed(0)}',
            sub: 'of ₱${target.toStringAsFixed(0)} goal',
            footLabel: toGo > 0 ? 'To go' : 'Reached',
            footValue: toGo > 0 ? '₱${toGo.toStringAsFixed(0)}' : '🎉',
            footColor: const Color(0xFF9B59B6),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SavingsScreen())),
          ),
        ),
      ],
    );
  }

  Widget _moneyCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required double progress,
    required Color ringColor,
    required String value,
    required String sub,
    required String footLabel,
    required String footValue,
    required Color footColor,
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
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cSubtext)),
              ],
            ),
            const SizedBox(height: 14),
            Center(child: _bigRing(progress, ringColor)),
            const SizedBox(height: 14),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800, color: cInk)),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    GoogleFonts.plusJakartaSans(fontSize: 11, color: cSubtext)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
              decoration: BoxDecoration(
                  color: footColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(footLabel,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: footColor)),
                  Text(footValue,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: footColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigRing(double progress, Color color) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress == 0 ? 0.02 : progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => CircularProgressIndicator(
                value: val,
                strokeWidth: 7,
                strokeCap: StrokeCap.round,
                backgroundColor: color.withOpacity(0.13),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          Text('${(progress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800, color: cInk)),
        ],
      ),
    );
  }

  // ── RECAP CARD ────────────────────────────────────────────
  Widget _recapCard() {
    final recap = _recap!;
    final saved = ((recap['leftover'] ?? 0.0) as num).toDouble();
    final range = (recap['range'] ?? '') as String;
    final canRoll = saved > 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cHeroGrad,
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
          Row(children: [
            GestureDetector(
              onTap: _dismissRecap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('Move to savings',
                      style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF1A2E1A),
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ),
            ],
          ]),
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
                  fontSize: 15, fontWeight: FontWeight.w800, color: cInk)),
          const SizedBox(height: 6),
          Text('Tap the + button to log your first one.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: cSubtext)),
        ],
      ),
    );
  }

  BoxDecoration _softCard() => BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cHairline),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      );
}

class _SparkPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  _SparkPainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final lo = points.reduce((a, b) => a < b ? a : b);
    final hi = points.reduce((a, b) => a > b ? a : b);
    final range = (hi - lo).abs() < 0.0001 ? 1.0 : (hi - lo);
    final dx = size.width / (points.length - 1);

    Offset at(int i) {
      final norm = (points[i] - lo) / range;
      return Offset(dx * i, size.height - (norm * (size.height - 6)) - 3);
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = at(i - 1);
      final p1 = at(i);
      final mx = (p0.dx + p1.dx) / 2;
      path.cubicTo(mx, p0.dy, mx, p1.dy, p1.dx, p1.dy);
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
          ).createShader(Offset.zero & size));

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final last = at(points.length - 1);
    canvas.drawCircle(last, 3.2, Paint()..color = color);
    canvas.drawCircle(last, 5.5, Paint()..color = color.withOpacity(0.18));
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.points != points || old.color != color;
}
