import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_card.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> _expenses = [];
  List<Expense> _allExpenses = [];
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  List<String> get _categories =>
      ['All', ...StorageService.getCategories().map((c) => c.name)];

  static const Map<String, Map<String, dynamic>> _catMeta = {
    'All': {'icon': Icons.grid_view_rounded, 'color': Color(0xFF1A2E1A)},
    'Food': {'icon': Icons.lunch_dining_rounded, 'color': Color(0xFF2ECC71)},
    'Transport': {'icon': Icons.directions_bus_rounded, 'color': Color(0xFF3498DB)},
    'Supplies': {'icon': Icons.book_rounded, 'color': Color(0xFFF39C12)},
    'Entertainment': {'icon': Icons.sports_esports_rounded, 'color': Color(0xFF9B59B6)},
    'Health': {'icon': Icons.medical_services_rounded, 'color': Color(0xFFE74C3C)},
    'Other': {'icon': Icons.category_rounded, 'color': Color(0xFF95A5A6)},
  };

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_filterExpenses);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _allExpenses = StorageService.getExpenses();
      _filterExpenses();
    });
  }

  void _filterExpenses() {
    setState(() {
      _expenses = StorageService.searchExpenses(
        _searchController.text,
        category: _selectedCategory,
      );
    });
  }

  void _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Expense?',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700)),
        content: Text('This cannot be undone.',
            style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: cSubtext)),
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
      await StorageService.deleteExpense(id);
      _load();
    }
  }

  void _edit(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          existingExpense: expense,
        ),
      ),
    );
    if (result == true) _load();
  }

  double get _totalShown =>
      _expenses.fold(0.0, (sum, e) => sum + e.amount);

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Expense>> grouped = {};
    for (final e in _expenses) {
      final key = DateFormat('MMMM dd, yyyy').format(e.date);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    return Scaffold(
      backgroundColor: AppPalette.of(context).bg,
      appBar: appHeader(context, 'Expenses', actions: [
        if (_expenses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₱${_totalShown.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 14),
                ),
              ),
            ),
          ),
      ]),
      body: phoneWrap(Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(
                20, 0, 20, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6)
                ],
              ),
              child: TextField(
                controller: _searchController,
                style:
                GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search expenses...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                      color: Colors.black26),
                  prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.black26),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Category filter
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                final meta = _catMeta[cat] ?? {'icon': Icons.category_rounded, 'color': const Color(0xFF95A5A6)};
                final color = meta['color'] as Color;

                return GestureDetector(
                  onTap: () {
                    setState(
                            () => _selectedCategory = cat);
                    _filterExpenses();
                  },
                  child: AnimatedContainer(
                    duration:
                    const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? color
                          : Colors.white,
                      borderRadius:
                      BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black
                                .withOpacity(0.04),
                            blurRadius: 4)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon((meta['icon'] ?? Icons.category_rounded) as IconData,
                            size: 14,
                            color: selected
                                ? Colors.white
                                : color),
                        const SizedBox(width: 5),
                        Text(cat,
                            style:
                            GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : cSubtext,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          if (_allExpenses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.swipe_left_rounded,
                      size: 14, color: Colors.black26),
                  const SizedBox(width: 4),
                  Text(
                      'Swipe left to delete  •  Tap ✏️ to edit',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.black26)),
                ],
              ),
            ),

          // List
          Expanded(
            child: _expenses.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  20, 8, 20, 80),
              itemCount: grouped.keys.length,
              itemBuilder: (context, i) {
                final date =
                grouped.keys.toList()[i];
                final items = grouped[date]!;
                final dayTotal = items.fold(
                    0.0, (sum, e) => sum + e.amount);

                return Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(
                          vertical: 10),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [
                          Text(date,
                              style: GoogleFonts
                                  .plusJakartaSans(
                                  fontWeight:
                                  FontWeight
                                      .w700,
                                  fontSize: 13,
                                  color: Colors
                                      .black45)),
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                                horizontal: 8,
                                vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(
                                  0xFFE74C3C)
                                  .withOpacity(0.1),
                              borderRadius:
                              BorderRadius
                                  .circular(6),
                            ),
                            child: Text(
                                '₱${dayTotal.toStringAsFixed(2)}',
                                style: GoogleFonts
                                    .plusJakartaSans(
                                    fontWeight:
                                    FontWeight
                                        .w700,
                                    fontSize: 12,
                                    color: const Color(
                                        0xFFE74C3C))),
                          ),
                        ],
                      ),
                    ),
                    ...items.map((expense) {
                      return ExpenseCard(
                        expense: expense,
                        onDelete: () => _delete(expense.id),
                        onEdit: () => _edit(expense),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                  const AddExpenseScreen()));
          if (result == true) _load();
        },
        backgroundColor: const Color(0xFF2ECC71),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 44,
                color: Color(0xFF2ECC71)),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No results found'
                : 'No expenses yet',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cSubtext),
          ),
          const SizedBox(height: 6),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search term'
                : 'Start tracking your spending today',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: Colors.black26),
          ),
          if (_searchController.text.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                        const AddExpenseScreen()));
                if (result == true) _load();
              },
              icon: const Icon(Icons.add_rounded,
                  size: 18),
              label: Text('Add First Expense',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}