import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../providers/questions_provider.dart';

import 'timer_screen.dart';
import 'plan_screen.dart';
import 'notes_screen.dart';
import 'stats_screen.dart';
import 'routine_screen.dart';
import 'deneme_screen.dart';
import 'subjects_screen.dart';
import 'dgs_soru_dagilimi_screen.dart';
import 'settings_screen.dart';
import 'questions_screen.dart';
import '../widgets/banner_ad_widget.dart';

// ── Nav item definition ─────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData iconSelected;
  final String label;
  final Color accent;
  const _NavItem(this.icon, this.iconSelected, this.label, this.accent);
}

const _bottomNavItems = [
  _NavItem(Icons.timer_outlined, Icons.timer, 'Sayaç', Color(0xFF7F5AF0)),
  _NavItem(Icons.calendar_month_outlined, Icons.calendar_month, 'Plan',
      Color(0xFF2CB67D)),
  _NavItem(Icons.checklist_rtl_outlined, Icons.checklist_rtl, 'Rutin',
      Color(0xFFFF9F1C)),
  _NavItem(
      Icons.assignment_outlined, Icons.assignment, 'Deneme', Color(0xFFFF6B6B)),
  _NavItem(Icons.sticky_note_2_outlined, Icons.sticky_note_2, 'Notlar',
      Color(0xFF43BCCD)),
  _NavItem(
      Icons.grid_view_outlined, Icons.grid_view, 'Keşfet', Color(0xFFFF9F1C)),
];

final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key ?? homeScreenKey);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  void switchToTimer() {
    if (mounted) {
      setState(() => _selectedIndex = 0);
    }
  }

  // Ana 4 sekme + Keşfet (4. indeks) ayrı sayfa
  static const List<Widget> _mainPages = [
    TimerScreen(),
    PlanScreen(),
    RoutineScreen(),
    DenemeSScreen(),
    NotesScreen(),
    _KesfetScreen(),
  ];

  late Timer _countdownTimer;
  Duration _dgsRemaining = Duration.zero;
  bool _hasDgsTargetDate = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCountdown());
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _updateCountdown() {
    if (!mounted) return;
    final provider = Provider.of<DataProvider>(context, listen: false);
    final target = provider.dgsTargetDate;
    if (target != null) {
      setState(() {
        _hasDgsTargetDate = true;
        _dgsRemaining = target.difference(DateTime.now());
      });
    } else {
      setState(() => _hasDgsTargetDate = false);
    }
  }

  Future<void> _pickDgsDate(BuildContext context) async {
    final provider = Provider.of<DataProvider>(context, listen: false);
    final initialDate =
        provider.dgsTargetDate ?? DateTime.now().add(const Duration(days: 365));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null && context.mounted) {
      final pickedTime = await showTimePicker(
          context: context, initialTime: TimeOfDay.fromDateTime(initialDate));
      if (pickedTime != null) {
        final finalDT = DateTime(pickedDate.year, pickedDate.month,
            pickedDate.day, pickedTime.hour, pickedTime.minute);
        await provider.setDgsTargetDate(finalDT);
        _updateCountdown();
      }
    }
  }

  String _daysLabel() {
    if (!_hasDgsTargetDate) return 'Tarih seç';
    if (_dgsRemaining.isNegative) return '🎉';
    final d = _dgsRemaining.inDays;
    if (d == 0) return 'Bugün!';
    return '${d}g';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _bottomNavItems[_selectedIndex.clamp(0, 5)].accent;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // ── APP BAR ──────────────────────────────────────────────────────────
      appBar: _buildAppBar(isDark, accent),
      // ── BODY ─────────────────────────────────────────────────────────────
      body: Consumer<QuestionsProvider>(
        builder: (context, qProvider, _) {
          final dueCount = qProvider.dueQuestions.length;
          // Plan ve Notes kendi Scaffold'larında banner gösterir
          final bool showHomeBanner =
              _selectedIndex != 1 && _selectedIndex != 4;
          return Column(
            children: [
              // Due questions banner
              if (dueCount > 0) _buildDueBanner(dueCount, isDark),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity:
                        CurvedAnimation(parent: anim, curve: Curves.easeOut),
                    child: child,
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_selectedIndex),
                    child: _mainPages[_selectedIndex],
                  ),
                ),
              ),
              // Gömülü sekmeler için banner reklam (Plan ve Notlar kendi banner'ını gösterir)
              if (showHomeBanner)
                const SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: BannerAdWidget(),
                  ),
                ),
            ],
          );
        },
      ),
      // ── BOTTOM NAVIGATION BAR ────────────────────────────────────────────
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color accent) {
    final compact = MediaQuery.sizeOf(context).width < 420;

    return AppBar(
      scrolledUnderElevation: 0,
      backgroundColor:
          isDark ? const Color(0xFF0D0B15) : const Color(0xFFFAFAFC),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 12,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App logo
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF7F5AF0).withValues(alpha: 0.2),
                      blurRadius: 10)
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('assets/logosefaf.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'DGS Rehberi',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF16161A),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // DGS Geri sayım butonu
        GestureDetector(
          onTap: () => _pickDgsDate(context),
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) =>
                Transform.scale(scale: _pulseAnim.value, child: child),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 9 : 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2CB67D).withValues(alpha: 0.2),
                    const Color(0xFF2CB67D).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF2CB67D).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 13, color: Color(0xFF2CB67D)),
                  const SizedBox(width: 5),
                  Text(
                    compact ? _daysLabel() : 'DGS: ${_daysLabel()}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2CB67D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
    );
  }

  Widget _buildDueBanner(int dueCount, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        border:
            Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Text('⚡', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Bugün tekrar gereken $dueCount zorlu soru var!',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _selectedIndex = 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Gör',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black)),
          ),
        ),
      ]),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    final bg = isDark ? const Color(0xFF0D0B15) : const Color(0xFFFAFAFC);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.07);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        animationDuration: const Duration(milliseconds: 300),
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: _bottomNavItems.asMap().entries.map((e) {
          final item = e.value;
          return NavigationDestination(
            icon: Icon(item.icon,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.35)),
            selectedIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: item.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(item.iconSelected, color: item.accent),
            ),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

// ── KEŞFET EKRANI ────────────────────────────────────────────────────────────
class _KesfetScreen extends StatelessWidget {
  const _KesfetScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    final items = [
      _KesfetItem(
        icon: Icons.library_books_rounded,
        label: 'Konularım',
        subtitle: 'Konu takibi & ilerleme',
        color: const Color(0xFFFF9F1C),
        screen: const SubjectsScreen(),
      ),
      _KesfetItem(
        icon: Icons.table_chart_rounded,
        label: 'Soru Dağılımı',
        subtitle: 'DGS çıkmış soru analizi',
        color: const Color(0xFF2CB67D),
        screen: const DgsSoruDagilimiScreen(),
      ),
      _KesfetItem(
        icon: Icons.bar_chart_rounded,
        label: 'İstatistikler',
        subtitle: 'Haftalık & aylık veriler',
        color: const Color(0xFF00B4D8),
        screen: const StatsScreen(),
      ),
      _KesfetItem(
        icon: Icons.help_center_rounded,
        label: 'Soru Galerim',
        subtitle: 'Çözemediğim sorular',
        color: const Color(0xFFE53170),
        screen: const QuestionsScreen(),
      ),
      _KesfetItem(
        icon: Icons.settings_rounded,
        label: 'Ayarlar',
        subtitle: 'Tema & veri yönetimi',
        color: const Color(0xFF94A1B2),
        screen: const SettingsScreen(),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keşfet',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            'Tüm özellikler',
            style: GoogleFonts.inter(
                fontSize: 13, color: textColor.withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.2,
            children: items
                .map((item) => _KesfetCard(item: item, isDark: isDark))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _KesfetItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Widget screen;
  const _KesfetItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.screen,
  });
}

class _KesfetCard extends StatelessWidget {
  final _KesfetItem item;
  final bool isDark;
  const _KesfetCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => item.screen)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF13111C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: item.color.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
