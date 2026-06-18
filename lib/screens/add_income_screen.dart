import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../services/storage_service.dart';

class AddIncomeScreen extends StatefulWidget {
  final Income? existingIncome;

  const AddIncomeScreen({super.key, this.existingIncome});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _sourceController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.existingIncome != null;

  // Common income sources for quick selection.
  final List<String> _sources = [
    'Allowance',
    'Salary',
    'Freelance',
    'Gift',
    'Refund',
    'Other',
  ];

  final Map<String, String> _sourceIcons = {
    'Allowance': '💵',
    'Salary': '💼',
    'Freelance': '🧑‍💻',
    'Gift': '🎁',
    'Refund': '↩️',
    'Other': '➕',
  };

  String _selectedSource = 'Allowance';

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _sourceController.text = widget.existingIncome!.source;
      _amountController.text =
          widget.existingIncome!.amount.toString();
      _noteController.text = widget.existingIncome!.note;
      _selectedDate = widget.existingIncome!.date;
      if (_sources.contains(widget.existingIncome!.source)) {
        _selectedSource = widget.existingIncome!.source;
      } else {
        _selectedSource = 'Other';
      }
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
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
    final source = _selectedSource == 'Other'
        ? (_sourceController.text.trim().isEmpty
            ? 'Other'
            : _sourceController.text.trim())
        : _selectedSource;

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
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

    final income = Income(
      id: widget.existingIncome?.id,
      source: source,
      amount: amount,
      date: _selectedDate,
      note: _noteController.text.trim(),
    );

    if (_isEditing) {
      await StorageService.updateIncome(
          widget.existingIncome!.id, income);
    } else {
      await StorageService.addIncome(income);
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
              color: cInk),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Income' : 'Add Income',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: cInk),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Source'),
            const SizedBox(height: 10),
            _sourcePicker(),
            if (_selectedSource == 'Other') ...[
              const SizedBox(height: 16),
              _label('Source name'),
              _inputField(_sourceController, 'e.g. Scholarship'),
            ],
            const SizedBox(height: 16),
            _label('Amount (₱)'),
            _inputField(_amountController, '0.00', isNumber: true),
            const SizedBox(height: 16),
            _label('Date'),
            _datePicker(),
            const SizedBox(height: 16),
            _label('Note (optional)'),
            _inputField(_noteController, 'Add a note...'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _isEditing ? 'Update Income' : 'Save Income',
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
              color: cInk)),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint,
      {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: cSurface,
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cSurface,
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

  Widget _sourcePicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _sources.map((src) {
        final selected = _selectedSource == src;
        return GestureDetector(
          onTap: () => setState(() => _selectedSource = src),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? cInk
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6)
              ],
            ),
            child: Text(
              '${_sourceIcons[src]} $src',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : cInk,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
