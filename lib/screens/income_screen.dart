import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../services/storage_service.dart';
import 'add_income_screen.dart';
import '../theme/theme_controller.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  List<Income> _incomes = [];

  final Map<String, String> _sourceIcons = {
    'Allowance': '💵',
    'Salary': '💼',
    'Freelance': '🧑‍💻',
    'Gift': '🎁',
    'Refund': '↩️',
    'Other': '➕',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _incomes = StorageService.getIncomes();
    });
  }

  double get _totalAll =>
      _incomes.fold(0.0, (sum, e) => sum + e.amount);

  void _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Income?',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700)),
        content: Text('This cannot be undone.',
            style: GoogleFonts.plusJakartaSans()),
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
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text('Delete',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await StorageService.deleteIncome(id);
      _load();
    }
  }

  void _edit(Income income) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddIncomeScreen(existingIncome: income),
      ),
    );
    if (result == true) _load();
  }

  void _add() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Income>> grouped = {};
    for (final e in _incomes) {
      final key = DateFormat('MMMM dd, yyyy').format(e.date);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: const Color(0xFF1A2E1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Income',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A2E1A))),
      ),
      body: Column(
        children: [
          _buildSummary(),
          Expanded(
            child: _incomes.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                        20, 8, 20, 100),
                    children: grouped.entries.expand((entry) {
                      return [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          child: Text(entry.key,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black45)),
                        ),
                        ...entry.value
                            .map((income) => _incomeCard(income)),
                      ];
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: cAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Income',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildSummary() {
    final week = StorageService.getTotalIncomeThisWeek();
    final month = StorageService.getTotalIncomeThisMonth();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
          Text('Total income (all time)',
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 4),
          Text('₱${_totalAll.toStringAsFixed(2)}',
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1)),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat('This week', week),
              const SizedBox(width: 24),
              _miniStat('This month', month),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 2),
        Text('₱${value.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
                color: cAccent,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _incomeCard(Income income) {
    return Dismissible(
      key: ValueKey(income.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        _delete(income.id);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE74C3C),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded,
            color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _edit(income),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8)
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _sourceIcons[income.source] ?? '💵',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(income.source,
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: const Color(0xFF1A2E1A))),
                    if (income.note.isNotEmpty)
                      Text(income.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.black45)),
                  ],
                ),
              ),
              Text('+₱${income.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: cAccent)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💵', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text('No income yet',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black45)),
          const SizedBox(height: 6),
          Text('Log your allowance or salary to track net cash flow',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: Colors.black26)),
        ],
      ),
    );
  }
}
