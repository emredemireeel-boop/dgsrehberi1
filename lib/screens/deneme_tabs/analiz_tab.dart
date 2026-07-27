import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/deneme_provider.dart';
import '../../models/deneme_kaydi.dart';

class AnalizTab extends StatefulWidget {
  const AnalizTab({super.key});
  @override
  State<AnalizTab> createState() => _AnalizTabState();
}

class _AnalizTabState extends State<AnalizTab> {
  int _chartIdx = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final prov = Provider.of<DenemeProvider>(context);
    final denemeler = prov.denemeler.reversed.toList();

    if (prov.denemeler.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.bar_chart, size: 64, color: tc.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        Text('Grafik için en az 1 deneme ekleyin',
            style: GoogleFonts.inter(
                fontSize: 15, color: tc.withValues(alpha: 0.35))),
        const SizedBox(height: 8),
        Text('Kayıtlar sekmesinden deneme ekleyebilirsin',
            style: GoogleFonts.inter(
                fontSize: 12, color: tc.withValues(alpha: 0.25))),
      ]));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _statCard('Ort. Net', prov.ortalamaToplamNet.toStringAsFixed(1),
              const Color(0xFF2CB67D), Icons.analytics_outlined),
          const SizedBox(width: 10),
          _statCard('En Yüksek', prov.enYuksekNet.toStringAsFixed(1),
              const Color(0xFF7F5AF0), Icons.trending_up),
          const SizedBox(width: 10),
          _statCard(
              'Gelişim',
              '${prov.gelisimTrend >= 0 ? '+' : ''}${prov.gelisimTrend.toStringAsFixed(1)}',
              prov.gelisimTrend >= 0
                  ? const Color(0xFF2CB67D)
                  : const Color(0xFFFF4D4D),
              Icons.show_chart),
          const SizedBox(width: 10),
          _statCard('Deneme', '${prov.denemeler.length}',
              const Color(0xFF00B4D8), Icons.assignment),
        ]),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chartTab('📈 Toplam Net', 0, tc),
            const SizedBox(width: 10),
            _chartTab('📊 Say. vs Söz.', 1, tc),
            const SizedBox(width: 10),
            _chartTab('🎯 D/Y Dağılımı', 2, tc),
          ]),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: const Offset(0.05, 0), end: Offset.zero)
                  .animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          child: [
            _ToplamNetChart(
                key: const ValueKey(0),
                denemeler: denemeler,
                isDark: isDark,
                tc: tc),
            _SayisalSozelChart(
                key: const ValueKey(1),
                denemeler: denemeler,
                isDark: isDark,
                tc: tc),
            _DYDagilimChart(
                key: const ValueKey(2),
                denemeler: denemeler,
                isDark: isDark,
                tc: tc),
          ][_chartIdx],
        ),
        const SizedBox(height: 20),
        _buildKarsilastirmaTablosu(denemeler, tc, isDark),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _chartTab(String label, int idx, Color tc) {
    final isActive = _chartIdx == idx;
    return GestureDetector(
      onTap: () => setState(() => _chartIdx = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF7F5AF0), Color(0xFF00B4D8)])
              : null,
          color: isActive ? null : tc.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive ? Colors.transparent : tc.withValues(alpha: 0.1)),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: const Color(0xFF7F5AF0).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : tc.withValues(alpha: 0.55))),
      ),
    );
  }

  Widget _statCard(String label, String val, Color color, IconData icon) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 10),
        Text(val,
            style: GoogleFonts.outfit(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600)),
      ]),
    ));
  }

  Widget _buildKarsilastirmaTablosu(
      List<DenemeKaydi> denemeler, Color tc, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13111C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tc.withValues(alpha: 0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Karşılaştırma Tablosu',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, fontSize: 15, color: tc)),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1)
          },
          children: [
            TableRow(children: [
              _th('Deneme', tc),
              _th('Say.Net', tc),
              _th('Söz.Net', tc),
              _th('Toplam', tc),
            ]),
            ...denemeler.reversed.take(10).map((d) => TableRow(children: [
                  _td(d.ad.length > 14 ? '${d.ad.substring(0, 14)}…' : d.ad,
                      tc),
                  _tdC(
                      d.sayisalNet.toStringAsFixed(1), const Color(0xFF00B4D8)),
                  _tdC(d.sozelNet.toStringAsFixed(1), const Color(0xFFFFB800)),
                  _tdC(d.toplamNet.toStringAsFixed(1), const Color(0xFF2CB67D)),
                ])),
          ],
        ),
      ]),
    );
  }

  Widget _th(String t, Color tc) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(t,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: tc.withValues(alpha: 0.45))),
      );
  Widget _td(String t, Color tc) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Text(t, style: GoogleFonts.inter(fontSize: 12, color: tc)),
      );
  Widget _tdC(String t, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Text(t,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.bold, color: c)),
      );
}

class _ToplamNetChart extends StatelessWidget {
  final List<DenemeKaydi> denemeler;
  final bool isDark;
  final Color tc;
  const _ToplamNetChart(
      {super.key,
      required this.denemeler,
      required this.isDark,
      required this.tc});

  @override
  Widget build(BuildContext context) {
    final spots = denemeler
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toplamNet))
        .toList();
    final maxY = spots.map((s) => s.y).reduce(max) * 1.3;
    final minY =
        (spots.map((s) => s.y).reduce(min) - 5).clamp(0.0, double.infinity);

    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13111C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tc.withValues(alpha: 0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text('Toplam Net Trendi',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 15, color: tc)),
        ),
        Expanded(
          child: LineChart(LineChartData(
            minY: minY,
            maxY: maxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((s) {
                  final d = denemeler[s.x.toInt()];
                  return LineTooltipItem(
                      '${d.ad}\n${s.y.toStringAsFixed(1)} Net',
                      GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11));
                }).toList(),
              ),
            ),
            gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: tc.withValues(alpha: 0.05), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                          style: TextStyle(
                              color: tc.withValues(alpha: 0.3), fontSize: 9)))),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= denemeler.length) {
                          return const SizedBox.shrink();
                        }
                        final name = denemeler[idx].ad;
                        final short =
                            name.length > 6 ? name.substring(0, 6) : name;
                        return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(short,
                                style: TextStyle(
                                    color: tc.withValues(alpha: 0.4),
                                    fontSize: 9)));
                      })),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: const Color(0xFF7F5AF0),
                barWidth: 3,
                dotData: FlDotData(
                    show: true,
                    getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                        radius: 5,
                        color: const Color(0xFF7F5AF0),
                        strokeWidth: 2,
                        strokeColor: Colors.white)),
                belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7F5AF0).withValues(alpha: 0.25),
                          const Color(0xFF7F5AF0).withValues(alpha: 0)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter)),
              )
            ],
          )),
        ),
      ]),
    );
  }
}

class _SayisalSozelChart extends StatelessWidget {
  final List<DenemeKaydi> denemeler;
  final bool isDark;
  final Color tc;
  const _SayisalSozelChart(
      {super.key,
      required this.denemeler,
      required this.isDark,
      required this.tc});

  @override
  Widget build(BuildContext context) {
    final saySpots = denemeler
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.sayisalNet))
        .toList();
    final sozSpots = denemeler
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.sozelNet))
        .toList();
    final allVals = [...saySpots.map((s) => s.y), ...sozSpots.map((s) => s.y)];
    final maxY = allVals.reduce(max) * 1.3;
    final minY = (allVals.reduce(min) - 2).clamp(0.0, double.infinity);

    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13111C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tc.withValues(alpha: 0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Sayısal vs Sözel Net',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 15, color: tc)),
            Row(children: [
              _leg(const Color(0xFF00B4D8), 'Sayısal'),
              const SizedBox(width: 12),
              _leg(const Color(0xFFFFB800), 'Sözel'),
            ]),
          ]),
        ),
        Expanded(
          child: LineChart(LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: tc.withValues(alpha: 0.05), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                          style: TextStyle(
                              color: tc.withValues(alpha: 0.3), fontSize: 9)))),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= denemeler.length) {
                          return const SizedBox.shrink();
                        }
                        final name = denemeler[idx].ad;
                        final short =
                            name.length > 6 ? name.substring(0, 6) : name;
                        return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(short,
                                style: TextStyle(
                                    color: tc.withValues(alpha: 0.4),
                                    fontSize: 9)));
                      })),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              _line(saySpots, const Color(0xFF00B4D8)),
              _line(sozSpots, const Color(0xFFFFB800))
            ],
          )),
        ),
      ]),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: color,
        barWidth: 2.5,
        dotData: FlDotData(
            show: spots.length <= 10,
            getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 2,
                strokeColor: Colors.white)),
        belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0)
            ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      );

  Widget _leg(Color c, String label) => Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.bold, color: c)),
      ]);
}

class _DYDagilimChart extends StatelessWidget {
  final List<DenemeKaydi> denemeler;
  final bool isDark;
  final Color tc;
  const _DYDagilimChart(
      {super.key,
      required this.denemeler,
      required this.isDark,
      required this.tc});

  @override
  Widget build(BuildContext context) {
    final shown = denemeler.take(8).toList();
    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13111C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tc.withValues(alpha: 0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('D / Y Dağılımı',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 15, color: tc)),
            Row(children: [
              _leg(const Color(0xFF2CB67D), 'Doğru'),
              const SizedBox(width: 10),
              _leg(const Color(0xFFFF4D4D), 'Yanlış'),
            ]),
          ]),
        ),
        Expanded(
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 110,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, _, rod, rodIdx) {
                  final d = shown[group.x];
                  final label = rodIdx == 0
                      ? 'D: ${d.sayisalDogru + d.sozelDogru}'
                      : 'Y: ${d.sayisalYanlis + d.sozelYanlis}';
                  return BarTooltipItem(
                      label,
                      GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11));
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= shown.length) {
                          return const SizedBox.shrink();
                        }
                        final name = shown[idx].ad;
                        final short =
                            name.length > 6 ? name.substring(0, 6) : name;
                        return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(short,
                                style: TextStyle(
                                    color: tc.withValues(alpha: 0.4),
                                    fontSize: 9)));
                      })),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                          style: TextStyle(
                              color: tc.withValues(alpha: 0.25),
                              fontSize: 9)))),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: tc.withValues(alpha: 0.04), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            barGroups: shown.asMap().entries.map((e) {
              final d = e.value;
              final totalD = (d.sayisalDogru + d.sozelDogru).toDouble();
              final totalY = (d.sayisalYanlis + d.sozelYanlis).toDouble();
              return BarChartGroupData(
                  x: e.key,
                  groupVertically: false,
                  barRods: [
                    BarChartRodData(
                        toY: totalD,
                        width: 10,
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF2CB67D), Color(0xFF1A9960)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter),
                        backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 110,
                            color: tc.withValues(alpha: 0.03))),
                    BarChartRodData(
                        toY: totalY,
                        width: 10,
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFF4D4D), Color(0xFFCC2222)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter),
                        backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 110,
                            color: tc.withValues(alpha: 0.03))),
                  ]);
            }).toList(),
          )),
        ),
      ]),
    );
  }

  Widget _leg(Color c, String label) => Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.bold, color: c)),
      ]);
}
