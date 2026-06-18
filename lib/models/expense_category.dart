import 'package:flutter/material.dart';

class ExpenseCategory {
  final String name; // unique id
  final String emoji;
  final int colorValue;

  const ExpenseCategory({
    required this.name,
    required this.emoji,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() => {
        'name': name,
        'emoji': emoji,
        'colorValue': colorValue,
      };

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) =>
      ExpenseCategory(
        name: map['name'] as String,
        emoji: (map['emoji'] ?? '📦') as String,
        colorValue: (map['colorValue'] as num?)?.toInt() ??
            0xFF95A5A6,
      );

  static const List<ExpenseCategory> defaults = [
    ExpenseCategory(name: 'Food', emoji: '🍱', colorValue: 0xFF2ECC71),
    ExpenseCategory(
        name: 'Transport', emoji: '🚌', colorValue: 0xFF3498DB),
    ExpenseCategory(
        name: 'Supplies', emoji: '📓', colorValue: 0xFFF39C12),
    ExpenseCategory(
        name: 'Entertainment', emoji: '🎮', colorValue: 0xFF9B59B6),
    ExpenseCategory(name: 'Health', emoji: '💊', colorValue: 0xFFE74C3C),
    ExpenseCategory(name: 'Other', emoji: '📦', colorValue: 0xFF95A5A6),
  ];

  // A palette users can pick from when creating categories.
  static const List<int> palette = [
    0xFF2ECC71, 0xFF3498DB, 0xFFF39C12, 0xFF9B59B6,
    0xFFE74C3C, 0xFF1ABC9C, 0xFFE67E22, 0xFF34495E,
    0xFFFF6B9D, 0xFF16A085, 0xFF8E44AD, 0xFF2C3E50,
  ];

  static const List<String> emojiChoices = [
    '🍱','🚌','📓','🎮','💊','📦','☕','🛒','🏠','📱',
    '👕','🎁','⚽','💡','🐾','✈️','💅','🎬','📚','🍿',
  ];
}
