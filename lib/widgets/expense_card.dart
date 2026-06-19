import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../theme/theme_controller.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onDelete,
    this.onEdit,
  });

  static const Map<String, Map<String, dynamic>> categoryData = {
    'Food': {'icon': '🍱', 'color': Color(0xFF2ECC71)},
    'Transport': {'icon': '🚌', 'color': Color(0xFF3498DB)},
    'Supplies': {'icon': '📓', 'color': Color(0xFFF39C12)},
    'Entertainment': {'icon': '🎮', 'color': Color(0xFF9B59B6)},
    'Health': {'icon': '💊', 'color': Color(0xFFE74C3C)},
    'Other': {'icon': '📦', 'color': Color(0xFF95A5A6)},
  };

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    final time = DateFormat('h:mm a').format(d);
    if (diff == 0) return 'Today · $time';
    if (diff == 1) return 'Yesterday · $time';
    return '${DateFormat('MMM d').format(d)} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final cat = categoryData[expense.category] ?? categoryData['Other']!;
    final color = cat['color'] as Color;
    final icon = cat['icon'] as String;

    return Dismissible(
      key: Key(expense.date.toString() + expense.title + expense.amount.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete?.call();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE74C3C),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Delete',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            SizedBox(width: 16),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: cSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cHairline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 23)),
              ),
            ),
            const SizedBox(width: 12),

            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: cInk),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          expense.category,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          _dateLabel(expense.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5, color: cSubtext),
                        ),
                      ),
                    ],
                  ),
                  if (expense.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      expense.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: cFaint),
                    ),
                  ],
                ],
              ),
            ),

            // Receipt thumbnail
            if (expense.hasReceipt) ...[
              GestureDetector(
                onTap: () => _showReceipt(context),
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 10, left: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cHairline),
                    image: DecorationImage(
                      image: MemoryImage(base64Decode(expense.receipt!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],

            // Amount + edit
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-₱${expense.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      color: const Color(0xFFE74C3C)),
                ),
                if (onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Icon(Icons.edit_rounded,
                          size: 16, color: cFaint),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReceipt(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(base64Decode(expense.receipt!)),
          ),
        ),
      ),
    );
  }
}
