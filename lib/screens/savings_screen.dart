import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _goals = [];
  int _activeGoalIndex = 0;
  bool _showConfetti = false;
  late AnimationController _confettiController;

  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _addCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _load();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _addCtrl.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _goals = StorageService.getAllSavingsGoals();
      if (_goals.isEmpty) {
        _goals = [StorageService.getSavingsGoal()];
      }
      if (_activeGoalIndex >= _goals.length) {
        _activeGoalIndex = 0;
      }
      if (_goals.isNotEmpty) {
        _nameCtrl.text = _goals[_activeGoalIndex]['name'] ?? '';
        _targetCtrl.text =
            (_goals[_activeGoalIndex]['target'] ?? 3000.0).toString();
      }
    });
  }

  void _addSavings() async {
    final amount = double.tryParse(_addCtrl.text);
    if (amount == null || amount <= 0) return;

    await StorageService.addToSavingsGoal(_activeGoalIndex, amount);
    _addCtrl.clear();
    _load();

    // Check if goal completed
    final goal = _goals[_activeGoalIndex];
    final saved = ((goal['saved'] ?? 0.0) as num).toDouble();
    final target = ((goal['target'] ?? 1.0) as num).toDouble();
    if (saved >= target) {
      setState(() => _showConfetti = true);
      _confettiController.forward(from: 0);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showConfetti = false);
      });
    }
  }

  void _updateGoal() async {
    final target = double.tryParse(_targetCtrl.text);
    if (_nameCtrl.text.isEmpty || target == null) return;
    await StorageService.updateSavingsGoal(
        _activeGoalIndex, _nameCtrl.text.trim(), target);
    _load();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Goal updated!',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _addNewGoal() async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('New Savings Goal',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogInput(nameCtrl, 'Goal name (e.g. New Phone)'),
            const SizedBox(height: 12),
            _dialogInput(targetCtrl, 'Target amount',
                isNumber: true),
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
            child: Text('Add Goal',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final target = double.tryParse(targetCtrl.text);
      if (nameCtrl.text.isNotEmpty && target != null) {
        await StorageService.addSavingsGoal(
            nameCtrl.text.trim(), target);
        _load();
      }
    }
  }

  void _deleteGoal(int index) async {
    if (_goals.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need at least one goal!',
              style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    await StorageService.deleteSavingsGoal(index);
    setState(() {
      if (_activeGoalIndex >= _goals.length - 1) {
        _activeGoalIndex = _goals.length - 2;
      }
    });
    _load();
  }

  Widget _dialogInput(TextEditingController ctrl, String hint,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType:
      isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        GoogleFonts.plusJakartaSans(color: Colors.black26),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spentWeek = StorageService.getTotalSpentThisWeek();
    final spentMonth = StorageService.getTotalSpentThisMonth();
    final totalSaved = _goals.fold(
        0.0, (sum, g) => sum + ((g['saved'] ?? 0.0) as num).toDouble());

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F7F5),
          appBar: appHeader(context, 'Savings', actions: [
            IconButton(
              onPressed: _addNewGoal,
              icon: const Icon(Icons.add_circle_rounded,
                  color: Colors.white),
              tooltip: 'Add new goal',
            ),
          ]),
          body: phoneWrap(SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                _buildSummaryCard(
                    spentWeek, spentMonth, totalSaved),
                const SizedBox(height: 16),

                // Goal tabs
                if (_goals.length > 1) ...[
                  _buildGoalTabs(),
                  const SizedBox(height: 16),
                ],

                // Active goal card
                if (_goals.isNotEmpty) ...[
                  _buildGoalCard(),
                  const SizedBox(height: 16),
                  _buildAddSavingsCard(),
                  const SizedBox(height: 16),
                  _buildEditGoalCard(),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
          ),
        ),

        // Confetti overlay
        if (_showConfetti) _buildConfettiOverlay(),
      ],
    );
  }

  Widget _buildSummaryCard(
      double spentWeek, double spentMonth, double totalSaved) {
    final allExpenses = StorageService.getExpenses();
    final totalAllTime =
    allExpenses.fold(0.0, (sum, e) => sum + e.amount);

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
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1A2E1A).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending Summary',
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryItem(
                  'This Week', '₱${spentWeek.toStringAsFixed(0)}',
                  const Color(0xFF2ECC71)),
              _summaryDivider(),
              _summaryItem(
                  'This Month', '₱${spentMonth.toStringAsFixed(0)}',
                  const Color(0xFF3498DB)),
              _summaryDivider(),
              _summaryItem(
                  'All Time', '₱${totalAllTime.toStringAsFixed(0)}',
                  const Color(0xFFF39C12)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.savings_rounded,
                        color: Color(0xFFF39C12), size: 18),
                    const SizedBox(width: 8),
                    Text('Total Saved Across All Goals',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white60,
                            fontSize: 12)),
                  ],
                ),
                Text('₱${totalSaved.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFF39C12),
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
      String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(
        width: 1, height: 32, color: Colors.white12);
  }

  Widget _buildGoalTabs() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _goals.length,
        itemBuilder: (context, i) {
          final goal = _goals[i];
          final active = i == _activeGoalIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeGoalIndex = i;
                _nameCtrl.text = goal['name'] ?? '';
                _targetCtrl.text =
                    (goal['target'] ?? 3000.0).toString();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF1A2E1A)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4)
                ],
              ),
              child: Text(goal['name'] ?? 'Goal ${i + 1}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? Colors.white
                          : Colors.black45)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalCard() {
    final goal = _goals[_activeGoalIndex];
    final saved = ((goal['saved'] ?? 0.0) as num).toDouble();
    final target = ((goal['target'] ?? 3000.0) as num).toDouble();
    final progress =
    target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
    final isComplete = progress >= 1.0;
    final remaining = target - saved;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isComplete
              ? [const Color(0xFFFF8F00), const Color(0xFFFFC107)]
              : [const Color(0xFF12280F), const Color(0xFF2D5A2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: (isComplete
                  ? const Color(0xFFFF8F00)
                  : const Color(0xFF12280F))
                  .withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(isComplete ? '🏆' : '🎯',
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(goal['name'] ?? 'My Goal',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17)),
                ],
              ),
              if (_goals.length > 1)
                GestureDetector(
                  onTap: () =>
                      _deleteGoal(_activeGoalIndex),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_rounded,
                        color: Colors.white70, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₱${saved.toStringAsFixed(2)} saved',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70, fontSize: 13)),
              Text('₱${target.toStringAsFixed(2)} goal',
                  style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF2ECC71),
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                height: 14,
                width: progress == 0
                    ? 6
                    : (MediaQuery.of(context).size.width -
                    84) *
                    progress,
                decoration: BoxDecoration(
                  color: isComplete
                      ? Colors.white
                      : const Color(0xFF2ECC71),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isComplete
                    ? '🎉 Goal achieved!'
                    : '${(progress * 100).toStringAsFixed(1)}% achieved',
                style: GoogleFonts.plusJakartaSans(
                    color: isComplete
                        ? Colors.white
                        : const Color(0xFF2ECC71),
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
              if (!isComplete)
                Text(
                  '₱${remaining.toStringAsFixed(0)} to go',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white54, fontSize: 12),
                ),
            ],
          ),
          if (saved == 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '💪 Every peso counts! Start saving today.',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddSavingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Color(0xFF2ECC71), size: 20),
              ),
              const SizedBox(width: 10),
              Text('Add to Savings',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: const Color(0xFF1A2E1A))),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF2ECC71)
                      .withOpacity(0.3)),
            ),
            child: TextField(
              controller: _addCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: GoogleFonts.plusJakartaSans(
                    color: Colors.black26,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                prefixText: '₱ ',
                prefixStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2ECC71)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Quick amount buttons
          Row(
            children: ['50', '100', '200', '500'].map((v) {
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _addCtrl.text = v),
                  child: Container(
                    margin: EdgeInsets.only(
                        right: v == '500' ? 0 : 8),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8),
                    decoration: BoxDecoration(
                      color: _addCtrl.text == v
                          ? const Color(0xFF2ECC71)
                          .withOpacity(0.15)
                          : const Color(0xFFF5F7F5),
                      borderRadius:
                      BorderRadius.circular(8),
                      border: Border.all(
                          color: _addCtrl.text == v
                              ? const Color(0xFF2ECC71)
                              : Colors.transparent),
                    ),
                    child: Text('₱$v',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _addCtrl.text == v
                                ? const Color(0xFF2ECC71)
                                : Colors.black45)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _addSavings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Add to Savings',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditGoalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF3498DB)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded,
                    color: Color(0xFF3498DB), size: 20),
              ),
              const SizedBox(width: 10),
              Text('Edit Goal',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: const Color(0xFF1A2E1A))),
            ],
          ),
          const SizedBox(height: 16),
          _fieldLabel('Goal Name'),
          _inputField(_nameCtrl, 'e.g. New Phone'),
          const SizedBox(height: 12),
          _fieldLabel('Target Amount (₱)'),
          _inputField(_targetCtrl, 'e.g. 5000',
              isNumber: true),
          const SizedBox(height: 16),
          // Goal presets
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              '📱 New Phone',
              '✈️ Trip',
              '🎮 Gadget',
              '👟 Shoes',
              '📚 Books',
              '💻 Laptop',
            ].map((v) {
              final label =
              v.split(' ').skip(1).join(' ');
              return GestureDetector(
                onTap: () =>
                    setState(() => _nameCtrl.text = label),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _nameCtrl.text == label
                        ? const Color(0xFF1A2E1A)
                        : const Color(0xFFF5F7F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(v,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _nameCtrl.text == label
                              ? Colors.white
                              : Colors.black45)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _updateGoal,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: Color(0xFF2ECC71), width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Update Goal',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2ECC71),
                      fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black45)),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint,
      {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType:
        isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.plusJakartaSans(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          GoogleFonts.plusJakartaSans(color: Colors.black26),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // Simple CSS-style confetti overlay
  Widget _buildConfettiOverlay() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return IgnorePointer(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: _ConfettiPainter(
                  _confettiController.value),
            ),
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final List<Map<String, dynamic>> _particles = List.generate(
    60,
        (i) => {
      'x': (i * 37.3) % 1.0,
      'speed': 0.3 + (i * 0.013) % 0.7,
      'color': [
        const Color(0xFF2ECC71),
        const Color(0xFFF39C12),
        const Color(0xFF3498DB),
        const Color(0xFFE74C3C),
        const Color(0xFF9B59B6),
        Colors.white,
      ][i % 6],
      'size': 4.0 + (i * 2.1) % 8.0,
      'rotation': (i * 0.4) % 1.0,
    },
  );

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final x = (p['x'] as double) * size.width;
      final y = (p['speed'] as double) * progress * size.height * 1.5;
      if (y > size.height) continue;

      final paint = Paint()
        ..color = (p['color'] as Color)
            .withOpacity(1.0 - progress * 0.8);
      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: p['size'] as double,
        height: (p['size'] as double) * 0.6,
      );
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((p['rotation'] as double) *
          progress *
          6.28);
      canvas.translate(-x, -y);
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.progress != progress;
}