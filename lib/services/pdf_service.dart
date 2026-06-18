import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/expense.dart';
import 'storage_service.dart';

/// Builds a shareable PDF expense report with an integrity checksum and a
/// receipts appendix. Works on Android, iOS, and web (browser download).
class PdfService {
  static Future<void> exportExpenseReport() async {
    final doc = pw.Document();
    final expenses = StorageService.getExpenses()
      ..sort((a, b) => b.date.compareTo(a.date));
    final hash = StorageService.computeIntegrityHash();
    final dFmt = DateFormat('MMM d, yyyy');
    final tsFmt = DateFormat('MMM d, yyyy h:mm a');
    final name =
        Hive.box('budget').get('userName', defaultValue: 'BudgetMo user');

    double total = 0;
    final byCategory = <String, double>{};
    for (final e in expenses) {
      total += e.amount;
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }

    String range = '—';
    if (expenses.isNotEmpty) {
      final dates = expenses.map((e) => e.date).toList()..sort();
      range = '${dFmt.format(dates.first)} – ${dFmt.format(dates.last)}';
    }

    final green = PdfColor.fromHex('2ECC71');
    final ink = PdfColor.fromHex('1A2E1A');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BudgetMo — Expense Report',
                      style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: ink)),
                  pw.SizedBox(height: 4),
                  pw.Text('Account: $name',
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.Text('Period: $range',
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.Text('Generated: ${tsFmt.format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                    color: green,
                    borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TOTAL',
                        style: pw.TextStyle(
                            fontSize: 9, color: PdfColors.white)),
                    pw.Text('PHP ${total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: ink),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {
              3: pw.Alignment.centerRight,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
            },
            headers: [
              'Date',
              'Title',
              'Category',
              'Amount',
              'Logged',
              'Edits',
              'Receipt'
            ],
            data: expenses
                .map((e) => [
                      dFmt.format(e.date),
                      e.title,
                      e.category,
                      e.amount.toStringAsFixed(2),
                      tsFmt.format(e.createdAt),
                      e.editCount.toString(),
                      e.hasReceipt ? 'Yes' : '—',
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('By category',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          ...byCategory.entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(e.key,
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('PHP ${e.value.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              )),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Text('Record integrity',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text(
              'SHA-256 checksum of all ${expenses.length} entries. '
              'Re-run the export to confirm this value is unchanged; any '
              'altered amount, date, or receipt changes it.',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(hash,
              style: pw.TextStyle(
                  fontSize: 8, font: pw.Font.courier())),
        ],
      ),
    );

    // Receipts appendix — one image per receipt as evidence.
    final withReceipts = expenses.where((e) => e.hasReceipt).toList();
    if (withReceipts.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (ctx) => [
            pw.Text('Receipts appendix',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            ...withReceipts.map((e) {
              pw.Widget img;
              try {
                img = pw.Image(
                  pw.MemoryImage(base64Decode(e.receipt!)),
                  height: 220,
                  fit: pw.BoxFit.contain,
                );
              } catch (_) {
                img = pw.Text('(could not render receipt)');
              }
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                        '${e.title} · PHP ${e.amount.toStringAsFixed(2)} · ${dFmt.format(e.date)}',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    img,
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }

    await Printing.sharePdf(
        bytes: await doc.save(), filename: 'BudgetMo_Expense_Report.pdf');
  }
}
