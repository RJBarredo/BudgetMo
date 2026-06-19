import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/recurring_expense.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  static Color get green => const Color(0xFF2ECC71);
  static Color get ink => const Color(0xFF1A2E1A);
  List<RecurringExpense> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _items = StorageService.getRecurring());

  void _editSheet({RecurringExpense? existing}) {
    final titleCtrl =
        TextEditingController(text: existing?.title ?? '');
    final amountCtrl = TextEditingController(
        text: existing != null ? existing.amount.toStringAsFixed(0) : '');
    String category =
        existing?.category ?? StorageService.getCategories().first.name;
    String frequency = existing?.frequency ?? 'weekly';
    DateTime nextDue = existing?.nextDue ?? DateTime.now();
    final cats = StorageService.getCategories();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(existing == null ? 'New recurring' : 'Edit recurring',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                _field(titleCtrl, 'Title (e.g. Rent, Load)'),
                const SizedBox(height: 12),
                _field(amountCtrl, 'Amount', isNumber: true, prefix: '₱ '),
                const SizedBox(height: 16),
                Text('Frequency',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: ['daily', 'weekly', 'monthly'].map((f) {
                    final sel = frequency == f;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setS(() => frequency = f),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sel ? ink : const Color(0xFFF2F4F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            f[0].toUpperCase() + f.substring(1),
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: sel ? Colors.white : ink),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Category',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cats.map((c) {
                    final sel = category == c.name;
                    return GestureDetector(
                      onTap: () => setS(() => category = c.name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? ink : const Color(0xFFF2F4F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${c.emoji} ${c.name}',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : ink)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: nextDue,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setS(() => nextDue = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Next due',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, color: Colors.black45)),
                        Text(
                            DateFormat('MMM d, yyyy').format(nextDue),
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: ink)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    onPressed: () async {
                      final amt = double.tryParse(amountCtrl.text) ?? 0;
                      if (titleCtrl.text.trim().isEmpty || amt <= 0) {
                        return;
                      }
                      final r = RecurringExpense(
                        id: existing?.id,
                        title: titleCtrl.text.trim(),
                        amount: amt,
                        category: category,
                        frequency: frequency,
                        nextDue: nextDue,
                        note: existing?.note ?? '',
                      );
                      if (existing != null) {
                        await StorageService.updateRecurring(
                            existing.id, r);
                      } else {
                        await StorageService.addRecurring(r);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    },
                    child: Text('Save',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint,
      {bool isNumber = false, String? prefix}) {
    return TextField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.plusJakartaSans(),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        filled: true,
        fillColor: const Color(0xFFF2F4F2),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: appHeader(context, 'Recurring'),
      body: phoneWrap(_items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔁', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 12),
                  Text('No recurring expenses yet',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: Colors.black45)),
                  const SizedBox(height: 6),
                  Text('Add rent, load, or subscriptions — they\'ll\nlog themselves automatically.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: Colors.black26)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: _items.map((r) {
                final cat = StorageService.categoryFor(r.category);
                return Dismissible(
                  key: ValueKey(r.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await StorageService.deleteRecurring(r.id);
                    _load();
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 22),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE74C3C),
                        borderRadius: BorderRadius.circular(16)),
                    child:
                        const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  child: GestureDetector(
                    onTap: () => _editSheet(existing: r),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
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
                                color: cat.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(cat.emoji,
                                style: const TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(r.title,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: ink)),
                                Text(
                                    '${r.frequencyLabel} · next ${DateFormat('MMM d').format(r.nextDue)}',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: Colors.black45)),
                              ],
                            ),
                          ),
                          Text('₱${r.amount.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: ink)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editSheet(),
        backgroundColor: green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('New',
            style:
                GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
