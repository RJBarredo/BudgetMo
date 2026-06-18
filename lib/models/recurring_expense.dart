class RecurringExpense {
  final String id;
  String title;
  double amount;
  String category;
  String frequency; // 'daily' | 'weekly' | 'monthly'
  DateTime nextDue;
  String note;

  RecurringExpense({
    String? id,
    required this.title,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.nextDue,
    this.note = '',
  }) : id = id ?? 'rec_${DateTime.now().microsecondsSinceEpoch}';

  String get frequencyLabel {
    switch (frequency) {
      case 'daily':
        return 'Every day';
      case 'monthly':
        return 'Every month';
      default:
        return 'Every week';
    }
  }

  DateTime advance(DateTime from) {
    switch (frequency) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'monthly':
        // Clamp day so e.g. Jan 31 -> Feb 28.
        final y = from.month == 12 ? from.year + 1 : from.year;
        final m = from.month == 12 ? 1 : from.month + 1;
        final lastDay = DateTime(y, m + 1, 0).day;
        final day = from.day > lastDay ? lastDay : from.day;
        return DateTime(y, m, day);
      default:
        return from.add(const Duration(days: 7));
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'frequency': frequency,
        'nextDue': nextDue.toIso8601String(),
        'note': note,
      };

  factory RecurringExpense.fromMap(Map<String, dynamic> map) =>
      RecurringExpense(
        id: map['id'] as String?,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        frequency: (map['frequency'] ?? 'weekly') as String,
        nextDue: DateTime.parse(map['nextDue'] as String),
        note: (map['note'] ?? '') as String,
      );
}
