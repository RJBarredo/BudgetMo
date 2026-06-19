import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../models/expense.dart';
import '../widgets/animations.dart';
import '../widgets/app_header.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  bool _showMonthly = false;
  int _touchedIndex = -1;
  List<Expense> _allExpenses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _allExpenses = StorageService.getExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final byCategory = _showMonthly
        ? StorageService.getMonthlySpendingByCategory()
        : StorageService.getSpendingByCategory();
    final barData = _showMonthly
        ? StorageService.getMonthlySpending()
        : StorageService.getLast7DaysSpending();
    final maxBar = barData.values.isEmpty
        ? 100.0
        : barData.values.reduce((a, b) => a > b ? a : b);

    final totalSpent = _showMonthly
        ? StorageService.getTotalSpentThisMonth()
        : StorageService.getTotalSpentThisWeek();

    final income = _showMonthly
        ? StorageService.getTotalIncomeThisMonth()
        : StorageService.getTotalIncomeThisWeek();
    final net = income - totalSpent;

    final hasData = _allExpenses.isNotEmpty || income > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: appHeader(context, 'Charts'),
      body: phoneWrap(!hasData
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 12),
            Text('No data yet — add some expenses first!',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.black45, fontSize: 14)),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle
            _buildToggle(),
            const SizedBox(height: 20),

            // Total summary card
            _buildSummaryCard(totalSpent, income, net),
            const SizedBox(height: 20),

            // Income vs Spending
            _sectionTitle('Income vs Spending'),
            const SizedBox(height: 12),
            _buildIncomeVsSpending(income, totalSpent),
            const SizedBox(height: 20),

            // Pie chart
            if (byCategory.isNotEmpty) ...[
              _sectionTitle('Spending by Category'),
              const SizedBox(height: 12),
              _buildPieCard(byCategory),
              const SizedBox(height: 20),
            ],

            // Bar chart
            _sectionTitle(
                _showMonthly ? 'Monthly Spending' : 'Daily Spending (Last 7 Days)'),
            const SizedBox(height: 12),
            _buildBarCard(barData, maxBar),
            const SizedBox(height: 20),

            // Category breakdown
            _sectionTitle('Category Breakdown'),
            const SizedBox(height: 12),
            _buildCategoryList(byCategory),
            const SizedBox(height: 80),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          _toggleBtn('This Week', !_showMonthly),
          _toggleBtn('This Month', _showMonthly),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showMonthly = label == 'This Month'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1A2E1A) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: active ? Colors.white : Colors.black45,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double total, double income, double net) {
    final positive = net >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF12280F), const Color(0xFF2D5A2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _showMonthly ? 'Spent This Month' : 'Spent This Week',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 4),
          AnimatedCount(
            value: total,
            decimals: 2,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 14),
          Row(
            children: [
              _summaryStat('Income', income, const Color(0xFF7BE495)),
              const SizedBox(width: 20),
              _summaryStat(
                'Net',
                net,
                positive
                    ? const Color(0xFF7BE495)
                    : const Color(0xFFFF8A80),
                signed: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, double value, Color color,
      {bool signed = false}) {
    final prefix = signed && value < 0 ? '-₱' : '₱';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 2),
        AnimatedCount(
          value: value.abs(),
          prefix: prefix,
          decimals: 0,
          style: GoogleFonts.plusJakartaSans(
              color: color, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildIncomeVsSpending(double income, double spent) {
    final maxVal = [income, spent, 1.0].reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          _compRow('Income', income, maxVal, const Color(0xFF2ECC71)),
          const SizedBox(height: 16),
          _compRow('Spending', spent, maxVal, const Color(0xFFE74C3C)),
        ],
      ),
    );
  }

  Widget _compRow(String label, double value, double maxVal, Color color) {
    final fraction = (value / maxVal).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A2E1A))),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            return Stack(
              children: [
                Container(
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, f, _) => Container(
                    height: 26,
                    width: c.maxWidth * f,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.7), color],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 64,
          child: AnimatedCount(
            value: value,
            decimals: 0,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A2E1A)),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: const Color(0xFF1A2E1A)));
  }

  Widget _buildPieCard(Map<String, double> byCategory) {
    final total = byCategory.values.fold(0.0, (a, b) => a + b);
    final sections = byCategory.entries.toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: sections.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cat = entry.value.key;
                  final val = entry.value.value;
                  final isTouched = i == _touchedIndex;
                  final color =
                      StorageService.colorFor(cat);
                  return PieChartSectionData(
                    value: val,
                    color: color,
                    radius: isTouched ? 70 : 55,
                    title: isTouched
                        ? '₱${val.toStringAsFixed(0)}'
                        : '${(val / total * 100).toStringAsFixed(0)}%',
                    titleStyle: GoogleFonts.plusJakartaSans(
                      fontSize: isTouched ? 13 : 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 3,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: sections.map((entry) {
              final color =
                  StorageService.colorFor(entry.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(entry.key,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: Colors.black45)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarCard(Map<String, double> data, double maxBar) {
    final keys = data.keys.toList();
    final values = data.values.toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxBar == 0 ? 100 : maxBar * 1.3,
            barGroups: keys.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: values[entry.key],
                    color: const Color(0xFF2ECC71),
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxBar == 0 ? 100 : maxBar * 1.3,
                      color: const Color(0xFFF0F0F0),
                    ),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= keys.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(keys[idx],
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: Colors.black45)),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxBar == 0 ? 25 : maxBar / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.black.withOpacity(0.05),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '₱${rod.toY.toStringAsFixed(0)}',
                    GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(Map<String, double> byCategory) {
    final total = byCategory.values.fold(0.0, (a, b) => a + b);
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((entry) {
        final color =
            StorageService.colorFor(entry.key);
        final pct = total > 0 ? entry.value / total : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 6)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key,
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF1A2E1A))),
                  Text('₱${entry.value.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: color)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: color.withOpacity(0.1),
                  color: color,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                  '${(pct * 100).toStringAsFixed(1)}% of total spending',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: Colors.black45)),
            ],
          ),
        );
      }).toList(),
    );
  }
}