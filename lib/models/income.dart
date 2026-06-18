class Income {
  final String id;
  String source;
  double amount;
  DateTime date;
  String note;

  Income({
    String? id,
    required this.source,
    required this.amount,
    required this.date,
    this.note = '',
  }) : id = id ?? _generateId();

  static int _counter = 0;
  static String _generateId() =>
      'inc_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source': source,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as String?,
      source: map['source'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] ?? '') as String,
    );
  }
}
