import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';
import '../theme/app_theme.dart';

class IntegrityScreen extends StatelessWidget {
  const IntegrityScreen({super.key});

  static Color get ink => cInk;
  static Color get green => cAccent;

  @override
  Widget build(BuildContext context) {
    final expenses = StorageService.getExpenses();
    final deleted = StorageService.getDeletedLog();
    final hash = StorageService.computeIntegrityHash();
    final fmt = DateFormat('MMM d, yyyy · h:mm a');
    String range = '—';
    if (expenses.isNotEmpty) {
      final dates = expenses.map((e) => e.date).toList()..sort();
      range =
          '${DateFormat('MMM d, yyyy').format(dates.first)} – ${DateFormat('MMM d, yyyy').format(dates.last)}';
    }

    return Scaffold(
      backgroundColor: AppPalette.of(context).bg,
      appBar: appHeader(context, 'Record & integrity'),
      body: phoneWrap(ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
        children: [
          // Summary / checksum card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cSurface,
              borderRadius: BorderRadius.circular(18),
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
                    Icon(Icons.verified_rounded,
                        color: green, size: 22),
                    const SizedBox(width: 8),
                    Text('Record summary',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: ink)),
                  ],
                ),
                const SizedBox(height: 14),
                _row('Total records', '${expenses.length}'),
                _row('Date range', range),
                _row('Generated', fmt.format(DateTime.now())),
                const SizedBox(height: 14),
                Text('Integrity checksum (SHA-256)',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: cSubtext)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(hash,
                      style: GoogleFonts.robotoMono(fontSize: 11)),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: hash));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: const Text('Checksum copied'),
                              backgroundColor: green),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text('Copy checksum',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Each expense records when it was logged and every edit since. '
              'The checksum is computed from all entries — if any logged amount, '
              'date, or detail is changed, the checksum changes too. Share the '
              'CSV export (which includes this checksum) so a reviewer can verify '
              'the record hasn\'t been altered.',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5, height: 1.45, color: const Color(0xFF35433A)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Entry history',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: ink)),
          const SizedBox(height: 10),
          if (expenses.isEmpty)
            Text('No expenses yet.',
                style: GoogleFonts.plusJakartaSans(
                    color: cSubtext))
          else
            ...expenses.map((e) => _entry(e, fmt)),

          if (deleted.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Deleted entries (${deleted.length})',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: const Color(0xFFE74C3C))),
            const SizedBox(height: 10),
            ...deleted.reversed.map((d) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_pretty(d),
                      style: GoogleFonts.robotoMono(
                          fontSize: 11, color: const Color(0xFF7A2018))),
                )),
          ],
        ],
      )),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: cSubtext)),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ink)),
            ),
          ],
        ),
      );

  Widget _entry(Expense e, DateFormat fmt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)
        ],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding:
              const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Text(e.title,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: ink)),
          subtitle: Text(
            'Logged ${fmt.format(e.createdAt)}'
            '${e.wasEdited ? '  ·  edited ${e.editCount}×' : ''}',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: e.wasEdited
                    ? const Color(0xFFE67E22)
                    : cSubtext),
          ),
          trailing: Text('₱${e.amount.toStringAsFixed(2)}',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800, color: ink)),
          children: e.history
              .map((h) => Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('• ${_pretty(h)}',
                          style: GoogleFonts.robotoMono(
                              fontSize: 11, color: cSubtext)),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // Turn the ISO timestamp prefix into a friendlier date.
  String _pretty(String entry) {
    final parts = entry.split(' · ');
    if (parts.isEmpty) return entry;
    try {
      final dt = DateTime.parse(parts.first);
      final nice = DateFormat('MMM d, yyyy h:mm a').format(dt);
      return '$nice · ${parts.sublist(1).join(' · ')}';
    } catch (_) {
      return entry;
    }
  }
}
