import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/plan_block.dart';
import '../providers/plan_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/banner_ad_widget.dart';

// ── Subject colors ──────────────────────────────────────────────────────────
const _subjects = [
  'Matematik',
  'Türkçe',
  'Geometri',
  'Sayısal M.',
  'Sözel M.',
  'Diğer',
];

const _subjectColors = {
  'Matematik': Color(0xFF7F5AF0),
  'Türkçe': Color(0xFFFF6B6B),
  'Geometri': Color(0xFF2CB67D),
  'Sayısal M.': Color(0xFF00B4D8),
  'Sözel M.': Color(0xFFFF9F1C),
  'Diğer': Color(0xFF94A1B2),
};

Color _subjectColor(String s) => _subjectColors[s] ?? const Color(0xFF94A1B2);

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ── MAIN SCREEN ─────────────────────────────────────────────────────────────
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTime _selectedDay = DateTime.now();
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // DGS countdown
  String _dgsLabel(BuildContext context) {
    final dp = Provider.of<DataProvider>(context, listen: false);
    final target = dp.dgsTargetDate;
    if (target == null) return 'Hedef tarihi seç';
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return '🎉 Tamamlandı';
    final d = diff.inDays;
    if (d == 0) return 'Bugün!';
    return '$d gün kaldı';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0E17) : const Color(0xFFF7F7F8);
    final cardBg = isDark ? const Color(0xFF13111C) : Colors.white;

    return Consumer<PlanProvider>(
      builder: (context, planProv, _) {
        return Scaffold(
          backgroundColor: bg,
          body: Column(
            children: [
              // ── HEADER ────────────────────────────────────────────────
              _PlanHeader(
                isDark: isDark,
                cardBg: cardBg,
                dgsLabel: _dgsLabel(context),
                tabCtrl: _tabCtrl,
              ),

              // ── TAB CONTENT ───────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _DailyView(
                      selectedDay: _selectedDay,
                      onDayChanged: (d) => setState(() => _selectedDay = d),
                      isDark: isDark,
                      cardBg: cardBg,
                      planProv: planProv,
                    ),
                    _MonthlyView(
                      calendarMonth: _calendarMonth,
                      selectedDay: _selectedDay,
                      onDaySelected: (d) {
                        setState(() {
                          _selectedDay = d;
                          _tabCtrl.animateTo(0);
                        });
                      },
                      onMonthChanged: (m) => setState(() => _calendarMonth = m),
                      isDark: isDark,
                      cardBg: cardBg,
                      planProv: planProv,
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: const SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: BannerAdWidget(),
            ),
          ),
          floatingActionButton: _tabCtrl.index == 0
              ? _AddBlockFab(
                  selectedDay: _selectedDay,
                  isDark: isDark,
                  planProv: planProv,
                )
              : null,
        );
      },
    );
  }
}

// ── HEADER ──────────────────────────────────────────────────────────────────
class _PlanHeader extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final String dgsLabel;
  final TabController tabCtrl;

  const _PlanHeader({
    required this.isDark,
    required this.cardBg,
    required this.dgsLabel,
    required this.tabCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      color: isDark ? const Color(0xFF0D0B15) : const Color(0xFFFAFAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Çalışma Planım',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Zamanını akıllıca planla',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: textColor.withValues(alpha: 0.45)),
                  ),
                ],
              ),
              const Spacer(),
              // DGS Countdown badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color(0xFF7F5AF0).withValues(alpha: 0.2),
                    const Color(0xFF2CB67D).withValues(alpha: 0.1),
                  ]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF7F5AF0).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      dgsLabel,
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7F5AF0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: tabCtrl,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F5AF0), Color(0xFF6246DB)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF7F5AF0).withValues(alpha: 0.3),
                      blurRadius: 10)
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              labelColor: Colors.white,
              unselectedLabelColor: textColor.withValues(alpha: 0.45),
              tabs: const [
                Tab(text: '📅  Günlük'),
                Tab(text: '🗓️  Aylık'),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── DAILY VIEW ───────────────────────────────────────────────────────────────
class _DailyView extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDayChanged;
  final bool isDark;
  final Color cardBg;
  final PlanProvider planProv;

  const _DailyView({
    required this.selectedDay,
    required this.onDayChanged,
    required this.isDark,
    required this.cardBg,
    required this.planProv,
  });

  @override
  Widget build(BuildContext context) {
    final dateKey = _dateKey(selectedDay);
    final blocks = planProv.getBlocksForDate(dateKey);
    final totalMins = planProv.minutesForDay(dateKey);
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Column(
      children: [
        // Day navigator
        _DayNavigator(
          selectedDay: selectedDay,
          onDayChanged: onDayChanged,
          isDark: isDark,
          totalMins: totalMins,
        ),
        Expanded(
          child: blocks.isEmpty
              ? _EmptyDayState(isDark: isDark, textColor: textColor)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: blocks.length,
                  itemBuilder: (ctx, i) => _BlockCard(
                    block: blocks[i],
                    isDark: isDark,
                    planProv: planProv,
                  ),
                ),
        ),
      ],
    );
  }
}

// ── DAY NAVIGATOR ────────────────────────────────────────────────────────────
class _DayNavigator extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDayChanged;
  final bool isDark;
  final int totalMins;

  const _DayNavigator({
    required this.selectedDay,
    required this.onDayChanged,
    required this.isDark,
    required this.totalMins,
  });

  String _dayLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    if (sel == today) return 'Bugün';
    if (sel == today.subtract(const Duration(days: 1))) return 'Dün';
    if (sel == today.add(const Duration(days: 1))) return 'Yarın';
    const months = [
      '',
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    return '${selectedDay.day} ${months[selectedDay.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Prev day
          _NavBtn(
            icon: Icons.chevron_left,
            onTap: () =>
                onDayChanged(selectedDay.subtract(const Duration(days: 1))),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Text(
                  _dayLabel(),
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (totalMins > 0)
                  Text(
                    '${(totalMins ~/ 60)}s ${totalMins % 60}dk planlı',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF7F5AF0),
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Next day
          _NavBtn(
            icon: Icons.chevron_right,
            onTap: () => onDayChanged(selectedDay.add(const Duration(days: 1))),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _NavBtn(
      {required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
            size: 20),
      ),
    );
  }
}

// ── BLOCK CARD ───────────────────────────────────────────────────────────────
class _BlockCard extends StatelessWidget {
  final PlanBlock block;
  final bool isDark;
  final PlanProvider planProv;

  const _BlockCard({
    required this.block,
    required this.isDark,
    required this.planProv,
  });

  String _timeStr(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor(block.subject);
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final cardBg = isDark ? const Color(0xFF13111C) : Colors.white;

    return Dismissible(
      key: Key(block.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red, size: 22),
      ),
      onDismissed: (_) => planProv.removeBlock(block.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => planProv.toggleBlock(block.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Color indicator & checkbox
                Container(
                  width: 4,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                // Time display
                Column(
                  children: [
                    Text(
                      _timeStr(block.startHour, block.startMinute),
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Container(
                      height: 18,
                      width: 1,
                      color: color.withValues(alpha: 0.4),
                    ),
                    Text(
                      _timeStr(block.endHour, block.endMinute),
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // Subject & note
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              block.subject,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${block.durationMinutes}dk',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: textColor.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                      if (block.note != null && block.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          block.note!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Completion check
                GestureDetector(
                  onTap: () => planProv.toggleBlock(block.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: block.isCompleted
                          ? color
                          : color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: color.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: block.isCompleted
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── EMPTY STATE ──────────────────────────────────────────────────────────────
class _EmptyDayState extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  const _EmptyDayState({required this.isDark, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF7F5AF0).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today_outlined,
                color: Color(0xFF7F5AF0), size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Bu gün plan yok',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 6),
          Text(
            'Sağ alttaki + butonuyla blok ekle',
            style: GoogleFonts.inter(
                fontSize: 13, color: textColor.withValues(alpha: 0.45)),
          ),
        ],
      ),
    );
  }
}

// ── ADD BLOCK FAB ────────────────────────────────────────────────────────────
class _AddBlockFab extends StatelessWidget {
  final DateTime selectedDay;
  final bool isDark;
  final PlanProvider planProv;

  const _AddBlockFab({
    required this.selectedDay,
    required this.isDark,
    required this.planProv,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddSheet(context),
      backgroundColor: const Color(0xFF7F5AF0),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: Text('Blok Ekle',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      elevation: 8,
    );
  }

  void _showAddSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedSubject = _subjects[0];
    int startHour = TimeOfDay.now().hour;
    int startMinute = 0;
    int durationMins = 60;
    final noteCtrl = TextEditingController();
    final customSubjectCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '60');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1825) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Çalışma Bloğu Ekle',
                  style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF16161A))),
              const SizedBox(height: 20),

              // Subject picker
              Text('Konu',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.45))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subjects.map((s) {
                  final c = _subjectColor(s);
                  final sel = s == selectedSubject;
                  return GestureDetector(
                    onTap: () => setSheet(() => selectedSubject = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? c : c.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel ? c : c.withValues(alpha: 0.3)),
                      ),
                      child: Text(s,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : c)),
                    ),
                  );
                }).toList(),
              ),
              if (selectedSubject == 'Diğer') ...[
                const SizedBox(height: 10),
                TextField(
                  controller: customSubjectCtrl,
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.white : const Color(0xFF16161A)),
                  decoration: InputDecoration(
                    labelText: 'Özel Konu Adı',
                    labelStyle: GoogleFonts.inter(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.4),
                        fontSize: 13),
                    filled: true,
                    fillColor: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF7F5AF0), width: 1.5)),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Time + Duration row
              Row(
                children: [
                  Expanded(
                    child: _SheetField(
                      label: 'Başlangıç',
                      value:
                          '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}',
                      icon: Icons.access_time_rounded,
                      color: const Color(0xFF7F5AF0),
                      isDark: isDark,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime:
                              TimeOfDay(hour: startHour, minute: startMinute),
                        );
                        if (t != null) {
                          setSheet(() {
                            startHour = t.hour;
                            startMinute = t.minute;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DurationPicker(
                      durationMins: durationMins,
                      isDark: isDark,
                      controller: durationCtrl,
                      onChanged: (v) {
                        setSheet(() {
                          durationMins = v;
                          if (durationCtrl.text != v.toString()) {
                            durationCtrl.text = v.toString();
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Note field
              TextField(
                controller: noteCtrl,
                style: GoogleFonts.inter(
                    color: isDark ? Colors.white : const Color(0xFF16161A)),
                decoration: InputDecoration(
                  labelText: 'Not (opsiyonel)',
                  labelStyle: GoogleFonts.inter(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.4),
                      fontSize: 13),
                  filled: true,
                  fillColor: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFF7F5AF0), width: 1.5),
                  ),
                  prefixIcon: const Icon(Icons.notes_rounded,
                      color: Color(0xFF7F5AF0), size: 18),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7F5AF0), Color(0xFF6246DB)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF7F5AF0).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      final finalSubject = (selectedSubject == 'Diğer' &&
                              customSubjectCtrl.text.isNotEmpty)
                          ? customSubjectCtrl.text.trim()
                          : selectedSubject;

                      final parsedDuration =
                          int.tryParse(durationCtrl.text) ?? durationMins;

                      final block = PlanBlock(
                        id: DateTime.now().toIso8601String(),
                        dateKey: _dateKey(selectedDay),
                        startHour: startHour,
                        startMinute: startMinute,
                        durationMinutes: parsedDuration,
                        subject: finalSubject,
                        note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                      );
                      planProv.addBlock(block);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Kaydet',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _SheetField({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: color.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600)),
                Text(value,
                    style: GoogleFonts.robotoMono(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationPicker extends StatelessWidget {
  final int durationMins;
  final bool isDark;
  final TextEditingController controller;
  final ValueChanged<int> onChanged;
  const _DurationPicker(
      {required this.durationMins,
      required this.isDark,
      required this.controller,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF2CB67D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Süre (dk)',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => onChanged(30),
                    child: _tag('30', durationMins == 30, color),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => onChanged(60),
                    child: _tag('60', durationMins == 60, color),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: GoogleFonts.robotoMono(
                fontSize: 15, fontWeight: FontWeight.bold, color: color),
            onChanged: (v) {
              final val = int.tryParse(v);
              if (val != null) {
                // Sadece callback'i çağırıyoruz ki UI'ın haberi olsun ama yazmayı bölmesin.
                onChanged(val);
              }
            },
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: 'Örn: 120',
              hintStyle: GoogleFonts.robotoMono(
                  color: color.withValues(alpha: 0.5), fontSize: 13),
            ),
          )
        ],
      ),
    );
  }

  Widget _tag(String text, bool active, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : color)),
    );
  }
}

// ── MONTHLY VIEW ─────────────────────────────────────────────────────────────
class _MonthlyView extends StatelessWidget {
  final DateTime calendarMonth;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onMonthChanged;
  final bool isDark;
  final Color cardBg;
  final PlanProvider planProv;

  const _MonthlyView({
    required this.calendarMonth,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onMonthChanged,
    required this.isDark,
    required this.cardBg,
    required this.planProv,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final minuteMap =
        planProv.minutesPerDayForMonth(calendarMonth.year, calendarMonth.month);

    // Find max for heatmap
    final maxMins = minuteMap.values.isEmpty
        ? 1
        : minuteMap.values.reduce((a, b) => a > b ? a : b);

    final firstDay = DateTime(calendarMonth.year, calendarMonth.month, 1);
    final lastDay = DateTime(calendarMonth.year, calendarMonth.month + 1, 0);
    // Start from Monday (1)
    final startPad = (firstDay.weekday - 1) % 7;
    const weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    const monthNames = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavBtn(
                icon: Icons.chevron_left,
                isDark: isDark,
                onTap: () => onMonthChanged(
                    DateTime(calendarMonth.year, calendarMonth.month - 1)),
              ),
              Text(
                '${monthNames[calendarMonth.month]} ${calendarMonth.year}',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
              _NavBtn(
                icon: Icons.chevron_right,
                isDark: isDark,
                onTap: () => onMonthChanged(
                    DateTime(calendarMonth.year, calendarMonth.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calendar container
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.07)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Week day headers
                Row(
                  children: weekDays
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(d,
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: textColor.withValues(alpha: 0.4))),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                // Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: startPad + lastDay.day,
                  itemBuilder: (ctx, index) {
                    if (index < startPad) return const SizedBox();
                    final dayNum = index - startPad + 1;
                    final date = DateTime(
                        calendarMonth.year, calendarMonth.month, dayNum);
                    final dateKey = _dateKey(date);
                    final mins = minuteMap[dateKey] ?? 0;
                    final heatIntensity = maxMins > 0 ? mins / maxMins : 0.0;
                    final isToday = _dateKey(DateTime.now()) == dateKey;
                    final isSelected = _dateKey(selectedDay) == dateKey;

                    return GestureDetector(
                      onTap: () => onDaySelected(date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF7F5AF0)
                              : mins > 0
                                  ? const Color(0xFF7F5AF0).withValues(
                                      alpha: 0.15 + 0.55 * heatIntensity)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday && !isSelected
                              ? Border.all(
                                  color: const Color(0xFF7F5AF0)
                                      .withValues(alpha: 0.6),
                                  width: 1.5)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$dayNum',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : textColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Monthly stats
          _MonthlyStats(
            planProv: planProv,
            year: calendarMonth.year,
            month: calendarMonth.month,
            isDark: isDark,
            cardBg: cardBg,
          ),
        ],
      ),
    );
  }
}

class _MonthlyStats extends StatelessWidget {
  final PlanProvider planProv;
  final int year;
  final int month;
  final bool isDark;
  final Color cardBg;

  const _MonthlyStats({
    required this.planProv,
    required this.year,
    required this.month,
    required this.isDark,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final minuteMap = planProv.minutesPerDayForMonth(year, month);
    final totalMins = minuteMap.values.fold(0, (a, b) => a + b);
    final daysWithPlan = minuteMap.values.where((m) => m > 0).length;

    final stats = [
      _Stat('Toplam Plan', '${totalMins ~/ 60}s ${totalMins % 60}dk',
          Icons.schedule_rounded, const Color(0xFF7F5AF0)),
      _Stat('Planlı Gün', '$daysWithPlan gün', Icons.calendar_month_rounded,
          const Color(0xFF2CB67D)),
      _Stat(
          'Günlük Ort.',
          daysWithPlan > 0 ? '${(totalMins / daysWithPlan).round()}dk' : '0dk',
          Icons.trending_up_rounded,
          const Color(0xFF00B4D8)),
    ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: s.color.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: s.color.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Column(
              children: [
                Icon(s.icon, color: s.color, size: 20),
                const SizedBox(height: 6),
                Text(s.value,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                Text(s.label,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: textColor.withValues(alpha: 0.45)),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
}
