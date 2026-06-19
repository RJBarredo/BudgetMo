import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

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

  @override
  Widget build(BuildContext context) {
    final cat = categoryData[expense.category] ?? categoryData['Other']!;
    final color = cat['color'] as Color;
    final icon = cat['icon'] as String;
    final timeStr = DateFormat('h:mm a').format(expense.date);

    return Dismissible(
      key: Key(expense.date.toString() + expense.title + expense.amount.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete?.call();
        return false; // Let the parent handle deletion
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE74C3C),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            SizedBox(width: 16),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),

            // Title and details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF1A2E1A)),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          expense.category,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: Colors.black38),
                      ),
                      if (expense.note.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '· ${expense.note}',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, color: Colors.black38),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
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
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE6ECE8)),
                    image: DecorationImage(
                      image: MemoryImage(base64Decode(expense.receipt!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],

            // Amount + edit button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${expense.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFFE74C3C)),
                ),
                if (onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.edit_rounded,
                          size: 16, color: Colors.black26),
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