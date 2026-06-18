import 'dart:convert';
import 'package:crypto/crypto.dart';

class Expense {
  final String id;
  String title;
  double amount;
  String category;
  DateTime date;
  String note;
  String? receipt; // base64-encoded receipt photo (optional)

  // Integrity / audit fields
  final DateTime createdAt; // when it was actually logged (immutable)
  DateTime modifiedAt; // last time it was changed
  List<String> history; // append-only audit trail

  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
    this.receipt,
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<String>? history,
  })  : id = id ?? _generateId(),
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? createdAt ?? DateTime.now(),
        history = history ?? [];

  static int _counter = 0;
  static String _generateId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  bool get hasReceipt => receipt != null && receipt!.isNotEmpty;

  // Stable string used for integrity hashing. Any change to a logged
  // field (including swapping/removing the receipt) changes this string.
  String integritySignature() {
    final receiptFingerprint = hasReceipt
        ? sha256.convert(utf8.encode(receipt!)).toString().substring(0, 16)
        : '-';
    return '$id|${amount.toStringAsFixed(2)}|${date.toIso8601String()}'
        '|${createdAt.toIso8601String()}|$category|$title|$receiptFingerprint';
  }

  bool get wasEdited => history.length > 1;
  int get editCount => history.isEmpty ? 0 : history.length - 1;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'receipt': receipt,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'history': history,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    final dateStr = map['date'] as String;
    return Expense(
      id: map['id'] as String?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: DateTime.parse(dateStr),
      note: (map['note'] ?? '') as String,
      receipt: map['receipt'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.parse(dateStr),
      modifiedAt: map['modifiedAt'] != null
          ? DateTime.parse(map['modifiedAt'] as String)
          : DateTime.parse(dateStr),
      history: (map['history'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
    );
  }
}
