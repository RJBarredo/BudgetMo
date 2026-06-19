import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';
import '../widgets/user_avatar.dart';
import 'home_screen.dart';
import '../theme/theme_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _goalNameCtrl = TextEditingController();
  final _goalAmountCtrl = TextEditingController();
  String _selectedAvatar = UserAvatars.defaultId;

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish() async {
    final box = Hive.box('budget');
    await box.put('userName', _nameCtrl.text.trim().isEmpty ? 'Student' : _nameCtrl.text.trim());
    await box.put('userAvatar', _selectedAvatar);
    await box.put('onboardingDone', true);

    final budget = double.tryParse(_budgetCtrl.text) ?? 1500.0;
    await StorageService.setWeeklyBudget(budget);

    final goalName = _goalNameCtrl.text.trim().isEmpty ? 'My Goal' : _goalNameCtrl.text.trim();
    final goalAmount = double.tryParse(_goalAmountCtrl.text) ?? 3000.0;
    await StorageService.setSavingsGoal(goalName, goalAmount);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? cAccent
                        : Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcomePage(),
                  _buildNamePage(),
                  _buildBudgetPage(),
                  _buildGoalPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PAGE 1 — Welcome
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2E1A),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: cAccent.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.savings_rounded,
                size: 64, color: Color(0xFF2ECC71)),
          ),
          const SizedBox(height: 40),
          Text('Welcome to',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, color: Colors.black45)),
          Text('BudgetMo',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A2E1A),
                  letterSpacing: -1)),
          const SizedBox(height: 16),
          Text(
            'Smart spending.\nTrack expenses, save goals, and stay on budget.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15, color: Colors.black45, height: 1.6),
          ),
          const SizedBox(height: 60),
          _nextButton("Let's Get Started 🚀", _nextPage),
        ],
      ),
    );
  }

  // PAGE 2 — Name & Avatar
  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('What should\nwe call you?',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2E1A),
                  height: 1.2)),
          const SizedBox(height: 8),
          Text('Pick an avatar and enter your name',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: Colors.black45)),
          const SizedBox(height: 24),

          // Selected avatar preview
          Center(
            child: UserAvatar(id: _selectedAvatar, size: 88),
          ),
          const SizedBox(height: 20),

          // Avatar picker
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: UserAvatars.all.map((spec) {
              final selected = _selectedAvatar == spec.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = spec.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? cAccent
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: UserAvatar(id: spec.id, size: 54),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Name input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8)
              ],
            ),
            child: TextField(
              controller: _nameCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Your name...',
                hintStyle:
                GoogleFonts.plusJakartaSans(color: Colors.black26),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
              ),
            ),
          ),
          const Spacer(),
          _nextButton('Continue', _nextPage),
        ],
      ),
    );
  }

  // PAGE 3 — Weekly Budget
  Widget _buildBudgetPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('Set your\nweekly budget',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2E1A),
                  height: 1.2)),
          const SizedBox(height: 8),
          Text('How much allowance do you get per week?',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: Colors.black45)),
          const SizedBox(height: 40),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8)
              ],
            ),
            child: TextField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 28, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: '1500',
                hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black12),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 20),
                prefixText: '₱ ',
                prefixStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: cAccent),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick presets
          Text('Quick select:',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: Colors.black45)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: ['500', '1000', '1500', '2000', '3000'].map((v) {
              return GestureDetector(
                onTap: () => setState(() => _budgetCtrl.text = v),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _budgetCtrl.text == v
                        ? const Color(0xFF1A2E1A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6)
                    ],
                  ),
                  child: Text('₱$v',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: _budgetCtrl.text == v
                              ? Colors.white
                              : Colors.black54)),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          _nextButton('Continue', _nextPage),
        ],
      ),
    );
  }

  // PAGE 4 — Savings Goal
  Widget _buildGoalPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('Set a\nsavings goal 🎯',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2E1A),
                  height: 1.2)),
          const SizedBox(height: 8),
          Text('What are you saving up for?',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: Colors.black45)),
          const SizedBox(height: 32),

          _onboardLabel('Goal name'),
          _onboardInput(_goalNameCtrl, 'e.g. New Phone, Trip, Gadget...'),
          const SizedBox(height: 16),
          _onboardLabel('Target amount (₱)'),
          _onboardInput(_goalAmountCtrl, 'e.g. 5000',
              isNumber: true),
          const SizedBox(height: 16),

          // Goal presets
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              '📱 New Phone',
              '✈️ Trip',
              '🎮 Gadget',
              '👟 Shoes',
              '📚 Books',
            ].map((v) {
              final label = v.split(' ').skip(1).join(' ');
              return GestureDetector(
                onTap: () =>
                    setState(() => _goalNameCtrl.text = label),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _goalNameCtrl.text == label
                        ? const Color(0xFF1A2E1A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6)
                    ],
                  ),
                  child: Text(v,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _goalNameCtrl.text == label
                              ? Colors.white
                              : Colors.black54)),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          _nextButton("Let's Go! 🎉", _finish),
        ],
      ),
    );
  }

  Widget _onboardLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black54)),
    );
  }

  Widget _onboardInput(TextEditingController ctrl, String hint,
      {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)
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

  Widget _nextButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: cAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }
}