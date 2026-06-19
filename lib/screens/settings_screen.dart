import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../services/pdf_service.dart';
import '../widgets/user_avatar.dart';
import 'categories_screen.dart';
import 'category_budgets_screen.dart';
import 'recurring_screen.dart';
import 'share_card_screen.dart';
import 'integrity_screen.dart';
import 'theme_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static Color get green => const Color(0xFF2ECC71);
  static Color get ink => const Color(0xFF1A2E1A);

  String _name = 'Student';
  String _avatar = UserAvatars.defaultId;
  bool _reminder = false;
  int _reminderHour = 20;
  int _reminderMinute = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final box = Hive.box('budget');
    setState(() {
      _name = box.get('userName', defaultValue: 'Student');
      _avatar =
          box.get('userAvatar', defaultValue: UserAvatars.defaultId);
      _reminder = StorageService.getReminderEnabled();
      _reminderHour = StorageService.getReminderHour();
      _reminderMinute = StorageService.getReminderMinute();
    });
  }

  // ── PROFILE ──
  void _changeAvatar() async {
    final picked = await showAvatarPicker(context, current: _avatar);
    if (picked != null) {
      await Hive.box('budget').put('userAvatar', picked);
      _load();
    }
  }

  void _editName() {
    final ctrl = TextEditingController(text: _name);
    _formDialog('Your name', ctrl, TextInputType.text, () async {
      if (ctrl.text.trim().isNotEmpty) {
        await Hive.box('budget').put('userName', ctrl.text.trim());
      }
    });
  }

  // ── BUDGETS ──
  void _editBudget(String label, double current,
      Future<void> Function(double) save) {
    final ctrl = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(0) : '');
    _formDialog(label, ctrl, TextInputType.number, () async {
      await save(double.tryParse(ctrl.text) ?? 0);
    }, prefix: '₱ ');
  }

  void _formDialog(String title, TextEditingController ctrl,
      TextInputType type, Future<void> Function() onSave,
      {String? prefix}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 17)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: type,
          style: GoogleFonts.plusJakartaSans(),
          decoration: InputDecoration(
            prefixText: prefix,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.black45))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await onSave();
              if (context.mounted) Navigator.pop(context);
              _load();
            },
            child: Text('Save',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── REMINDERS ──
  Future<void> _pickReminderHour() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (picked != null) {
      await StorageService.setReminder(
          _reminder, picked.hour, picked.minute);
      if (_reminder) {
        await NotificationService.scheduleDaily(
            picked.hour, picked.minute);
      }
      _load();
    }
  }

  void _permissionDeniedDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('$title permission needed',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(message,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Not now',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.black45)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              PermissionService.openSettings();
            },
            child: Text('Open settings',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── DATA ──
  void _showExport(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 17)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(content,
                  style: GoogleFonts.robotoMono(fontSize: 11)),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.black45))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: const Text('Copied to clipboard'),
                      backgroundColor: green),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text('Copy',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _restoreDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Restore from backup',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Paste a backup below. This replaces all current data.',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5, color: Colors.black45)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 6,
              style: GoogleFonts.robotoMono(fontSize: 11),
              decoration: InputDecoration(
                hintText: '{ "version": 1, ... }',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.black45))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              try {
                final msg =
                    await StorageService.restoreFromJson(ctrl.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(msg), backgroundColor: green),
                  );
                }
                _load();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('That doesn\'t look like a valid backup'),
                        backgroundColor: Color(0xFFE74C3C)),
                  );
                }
              }
            },
            child: Text('Restore',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, color: ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 60),
        children: [
          // Profile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: Row(
              children: [
                GestureDetector(
                    onTap: _changeAvatar,
                    child: UserAvatar(id: _avatar, size: 54)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name,
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: ink)),
                      Text('Tap avatar or pencil to edit',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                ),
                IconButton(
                    onPressed: _editName,
                    icon: Icon(Icons.edit_rounded,
                        color: Colors.black45, size: 20)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _sectionTitle('Budgets'),
          _tile('Weekly budget',
              '₱${StorageService.getWeeklyBudget().toStringAsFixed(0)}',
              Icons.calendar_view_week_rounded,
              () => _editBudget('Weekly budget',
                  StorageService.getWeeklyBudget(),
                  StorageService.setWeeklyBudget)),
          _tile('Daily budget',
              '₱${StorageService.getDailyBudget().toStringAsFixed(0)}',
              Icons.today_rounded,
              () => _editBudget('Daily budget',
                  StorageService.getDailyBudget(),
                  StorageService.setDailyBudget)),
          _tile('Monthly budget',
              '₱${StorageService.getMonthlyBudget().toStringAsFixed(0)}',
              Icons.calendar_month_rounded,
              () => _editBudget('Monthly budget',
                  StorageService.getMonthlyBudget(),
                  StorageService.setMonthlyBudget)),

          const SizedBox(height: 18),
          _sectionTitle('Appearance'),
          _tile('Theme & colors', 'Accent color and dark mode',
              Icons.palette_rounded, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ThemeScreen()));
          }),

          const SizedBox(height: 18),
          _sectionTitle('Categories'),
          _tile('Manage categories', 'Add, edit, recolor',
              Icons.category_rounded, () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CategoriesScreen()));
            _load();
          }),
          _tile('Category budgets', 'Weekly caps per category',
              Icons.donut_small_rounded, () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const CategoryBudgetsScreen()));
            _load();
          }),

          const SizedBox(height: 18),
          _sectionTitle('Automation & sharing'),
          _tile('Recurring expenses', 'Auto-log rent, load, subs',
              Icons.repeat_rounded, () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RecurringScreen()));
            _load();
          }),
          _tile('Share your week', 'A card built for screenshots',
              Icons.ios_share_rounded, () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ShareCardScreen()));
          }),

          const SizedBox(height: 18),
          _sectionTitle('Reminders'),
          Container(
            decoration: _cardDeco(),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: green,
                  title: Text('Daily log reminder',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: ink)),
                  subtitle: Text(
                      'Piso nudges you if nothing\'s logged by your set time',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5, color: Colors.black45)),
                  value: _reminder,
                  onChanged: (v) async {
                    if (v) {
                      final granted = await PermissionService
                          .requestNotifications();
                      await NotificationService.requestIOSPermissions();
                      await NotificationService.requestExactAlarms();
                      await StorageService.setReminder(
                          true, _reminderHour, _reminderMinute);
                      await NotificationService.scheduleDaily(
                          _reminderHour, _reminderMinute);
                      if (!granted && context.mounted) {
                        _permissionDeniedDialog(
                            'Notifications',
                            'BudgetMo needs notification permission to remind you. Enable it in Settings.');
                      }
                    } else {
                      await StorageService.setReminder(
                          false, _reminderHour, _reminderMinute);
                      await NotificationService.cancel();
                    }
                    _load();
                  },
                ),
                if (_reminder)
                  ListTile(
                    title: Text('Remind me at',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: ink)),
                    trailing: Text(
                        '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: green)),
                    onTap: _pickReminderHour,
                  ),
                if (_reminder)
                  ListTile(
                    title: Text('Send a test alert',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: ink)),
                    subtitle: Text('Fires immediately',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5, color: Colors.black45)),
                    trailing: Icon(Icons.notifications_active_rounded,
                        color: green),
                    onTap: () async {
                      await PermissionService.requestNotifications();
                      await NotificationService.requestIOSPermissions();
                      await NotificationService.requestExactAlarms();
                      final err = await NotificationService.showNow();
                      if (!context.mounted) return;
                      if (err == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: const Text('Sent! Check your notification bar.'),
                              backgroundColor: green),
                        );
                      } else {
                        _permissionDeniedDialog('Notification', err);
                      }
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          _sectionTitle('Data & backup'),
          _tile('Record & integrity', 'Timestamps, edit history, checksum',
              Icons.verified_rounded, () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const IntegrityScreen()));
          }),
          _tile('Export PDF report', 'Shareable report + receipts + checksum',
              Icons.picture_as_pdf_rounded, () async {
            try {
              await PdfService.exportExpenseReport();
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Could not generate PDF'),
                      backgroundColor: Color(0xFFE74C3C)),
                );
              }
            }
          }),
          _tile('Export expenses (CSV)', 'Copy as spreadsheet text',
              Icons.table_chart_rounded,
              () => _showExport('Expenses CSV',
                  StorageService.exportExpensesCsv())),
          _tile('Export income (CSV)', 'Copy as spreadsheet text',
              Icons.table_chart_outlined,
              () => _showExport('Income CSV',
                  StorageService.exportIncomeCsv())),
          _tile('Backup everything (JSON)', 'Copy a full backup',
              Icons.cloud_download_rounded,
              () => _showExport('Full backup',
                  StorageService.exportBackupJson())),
          _tile('Restore from backup', 'Paste a saved backup',
              Icons.restore_rounded, _restoreDialog,
              danger: true),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
        child: Text(t,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Colors.black45)),
      );

  Widget _tile(String title, String subtitle, IconData icon,
      VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? const Color(0xFFE67E22) : green;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDeco(),
      child: ListTile(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: ink)),
        subtitle: Text(subtitle,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: Colors.black45)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: Colors.black26),
        onTap: onTap,
      ),
    );
  }
}
