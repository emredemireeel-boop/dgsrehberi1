import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/data_provider.dart';

class _SoruData {
  int sayisal = 0;
  int sozel = 0;
  int get toplam => sayisal + sozel;
}

class _SureData {
  int sure = 0; // seconds
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  int _chartIndex = 0; // 0 = Sorular, 1 = Süre

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    const primary = Color(0xFF00B4D8);

    final sessions = _currentTabIndex == 0
        ? dataProvider.getThisWeekSessions()
        : _currentTabIndex == 1
            ? dataProvider.getThisMonthSessions()
            : dataProvider.getThisYearSessions();

    int totalDur = 0, totalVerbal = 0, totalNumerical = 0, totalBreak = 0;
    Map<int, _SoruData> dataHafta = {
      for (var i = 1; i <= 7; i++) i: _SoruData()
    };
    Map<int, _SoruData> dataAy = {for (var i = 1; i <= 31; i++) i: _SoruData()};
    Map<int, _SoruData> dataYil = {
      for (var i = 1; i <= 12; i++) i: _SoruData()
    };

    Map<int, _SureData> sureHafta = {
      for (var i = 1; i <= 7; i++) i: _SureData()
    };
    Map<int, _SureData> sureAy = {for (var i = 1; i <= 31; i++) i: _SureData()};
    Map<int, _SureData> sureYil = {
      for (var i = 1; i <= 12; i++) i: _SureData()
    };

    for (var s in sessions) {
      if (_currentTabIndex == 0) {
        dataHafta[s.date.weekday]!.sayisal += s.numericalQuestions;
        dataHafta[s.date.weekday]!.sozel += s.verbalQuestions;
        sureHafta[s.date.weekday]!.sure += s.durationSeconds;
      } else if (_currentTabIndex == 1) {
        dataAy[s.date.day]!.sayisal += s.numericalQuestions;
        dataAy[s.date.day]!.sozel += s.verbalQuestions;
        sureAy[s.date.day]!.sure += s.durationSeconds;
      } else {
        dataYil[s.date.month]!.sayisal += s.numericalQuestions;
        dataYil[s.date.month]!.sozel += s.verbalQuestions;
        sureYil[s.date.month]!.sure += s.durationSeconds;
      }
      totalDur += s.durationSeconds;
      totalBreak += s.breakSeconds;
      totalVerbal += s.verbalQuestions;
      totalNumerical += s.numericalQuestions;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────────────────────────
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('İstatistikler',
                  style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              Text('Çalışma performansın',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: textColor.withValues(alpha: 0.4))),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [primary, Color(0xFF0090B8)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: primary.withValues(alpha: 0.4), blurRadius: 8)
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: textColor.withValues(alpha: 0.45),
                labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
                padding: EdgeInsets.zero,
                tabs: const [
                  Tab(text: 'Bu Hafta'),
                  Tab(text: 'Bu Ay'),
                  Tab(text: 'Bu Yıl')
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── SUMMARY CARDS ────────────────────────────────────────────────
          Row(children: [
            _summaryCard('⏱', 'Çalışma', _fmt(totalDur),
                const Color(0xFF7F5AF0), isDark),
            const SizedBox(width: 10),
            _summaryCard(
                '☕', 'Mola', _fmt(totalBreak), const Color(0xFFFFB800), isDark),
            const SizedBox(width: 10),
            _summaryCard('📖', 'Sözel', '$totalVerbal soru',
                const Color(0xFFE53170), isDark),
            const SizedBox(width: 10),
            _summaryCard('🔢', 'Sayısal', '$totalNumerical soru',
                const Color(0xFF2CB67D), isDark),
          ]),
          const SizedBox(height: 16),

          // ── CHART SWITCHER TABS ──────────────────────────────────────────
          Row(children: [
            _chartTabBtn('📊 Soru Dağılımı', 0, textColor, isDark),
            const SizedBox(width: 10),
            _chartTabBtn('⏰ Çalışma Süresi', 1, textColor, isDark),
          ]),
          const SizedBox(height: 14),

          // ── CHART ────────────────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                          begin: const Offset(0.05, 0), end: Offset.zero)
                      .animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: _chartIndex == 0
                  ? _buildSoruChart(
                      key: const ValueKey('soru'),
                      isDark: isDark,
                      textColor: textColor,
                      primary: primary,
                      tabIndex: _currentTabIndex,
                      dataHafta: dataHafta,
                      dataAy: dataAy,
                      dataYil: dataYil,
                    )
                  : _buildSureChart(
                      key: const ValueKey('sure'),
                      isDark: isDark,
                      textColor: textColor,
                      tabIndex: _currentTabIndex,
                      sureHafta: sureHafta,
                      sureAy: sureAy,
                      sureYil: sureYil,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartTabBtn(String label, int index, Color textColor, bool isDark) {
    final isActive = _chartIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _chartIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF7F5AF0), Color(0xFF00B4D8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight)
              : null,
          color: isActive
              ? null
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.08))),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: const Color(0xFF7F5AF0).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive
                    ? Colors.white
                    : textColor.withValues(alpha: 0.55))),
      ),
    );
  }

  Widget _buildSoruChart(
      {required Key key,
      required bool isDark,
      required Color textColor,
      required Color primary,
      required int tabIndex,
      required Map<int, _SoruData> dataHafta,
      required Map<int, _SoruData> dataAy,
      required Map<int, _SoruData> dataYil}) {
    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: _chartBoxDecoration(isDark, textColor),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
              tabIndex == 0
                  ? 'Haftalık Soru Dağılımı'
                  : tabIndex == 1
                      ? 'Aylık Soru Dağılımı'
                      : 'Yıllık Soru Dağılımı',
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
          Row(children: [
            _legendDot(const Color(0xFF00B4D8), 'Sayısal'),
            const SizedBox(width: 12),
            _legendDot(const Color(0xFFE53170), 'Sözel'),
          ]),
        ]),
        const SizedBox(height: 20),
        Expanded(
            child: BarChart(_buildSoruChartData(
                tabIndex, dataHafta, dataAy, dataYil, textColor, primary))),
      ]),
    );
  }

  Widget _buildSureChart(
      {required Key key,
      required bool isDark,
      required Color textColor,
      required int tabIndex,
      required Map<int, _SureData> sureHafta,
      required Map<int, _SureData> sureAy,
      required Map<int, _SureData> sureYil}) {
    final activeData = tabIndex == 0
        ? sureHafta
        : tabIndex == 1
            ? sureAy
            : sureYil;
    double maxVal = 0;
    for (var v in activeData.values) {
      final h = v.sure / 3600;
      if (h > maxVal) maxVal = h;
    }
    maxVal = (maxVal * 1.25);
    if (maxVal < 1) maxVal = 1;
    const accentColor = Color(0xFF7F5AF0);

    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: _chartBoxDecoration(isDark, textColor),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
              tabIndex == 0
                  ? 'Haftalık Çalışma Süresi'
                  : tabIndex == 1
                      ? 'Aylık Çalışma Süresi'
                      : 'Yıllık Çalışma Süresi',
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
          _legendDot(accentColor, 'Saat'),
        ]),
        const SizedBox(height: 20),
        Expanded(
            child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) {
                final totalSec = activeData[group.x]!.sure;
                final h = totalSec ~/ 3600;
                final m = (totalSec % 3600) ~/ 60;
                return BarTooltipItem(
                    '${h}s ${m}dk',
                    GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12));
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                String text = '';
                if (tabIndex == 0) {
                  const days = [
                    'Pzt',
                    'Sal',
                    'Çar',
                    'Per',
                    'Cum',
                    'Cmt',
                    'Paz'
                  ];
                  final idx = value.toInt() - 1;
                  if (idx >= 0 && idx < 7) text = days[idx];
                } else if (tabIndex == 1) {
                  if (value.toInt() % 5 == 0 || value.toInt() == 1) {
                    text = value.toInt().toString();
                  }
                } else {
                  const months = [
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
                  final idx = value.toInt() - 1;
                  if (idx >= 0 && idx < 12) text = months[idx];
                }
                return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(text,
                        style: TextStyle(
                            color: textColor.withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w600)));
              },
            )),
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, _) {
                      if (value == 0 || value == maxVal) {
                        return const SizedBox.shrink();
                      }
                      return Text('${value.toStringAsFixed(1)}s',
                          style: TextStyle(
                              color: textColor.withValues(alpha: 0.25),
                              fontSize: 9,
                              fontWeight: FontWeight.bold));
                    })),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                  color: textColor.withValues(alpha: 0.04), strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          barGroups: activeData.entries.map((e) {
            final hours = e.value.sure / 3600;
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: hours,
                width: tabIndex == 1 ? 6 : 14,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
                backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxVal,
                    color: textColor.withValues(alpha: 0.03)),
              ),
            ]);
          }).toList(),
        ))),
      ]),
    );
  }

  BoxDecoration _chartBoxDecoration(bool isDark, Color textColor) =>
      BoxDecoration(
        color: isDark ? const Color(0xFF13111C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
      );

  String _fmt(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return h > 0 ? '${h}s ${m}dk' : '${m}dk';
  }

  Widget _summaryCard(
      String emoji, String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  BarChartData _buildSoruChartData(
      int tabIndex,
      Map<int, _SoruData> dataHafta,
      Map<int, _SoruData> dataAy,
      Map<int, _SoruData> dataYil,
      Color textColor,
      Color primaryColor) {
    Map<int, _SoruData> activeData = tabIndex == 0
        ? dataHafta
        : tabIndex == 1
            ? dataAy
            : dataYil;
    double maxVal = 0;
    for (var v in activeData.values) {
      if (v.toplam > maxVal) maxVal = v.toplam.toDouble();
    }
    maxVal = (maxVal * 1.2).ceilToDouble();
    if (maxVal < 10) maxVal = 10;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxVal,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
            '${rod.toY.toInt()} Soru\nSayısal: ${activeData[group.x]!.sayisal} • Sözel: ${activeData[group.x]!.sozel}',
            GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, _) {
            String text = '';
            if (tabIndex == 0) {
              const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
              final idx = value.toInt() - 1;
              if (idx >= 0 && idx < 7) text = days[idx];
            } else if (tabIndex == 1) {
              if (value.toInt() % 5 == 0 || value.toInt() == 1) {
                text = value.toInt().toString();
              }
            } else {
              const months = [
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
              final idx = value.toInt() - 1;
              if (idx >= 0 && idx < 12) text = months[idx];
            }
            return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(text,
                    style: TextStyle(
                        color: textColor.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w600)));
          },
        )),
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  if (value == 0 || value == maxVal) {
                    return const SizedBox.shrink();
                  }
                  return Text('${value.toInt()}',
                      style: TextStyle(
                          color: textColor.withValues(alpha: 0.25),
                          fontSize: 9,
                          fontWeight: FontWeight.bold));
                })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: textColor.withValues(alpha: 0.04), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      barGroups: activeData.entries.map((e) {
        final sayisal = e.value.sayisal.toDouble();
        final sozel = e.value.sozel.toDouble();
        return BarChartGroupData(x: e.key, barRods: [
          BarChartRodData(
            toY: e.value.toplam.toDouble(),
            width: tabIndex == 1 ? 5 : 14,
            borderRadius: BorderRadius.circular(6),
            color: Colors.transparent,
            rodStackItems: [
              BarChartRodStackItem(0, sayisal, const Color(0xFF00B4D8)),
              BarChartRodStackItem(
                  sayisal, sayisal + sozel, const Color(0xFFE53170)),
            ],
            backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxVal,
                color: textColor.withValues(alpha: 0.03)),
          ),
        ]);
      }).toList(),
    );
  }
}
