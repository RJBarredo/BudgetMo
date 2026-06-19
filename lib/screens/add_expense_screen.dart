import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import '../theme/theme_controller.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;

  const AddExpenseScreen({
    super.key,
    this.existingExpense,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  String? _receipt; // base64

  bool get _isEditing => widget.existingExpense != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.existingExpense!.title;
      _amountController.text = widget.existingExpense!.amount.toString();
      _noteController.text = widget.existingExpense!.note;
      _selectedCategory = widget.existingExpense!.category;
      _selectedDate = widget.existingExpense!.date;
      _receipt = widget.existingExpense!.receipt;
    }
  }

  Future<void> _addReceipt(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        await PermissionService.requestCamera();
      } else {
        await PermissionService.requestPhotos();
      }
      final XFile? f = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 70,
      );
      if (f != null) {
        final bytes = await f.readAsBytes();
        setState(() => _receipt = base64Encode(bytes));
      }
    } catch (_) {}
  }

  void _receiptSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: Color(0xFF2ECC71)),
              title: Text('Take a photo',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _addReceipt(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: Color(0xFF2ECC71)),
              title: Text('Choose from gallery',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _addReceipt(ImageSource.gallery);
              },
            ),
            if (_receipt != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFE74C3C)),
                title: Text('Remove receipt',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE74C3C))),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _receipt = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _viewReceipt() {
    if (_receipt == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(base64Decode(_receipt!)),
          ),
        ),
      ),
    );
  }

  Widget _receiptField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Receipt (optional)',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: const Color(0xFF1A2E1A))),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_receipt != null)
              GestureDetector(
                onTap: _viewReceipt,
                child: Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: MemoryImage(base64Decode(_receipt!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _receiptSheet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A2E1A),
                  side: const BorderSide(color: Color(0xFFD9E2DC)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(
                    _receipt == null
                        ? Icons.add_a_photo_rounded
                        : Icons.edit_rounded,
                    size: 18),
                label: Text(
                    _receipt == null ? 'Attach receipt' : 'Change receipt',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2ECC71),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and amount')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final expense = Expense(
      id: widget.existingExpense?.id,
      title: _titleController.text.trim(),
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      note: _noteController.text.trim(),
      receipt: _receipt,
    );

    if (_isEditing) {
      await StorageService.updateExpense(
          widget.existingExpense!.id, expense);
    } else {
      await StorageService.addExpense(expense);
    }

    if (mounted) Navigator.pop(context, true);
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
        title: Text(
          _isEditing ? 'Edit Expense' : 'Add Expense',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A2E1A)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Title'),
            _inputField(_titleController, 'e.g. Lunch, Jeep fare...'),
            const SizedBox(height: 16),
            _label('Amount (₱)'),
            _inputField(_amountController, '0.00', isNumber: true),
            const SizedBox(height: 16),
            _label('Date'),
            _datePicker(),
            const SizedBox(height: 16),
            _label('Category'),
            const SizedBox(height: 10),
            _categoryPicker(),
            const SizedBox(height: 16),
            _label('Note (optional)'),
            _inputField(_noteController, 'Add a note...'),
            const SizedBox(height: 20),
            _receiptField(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _isEditing ? 'Update Expense' : 'Save Expense',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: const Color(0xFF1A2E1A))),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint,
      {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: TextField(
        controller: ctrl,
        keyboardType:
        isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.plusJakartaSans(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          GoogleFonts.plusJakartaSans(color: Colors.black26),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _datePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 6)
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM dd, yyyy').format(_selectedDate),
              style: GoogleFonts.plusJakartaSans(fontSize: 15),
            ),
            const Icon(Icons.calendar_today_rounded,
                color: Color(0xFF2ECC71), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _categoryPicker() {
    final categories = StorageService.getCategories();
    // Ensure the selected category is valid (e.g. after a category was deleted)
    if (!categories.any((c) => c.name == _selectedCategory) &&
        categories.isNotEmpty) {
      _selectedCategory = categories.first.name;
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final selected = _selectedCategory == cat.name;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF1A2E1A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6)
              ],
            ),
            child: Text(
              '${cat.emoji} ${cat.name}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : const Color(0xFF1A2E1A),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}