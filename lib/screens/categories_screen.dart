import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense_category.dart';
import '../services/storage_service.dart';
import '../theme/theme_controller.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<ExpenseCategory> _cats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _cats = StorageService.getCategories());

  void _editDialog({ExpenseCategory? existing}) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    String emoji = existing?.emoji ?? ExpenseCategory.emojiChoices.first;
    int colorValue =
        existing?.colorValue ?? ExpenseCategory.palette.first;
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22)),
          title: Text(isEdit ? 'Edit category' : 'New category',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  enabled: !isEdit,
                  style: GoogleFonts.plusJakartaSans(),
                  decoration: InputDecoration(
                    hintText: 'Category name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Icon',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ExpenseCategory.emojiChoices.map((e) {
                    final sel = emoji == e;
                    return GestureDetector(
                      onTap: () => setD(() => emoji = e),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel
                              ? cAccent
                                  .withOpacity(0.18)
                              : const Color(0xFFF2F4F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: sel
                                  ? cAccent
                                  : Colors.transparent,
                              width: 2),
                        ),
                        child: Text(e,
                            style: const TextStyle(fontSize: 18)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Color',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExpenseCategory.palette.map((c) {
                    final sel = colorValue == c;
                    return GestureDetector(
                      onTap: () => setD(() => colorValue = c),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: sel ? 3 : 0),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                      color: Color(c).withOpacity(0.5),
                                      blurRadius: 6)
                                ]
                              : null,
                        ),
                        child: sel
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.black45)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: cAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final cat = ExpenseCategory(
                    name: name, emoji: emoji, colorValue: colorValue);
                if (isEdit) {
                  await StorageService.updateCategory(name, cat);
                } else {
                  await StorageService.addCategory(cat);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: Text('Save',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ExpenseCategory cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Delete "${cat.name}"?',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800)),
        content: Text(
            'Existing expenses keep this label, but it won\'t appear when logging new ones.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.black45))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await StorageService.deleteCategory(cat.name);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: const Color(0xFF1A2E1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Categories',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A2E1A))),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        children: _cats.map((cat) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
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
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(cat.name,
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: const Color(0xFF1A2E1A))),
                ),
                IconButton(
                  icon: Icon(Icons.edit_rounded,
                      size: 19, color: Colors.black45),
                  onPressed: () => _editDialog(existing: cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 19, color: Color(0xFFE74C3C)),
                  onPressed: () => _confirmDelete(cat),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editDialog(),
        backgroundColor: cAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('New',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}
