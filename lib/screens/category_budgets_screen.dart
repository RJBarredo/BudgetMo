import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense_category.dart';
import '../services/storage_service.dart';
import '../theme/theme_controller.dart';

class CategoryBudgetsScreen extends StatefulWidget {
  const CategoryBudgetsScreen({super.key});

  @override
  State<CategoryBudgetsScreen> createState() =>
      _CategoryBudgetsScreenState();
}

class _CategoryBudgetsScreenState extends State<CategoryBudgetsScreen> {
  List<ExpenseCategory> _cats = [];
  Map<String, double> _budgets = {};
  Map<String, double> _spent = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _cats = StorageService.getCategories();
      _budgets = StorageService.getCategoryBudgets();
      _spent = StorageService.getWeeklyCategorySpending();
    });
  }

  void _editLimit(ExpenseCategory cat) {
    final ctrl = TextEditingController(
        text: (_budgets[cat.name] ?? 0) > 0
            ? _budgets[cat.name]!.toStringAsFixed(0)
            : '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('${cat.emoji}  ${cat.name} limit',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 17)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: GoogleFonts.plusJakartaSans(),
          decoration: InputDecoration(
            prefixText: '₱ ',
            hintText: 'Weekly limit (0 to remove)',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.black45))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: cAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final v = double.tryParse(ctrl.text) ?? 0;
              await StorageService.setCategoryBudget(cat.name, v);
              if (context.mounted) Navigator.pop(context);
              _load();
            },
            child: Text('Save',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Category budgets',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A2E1A))),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          Text('Set a weekly spending cap per category. Tap to edit.',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: Colors.black45)),
          const SizedBox(height: 14),
          ..._cats.map((cat) {
            final limit = _budgets[cat.name] ?? 0;
            final spent = _spent[cat.name] ?? 0;
            final hasLimit = limit > 0;
            final ratio =
                hasLimit ? (spent / limit).clamp(0.0, 1.0) : 0.0;
            final over = hasLimit && spent > limit;
            return GestureDetector(
              onTap: () => _editLimit(cat),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(cat.emoji,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(cat.name,
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: const Color(0xFF1A2E1A))),
                        const Spacer(),
                        Text(
                          hasLimit
                              ? '₱${spent.toStringAsFixed(0)} / ₱${limit.toStringAsFixed(0)}'
                              : 'No limit',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: over
                                  ? const Color(0xFFE74C3C)
                                  : Colors.black45),
                        ),
                      ],
                    ),
                    if (hasLimit) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFEFEFEF),
                          valueColor: AlwaysStoppedAnimation(
                            over
                                ? const Color(0xFFE74C3C)
                                : cat.color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
