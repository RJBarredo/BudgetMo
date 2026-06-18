import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart' show Color;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/expense_category.dart';
import '../models/recurring_expense.dart';

class StorageService {
  static const String _expenseBox = 'expenses';
  static const String _incomeBox = 'income';
  static const String _budgetBox = 'budget';
  static const String _savingsBox = 'savings';
  static const String _metaBox = 'meta';

  // ─── INIT ────────────────────────────────────────────────

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_expenseBox);
    await Hive.openBox(_incomeBox);
    await Hive.openBox(_budgetBox);
    await Hive.openBox(_savingsBox);
    await Hive.openBox(_metaBox);
    await _migrateExpenseIds();
    await _migrateExpenseAudit();
    await _applyDueRecurring();
    await _checkWeeklyReset();
  }

  // Backfill timestamps + history onto records saved before these existed.
  static Future<void> _migrateExpenseAudit() async {
    final box = Hive.box(_expenseBox);
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      final map = Map<String, dynamic>.from(raw);
      if (map['createdAt'] == null || map['history'] == null) {
        final e = Expense.fromMap(map);
        if (e.history.isEmpty) {
          e.history.add(
              '${e.date.toIso8601String()} · created (migrated record)');
        }
        await box.put(key, e.toMap());
      }
    }
  }

  // ─── RECURRING EXPENSES ──────────────────────────────────

  static List<RecurringExpense> getRecurring() {
    final raw = Hive.box(_metaBox).get('recurring');
    if (raw == null) return [];
    return (raw as List)
        .map((e) =>
            RecurringExpense.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> _saveRecurring(
      List<RecurringExpense> items) async {
    await Hive.box(_metaBox)
        .put('recurring', items.map((e) => e.toMap()).toList());
  }

  static Future<void> addRecurring(RecurringExpense r) async {
    final items = getRecurring()..add(r);
    await _saveRecurring(items);
    await _applyDueRecurring();
  }

  static Future<void> updateRecurring(
      String id, RecurringExpense r) async {
    final items =
        getRecurring().map((x) => x.id == id ? r : x).toList();
    await _saveRecurring(items);
  }

  static Future<void> deleteRecurring(String id) async {
    final items = getRecurring().where((x) => x.id != id).toList();
    await _saveRecurring(items);
  }

  // Creates real expenses for any recurring item whose due date has passed,
  // advancing each forward until it's in the future. Runs at startup.
  static Future<void> _applyDueRecurring() async {
    final items = getRecurring();
    if (items.isEmpty) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool changed = false;

    for (final r in items) {
      var guard = 0;
      while (!r.nextDue.isAfter(today) && guard < 400) {
        await addExpense(Expense(
          title: r.title,
          amount: r.amount,
          category: r.category,
          date: r.nextDue,
          note: r.note.isEmpty ? '(recurring)' : '${r.note} (recurring)',
        ));
        r.nextDue = r.advance(r.nextDue);
        changed = true;
        guard++;
      }
    }
    if (changed) await _saveRecurring(items);
  }

  // ─── NO-SPEND STREAK ─────────────────────────────────────

  // Consecutive days (ending today or yesterday) with no expenses logged.
  static int getNoSpendStreak() {
    final expenses = getExpenses();
    final daysWithSpend = <String>{};
    for (final e in expenses) {
      daysWithSpend
          .add('${e.date.year}-${e.date.month}-${e.date.day}');
    }
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final d = now.subtract(Duration(days: i));
      final key = '${d.year}-${d.month}-${d.day}';
      if (daysWithSpend.contains(key)) {
        // Today still counts as "no spend yet" only if i>0; if today has
        // spend, streak is broken at 0.
        if (i == 0) return 0;
        break;
      }
      streak++;
    }
    return streak;
  }

  // ─── MIGRATION ───────────────────────────────────────────
  // Records created before the `id` field existed get a stable id
  // written back once, so edit/delete can key on id reliably.

  static Future<void> _migrateExpenseIds() async {
    final box = Hive.box(_expenseBox);
    for (final key in box.keys.toList()) {
      final raw = box.get(key);
      if (raw == null) continue;
      final map = Map<String, dynamic>.from(raw);
      if (map['id'] == null) {
        map['id'] =
            'legacy_${key}_${DateTime.now().microsecondsSinceEpoch}';
        await box.put(key, map);
      }
    }
  }

  // ─── AUTO RESET EVERY MONDAY ─────────────────────────────

  static Future<void> _checkWeeklyReset() async {
    final box = Hive.box(_budgetBox);
    final lastReset = box.get('lastReset');
    final now = DateTime.now();
    final lastMonday =
    now.subtract(Duration(days: now.weekday - 1));
    final lastMondayDate = DateTime(
        lastMonday.year, lastMonday.month, lastMonday.day);

    if (lastReset == null) {
      box.put('lastReset', lastMondayDate.toIso8601String());
      return;
    }

    final lastResetDate = DateTime.parse(lastReset);
    if (lastMondayDate.isAfter(lastResetDate)) {
      // The week that just ended runs [lastResetDate, lastMondayDate).
      final spent = getSpentInRange(lastResetDate, lastMondayDate);
      final income = getIncomeInRange(lastResetDate, lastMondayDate);
      final budget = getWeeklyBudget();
      final leftover = budget - spent;

      // Stash a one-time recap for the Home screen to surface.
      await box.put('pendingRecap', {
        'weekStart': lastResetDate.toIso8601String(),
        'weekEnd': lastMondayDate.toIso8601String(),
        'spent': spent,
        'income': income,
        'budget': budget,
        'leftover': leftover > 0 ? leftover : 0.0,
      });

      box.put('lastReset', lastMondayDate.toIso8601String());
      box.put('weekResetCount',
          (box.get('weekResetCount', defaultValue: 0)) + 1);
    }
  }

  // ─── WEEKLY RECAP ────────────────────────────────────────

  static Map<String, dynamic>? getPendingRecap() {
    final raw = Hive.box(_budgetBox).get('pendingRecap');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  static Future<void> clearPendingRecap() async {
    await Hive.box(_budgetBox).delete('pendingRecap');
  }

  // Moves the recap's leftover into the first savings goal, then clears it.
  // Returns the amount moved (0 if nothing to move / no goal).
  static Future<double> claimRecapToSavings() async {
    final recap = getPendingRecap();
    if (recap == null) return 0.0;
    final leftover = (recap['leftover'] as num?)?.toDouble() ?? 0.0;
    final goals = getAllSavingsGoals();
    if (leftover > 0 && goals.isNotEmpty) {
      await addToSavingsGoal(0, leftover);
      await clearPendingRecap();
      return leftover;
    }
    await clearPendingRecap();
    return 0.0;
  }

  // ─── EXPENSES ────────────────────────────────────────────

  static List<Expense> getExpenses() {
    final box = Hive.box(_expenseBox);
    return box.values
        .map((e) => Expense.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<Expense> getExpensesByDateRange(
      DateTime start, DateTime end) {
    return getExpenses().where((e) {
      return !e.date.isBefore(start) && !e.date.isAfter(end);
    }).toList();
  }

  static List<Expense> searchExpenses(String query,
      {String? category}) {
    var expenses = getExpenses();
    if (query.isNotEmpty) {
      expenses = expenses
          .where((e) =>
      e.title
          .toLowerCase()
          .contains(query.toLowerCase()) ||
          e.category
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          e.note
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    }
    if (category != null && category != 'All') {
      expenses =
          expenses.where((e) => e.category == category).toList();
    }
    return expenses;
  }

  static String _stamp() => DateTime.now().toIso8601String();

  static Future<void> addExpense(Expense expense) async {
    final box = Hive.box(_expenseBox);
    if (expense.history.isEmpty) {
      expense.history.add(
          '${_stamp()} · created · ₱${expense.amount.toStringAsFixed(2)}${expense.hasReceipt ? ' · with receipt' : ''}');
    }
    await box.add(expense.toMap());
  }

  // Find the Hive key whose stored record has the given id.
  static dynamic _expenseKeyForId(String id) {
    final box = Hive.box(_expenseBox);
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      if (Map<String, dynamic>.from(raw)['id'] == id) return key;
    }
    return null;
  }

  static Future<void> updateExpense(
      String id, Expense expense) async {
    final box = Hive.box(_expenseBox);
    final key = _expenseKeyForId(id);
    if (key == null) return;

    // Preserve the original logged-time and audit trail; record the change.
    final old = Expense.fromMap(Map<String, dynamic>.from(box.get(key)));
    final changes = <String>[];
    if (old.amount != expense.amount) {
      changes.add(
          'amount ₱${old.amount.toStringAsFixed(2)}→₱${expense.amount.toStringAsFixed(2)}');
    }
    if (old.title != expense.title) {
      changes.add('title "${old.title}"→"${expense.title}"');
    }
    if (old.category != expense.category) {
      changes.add('category ${old.category}→${expense.category}');
    }
    if (!old.date.isAtSameMomentAs(expense.date)) {
      changes.add('date');
    }
    if ((old.receipt ?? '') != (expense.receipt ?? '')) {
      if (!old.hasReceipt && expense.hasReceipt) {
        changes.add('receipt attached');
      } else if (old.hasReceipt && !expense.hasReceipt) {
        changes.add('receipt removed');
      } else {
        changes.add('receipt replaced');
      }
    }

    final merged = Expense(
      id: old.id,
      title: expense.title,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
      note: expense.note,
      receipt: expense.receipt,
      createdAt: old.createdAt,
      modifiedAt: DateTime.now(),
      history: List<String>.from(old.history),
    );
    merged.history.add(
        '${_stamp()} · edited · ${changes.isEmpty ? "no field change" : changes.join(", ")}');
    await box.put(key, merged.toMap());
  }

  static Future<void> deleteExpense(String id) async {
    final box = Hive.box(_expenseBox);
    final key = _expenseKeyForId(id);
    if (key == null) return;
    // Record the deletion in an append-only log before removing it.
    final raw = Map<String, dynamic>.from(box.get(key));
    final log = getDeletedLog();
    log.add(
        '${_stamp()} · deleted · ${raw['title']} · ₱${(raw['amount'] as num).toStringAsFixed(2)} · ${raw['date']}');
    await Hive.box(_metaBox).put('deletedLog', log);
    await box.delete(key);
  }

  static List<String> getDeletedLog() {
    final raw = Hive.box(_metaBox).get('deletedLog');
    if (raw == null) return [];
    return (raw as List).map((e) => e.toString()).toList();
  }

  // SHA-256 over every expense's integrity signature, in created order.
  // The same dataset always produces the same checksum; any edit to a
  // logged field changes it, so an exported checksum can be re-verified.
  static String computeIntegrityHash() {
    final list = getExpenses()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final buffer =
        list.map((e) => e.integritySignature()).join('\n');
    final digest = sha256.convert(utf8.encode(buffer));
    return digest.toString();
  }

  // ─── INCOME ──────────────────────────────────────────────

  static List<Income> getIncomes() {
    final box = Hive.box(_incomeBox);
    return box.values
        .map((e) => Income.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> addIncome(Income income) async {
    final box = Hive.box(_incomeBox);
    await box.add(income.toMap());
  }

  static dynamic _incomeKeyForId(String id) {
    final box = Hive.box(_incomeBox);
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      if (Map<String, dynamic>.from(raw)['id'] == id) return key;
    }
    return null;
  }

  static Future<void> updateIncome(String id, Income income) async {
    final box = Hive.box(_incomeBox);
    final key = _incomeKeyForId(id);
    if (key != null) await box.put(key, income.toMap());
  }

  static Future<void> deleteIncome(String id) async {
    final box = Hive.box(_incomeBox);
    final key = _incomeKeyForId(id);
    if (key != null) await box.delete(key);
  }

  static double getTotalIncomeThisWeek() {
    final now = DateTime.now();
    final startOfWeek =
        now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(
        startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return getIncomes()
        .where((e) => !e.date.isBefore(weekStart))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  static double getTotalIncomeToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return getIncomes()
        .where((e) =>
            DateTime(e.date.year, e.date.month, e.date.day) ==
            today)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  static double getTotalIncomeThisMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return getIncomes()
        .where((e) => !e.date.isBefore(monthStart))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  static double getTotalIncomeAllTime() {
    return getIncomes().fold(0.0, (sum, e) => sum + e.amount);
  }

  // Net = money in − money out, for the matching period.
  static double getNetThisWeek() =>
      getTotalIncomeThisWeek() - getTotalSpentThisWeek();

  static double getNetThisMonth() =>
      getTotalIncomeThisMonth() - getTotalSpentThisMonth();

  // Sum of expenses with date in [start, end).
  static double getSpentInRange(DateTime start, DateTime end) {
    return getExpenses()
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // Sum of income with date in [start, end).
  static double getIncomeInRange(DateTime start, DateTime end) {
    return getIncomes()
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // ─── CATEGORIES ──────────────────────────────────────────

  static List<ExpenseCategory> getCategories() {
    final raw = Hive.box(_metaBox).get('categories');
    if (raw == null) return ExpenseCategory.defaults;
    final list = (raw as List)
        .map((e) =>
            ExpenseCategory.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return list.isEmpty ? ExpenseCategory.defaults : list;
  }

  static Future<void> _saveCategories(
      List<ExpenseCategory> cats) async {
    await Hive.box(_metaBox)
        .put('categories', cats.map((c) => c.toMap()).toList());
  }

  static Future<void> addCategory(ExpenseCategory c) async {
    final cats = List<ExpenseCategory>.from(getCategories());
    if (cats.any(
        (x) => x.name.toLowerCase() == c.name.toLowerCase())) {
      return;
    }
    cats.add(c);
    await _saveCategories(cats);
  }

  static Future<void> updateCategory(
      String oldName, ExpenseCategory c) async {
    final cats =
        getCategories().map((x) => x.name == oldName ? c : x).toList();
    await _saveCategories(cats);
  }

  static Future<void> deleteCategory(String name) async {
    final cats =
        getCategories().where((x) => x.name != name).toList();
    await _saveCategories(cats);
  }

  static ExpenseCategory categoryFor(String name) {
    for (final c in getCategories()) {
      if (c.name == name) return c;
    }
    return ExpenseCategory(
        name: name, emoji: '📦', colorValue: 0xFF95A5A6);
  }

  static Color colorFor(String name) => categoryFor(name).color;
  static String emojiFor(String name) => categoryFor(name).emoji;

  // ─── CUSTOM AVATAR IMAGE ─────────────────────────────────

  static String? getAvatarImage() =>
      Hive.box(_metaBox).get('avatarImage');

  static Future<void> setAvatarImage(String base64) async {
    await Hive.box(_metaBox).put('avatarImage', base64);
  }

  // ─── PER-CATEGORY BUDGETS ────────────────────────────────

  static Map<String, double> getCategoryBudgets() {
    final raw = Hive.box(_metaBox).get('categoryBudgets');
    if (raw == null) return {};
    return (raw as Map).map((k, v) =>
        MapEntry(k.toString(), (v as num).toDouble()));
  }

  static Future<void> setCategoryBudget(
      String name, double limit) async {
    final m = getCategoryBudgets();
    if (limit <= 0) {
      m.remove(name);
    } else {
      m[name] = limit;
    }
    await Hive.box(_metaBox).put('categoryBudgets', m);
  }

  // Spending per category for the current week.
  static Map<String, double> getWeeklyCategorySpending() {
    final now = DateTime.now();
    final startOfWeek =
        now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(
        startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final map = <String, double>{};
    for (final e
        in getExpenses().where((e) => !e.date.isBefore(weekStart))) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  // ─── REMINDERS (in-app) ──────────────────────────────────

  static bool getReminderEnabled() =>
      Hive.box(_metaBox).get('reminderEnabled', defaultValue: false);

  static int getReminderHour() =>
      Hive.box(_metaBox).get('reminderHour', defaultValue: 20);

  static int getReminderMinute() =>
      Hive.box(_metaBox).get('reminderMinute', defaultValue: 0);

  static Future<void> setReminder(
      bool enabled, int hour, int minute) async {
    final box = Hive.box(_metaBox);
    await box.put('reminderEnabled', enabled);
    await box.put('reminderHour', hour);
    await box.put('reminderMinute', minute);
  }

  static String? getReminderLastShown() =>
      Hive.box(_metaBox).get('reminderLastShown');

  static Future<void> markReminderShownToday() async {
    final now = DateTime.now();
    await Hive.box(_metaBox).put(
        'reminderLastShown', '${now.year}-${now.month}-${now.day}');
  }

  // True if the daily reminder pop-up should show right now.
  static bool shouldShowReminderNow(double spentToday) {
    if (!getReminderEnabled()) return false;
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day,
        getReminderHour(), getReminderMinute());
    if (now.isBefore(target)) return false;
    if (spentToday > 0) return false;
    final todayKey = '${now.year}-${now.month}-${now.day}';
    return getReminderLastShown() != todayKey;
  }

  // ─── EXPORT / BACKUP / RESTORE ───────────────────────────

  static String _csvField(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String exportExpensesCsv() {
    final rows = <String>[
      'Date,Title,Category,Amount,Note,LoggedAt,LastEdited,Edits'
    ];
    for (final e in getExpenses()) {
      rows.add([
        e.date.toIso8601String(),
        e.title,
        e.category,
        e.amount.toStringAsFixed(2),
        e.note,
        e.createdAt.toIso8601String(),
        e.modifiedAt.toIso8601String(),
        e.editCount.toString(),
      ].map(_csvField).join(','));
    }
    rows.add('');
    rows.add('# Records: ${getExpenses().length}');
    rows.add('# Generated: ${DateTime.now().toIso8601String()}');
    rows.add('# Integrity (SHA-256): ${computeIntegrityHash()}');
    return rows.join('\n');
  }

  static String exportIncomeCsv() {
    final rows = <String>['Date,Source,Amount,Note'];
    for (final e in getIncomes()) {
      rows.add([
        e.date.toIso8601String(),
        e.source,
        e.amount.toStringAsFixed(2),
        e.note,
      ].map(_csvField).join(','));
    }
    return rows.join('\n');
  }

  static Map<String, dynamic> _dumpBox(Box b) {
    final m = <String, dynamic>{};
    for (final k in b.keys) {
      m[k.toString()] = b.get(k);
    }
    return m;
  }

  static String exportBackupJson() {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'expenses': getExpenses().map((e) => e.toMap()).toList(),
      'income': getIncomes().map((e) => e.toMap()).toList(),
      'budgetBox': _dumpBox(Hive.box(_budgetBox)),
      'savingsBox': _dumpBox(Hive.box(_savingsBox)),
      'metaBox': _dumpBox(Hive.box(_metaBox)),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // Returns a status string. Throws on malformed input.
  static Future<String> restoreFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (!data.containsKey('expenses')) {
      throw const FormatException('Not a BudgetMo backup');
    }

    final eb = Hive.box(_expenseBox);
    await eb.clear();
    for (final m in (data['expenses'] as List)) {
      await eb.add(Map<String, dynamic>.from(m));
    }

    final ib = Hive.box(_incomeBox);
    await ib.clear();
    for (final m in (data['income'] as List? ?? [])) {
      await ib.add(Map<String, dynamic>.from(m));
    }

    Future<void> restoreBox(String boxName, String key) async {
      final box = Hive.box(boxName);
      final src = data[key];
      if (src is Map) {
        await box.clear();
        src.forEach((k, v) => box.put(k.toString(), v));
      }
    }

    await restoreBox(_budgetBox, 'budgetBox');
    await restoreBox(_savingsBox, 'savingsBox');
    await restoreBox(_metaBox, 'metaBox');

    return 'Restored ${(data['expenses'] as List).length} expenses '
        'and ${(data['income'] as List? ?? []).length} income entries.';
  }

  // ─── BUDGET ──────────────────────────────────────────────

  static double getWeeklyBudget() =>
      Hive.box(_budgetBox).get('weekly', defaultValue: 1500.0);

  static double getDailyBudget() =>
      Hive.box(_budgetBox).get('daily', defaultValue: 0.0);

  static double getMonthlyBudget() =>
      Hive.box(_budgetBox).get('monthly', defaultValue: 0.0);

  static Future<void> setWeeklyBudget(double amount) async =>
      await Hive.box(_budgetBox).put('weekly', amount);

  static Future<void> setDailyBudget(double amount) async =>
      await Hive.box(_budgetBox).put('daily', amount);

  static Future<void> setMonthlyBudget(double amount) async =>
      await Hive.box(_budgetBox).put('monthly', amount);

  // ─── SAVINGS (MULTIPLE GOALS) ─────────────────────────────

  static List<Map<String, dynamic>> getAllSavingsGoals() {
    final box = Hive.box(_savingsBox);
    final raw = box.get('goals');
    if (raw == null) {
      // Migrate old single goal if exists
      final oldName = box.get('name');
      final oldTarget = box.get('target');
      final oldSaved = box.get('saved');
      if (oldName != null) {
        final goals = [
          {
            'name': oldName,
            'target': oldTarget ?? 3000.0,
            'saved': oldSaved ?? 0.0,
          }
        ];
        box.put('goals', goals);
        return List<Map<String, dynamic>>.from(
            goals.map((g) => Map<String, dynamic>.from(g)));
      }
      return [];
    }
    return List<Map<String, dynamic>>.from(
        (raw as List).map((g) => Map<String, dynamic>.from(g)));
  }

  static Future<void> _saveGoals(
      List<Map<String, dynamic>> goals) async {
    await Hive.box(_savingsBox).put('goals', goals);
  }

  // Legacy support
  static Map<String, dynamic> getSavingsGoal() {
    final goals = getAllSavingsGoals();
    if (goals.isEmpty) {
      return {'name': 'My Goal', 'target': 3000.0, 'saved': 0.0};
    }
    return goals[0];
  }

  static Future<void> setSavingsGoal(
      String name, double target) async {
    final goals = getAllSavingsGoals();
    if (goals.isEmpty) {
      await addSavingsGoal(name, target);
    } else {
      goals[0]['name'] = name;
      goals[0]['target'] = target;
      await _saveGoals(goals);
    }
  }

  static Future<void> addToSavings(double amount) async {
    await addToSavingsGoal(0, amount);
  }

  // New multi-goal methods
  static Future<void> addSavingsGoal(
      String name, double target) async {
    final goals = getAllSavingsGoals();
    goals.add({'name': name, 'target': target, 'saved': 0.0});
    await _saveGoals(goals);
  }

  static Future<void> updateSavingsGoal(
      int index, String name, double target) async {
    final goals = getAllSavingsGoals();
    if (index >= 0 && index < goals.length) {
      goals[index]['name'] = name;
      goals[index]['target'] = target;
      await _saveGoals(goals);
    }
  }

  static Future<void> addToSavingsGoal(
      int index, double amount) async {
    final goals = getAllSavingsGoals();
    if (index >= 0 && index < goals.length) {
      final current =
          (goals[index]['saved'] as num?)?.toDouble() ?? 0.0;
      goals[index]['saved'] = current + amount;
      await _saveGoals(goals);
    }
  }

  static Future<void> deleteSavingsGoal(int index) async {
    final goals = getAllSavingsGoals();
    if (index >= 0 && index < goals.length) {
      goals.removeAt(index);
      await _saveGoals(goals);
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────

  static double getTotalSpentThisWeek() {
    final now = DateTime.now();
    final startOfWeek =
    now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(
        startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return getExpenses()
        .where((e) => !e.date.isBefore(weekStart))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  static double getTotalSpentToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return getExpenses()
        .where((e) =>
    DateTime(e.date.year, e.date.month, e.date.day) ==
        today)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  static double getTotalSpentThisMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return getExpenses()
        .where((e) => !e.date.isBefore(monthStart))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // Total of ALL expenses ever
  static double getTotalAllTime() {
    return getExpenses()
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  static double getSafeToSpendToday() {
    final weeklyBudget = getWeeklyBudget();
    final spentThisWeek = getTotalSpentThisWeek();
    final remaining = weeklyBudget - spentThisWeek;
    final now = DateTime.now();
    final daysLeft = 7 - now.weekday + 1;
    if (daysLeft <= 0) return 0;
    final safeDaily = remaining / daysLeft;
    final dailyBudget = getDailyBudget();
    if (dailyBudget > 0) {
      return safeDaily < dailyBudget ? safeDaily : dailyBudget;
    }
    return safeDaily < 0 ? 0 : safeDaily;
  }

  static Map<String, double> getSpendingByCategory() {
    final Map<String, double> result = {};
    for (final e in getExpenses()) {
      result[e.category] =
          (result[e.category] ?? 0) + e.amount;
    }
    return result;
  }

  static Map<String, double> getMonthlySpendingByCategory() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final Map<String, double> result = {};
    for (final e in getExpenses()
        .where((e) => !e.date.isBefore(monthStart))) {
      result[e.category] =
          (result[e.category] ?? 0) + e.amount;
    }
    return result;
  }

  static Map<String, double> getLast7DaysSpending() {
    final now = DateTime.now();
    final Map<String, double> result = {};
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = _dayLabel(day.weekday);
      result[key] = 0;
    }
    for (final e in getExpenses()) {
      final diff = now.difference(e.date).inDays;
      if (diff <= 6) {
        final key = _dayLabel(e.date.weekday);
        result[key] = (result[key] ?? 0) + e.amount;
      }
    }
    return result;
  }

  static Map<String, double> getMonthlySpending() {
    final now = DateTime.now();
    final Map<String, double> result = {};
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = _monthLabel(month.month);
      result[key] = 0;
    }
    for (final e in getExpenses()) {
      final diff = now.month -
          e.date.month +
          (now.year - e.date.year) * 12;
      if (diff >= 0 && diff <= 5) {
        final key = _monthLabel(e.date.month);
        result[key] = (result[key] ?? 0) + e.amount;
      }
    }
    return result;
  }

  static String _dayLabel(int weekday) {
    const days = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    return days[weekday - 1];
  }

  static String _monthLabel(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}