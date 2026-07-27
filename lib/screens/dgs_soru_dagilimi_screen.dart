import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ad_service.dart';
import '../widgets/banner_ad_widget.dart';

class _TopicRow {
  final String topic;
  final List<String> values;
  final bool isBold;
  const _TopicRow(this.topic, this.values, {this.isBold = false});
}

const _sayisalYears = [2022, 2023, 2024, 2025];
const _sayisalData = <_TopicRow>[
  _TopicRow('Temel Kavramlar – Dört İşlem', ['1', '2', '1', '1']),
  _TopicRow('Tek Çift Sayılar', ['1', '1', '1', '1']),
  _TopicRow('Faktöriyel', ['1', '–', '1', '1']),
  _TopicRow('Basamak Kavramı', ['1', '1', '2', '3']),
  _TopicRow('Bölme – Bölünebilme', ['1', '1', '1', '1']),
  _TopicRow('Basit Eşitsizlikler', ['1', '2', '2', '2']),
  _TopicRow('Mutlak Değer', ['1', '1', '1', '1']),
  _TopicRow('Rasyonel Sayılar', ['1', '2', '1', '1']),
  _TopicRow('Üslü İfadeler', ['2', '2', '2', '2']),
  _TopicRow('Köklü İfadeler', ['1', '1', '1', '1']),
  _TopicRow('Çarpanlara Ayırma', ['–', '1', '–', '–']),
  _TopicRow('Denklem Çözme', ['1', '1', '–', '–']),
  _TopicRow('Sayı – Kesir Problemleri', ['5', '4', '4', '3']),
  _TopicRow('Yaş Problemleri', ['1', '1', '1', '1']),
  _TopicRow('Hız – Hareket Problemleri', ['1', '1', '1', '1']),
  _TopicRow('Yüzde – Kâr – Zarar Problemleri', ['3', '2', '1', '3']),
  _TopicRow('Grafik ve Tablo Problemleri', ['1', '2', '2', '3']),
  _TopicRow('Rutin Olmayan Problemler', ['1', '1', '1', '1']),
  _TopicRow('Sayısal Mantık', ['16', '13', '15', '12'], isBold: true),
  _TopicRow('Kümeler', ['1', '1', '1', '1']),
  _TopicRow('Fonksiyonlar', ['1', '–', '1', '1']),
  _TopicRow('Permütasyon – Kombinasyon', ['1', '1', '–', '1']),
  _TopicRow('Olasılık', ['–', '1', '1', '1']),
  _TopicRow('İşlem – Modüler Aritmetik', ['–', '1', '–', '–']),
  _TopicRow('Üçgenler', ['2', '1', '2', '2']),
  _TopicRow('Dörtgenler', ['1', '2', '1', '1']),
  _TopicRow('Çokgenler', ['1', '1', '1', '1']),
  _TopicRow('Çember – Daire', ['1', '1', '1', '1']),
  _TopicRow('Şekil – Mantık', ['–', '1', '1', '1']),
  _TopicRow('Katı Cisimler', ['1', '1', '1', '1']),
  _TopicRow('Analitik Geometri', ['1', '1', '1', '1']),
  _TopicRow('TOPLAM', ['50', '50', '50', '50'], isBold: true),
];

const _turkcYears = [2023, 2024, 2025];
const _turkceData = <_TopicRow>[
  _TopicRow('Sözcükte Anlam', ['5', '4', '4']),
  _TopicRow('Cümlede Anlam', ['15', '16', '16']),
  _TopicRow('Paragrafta Anlam', ['22', '22', '22']),
  _TopicRow('Sözel Mantık', ['8', '8', '8']),
  _TopicRow('TOPLAM', ['50', '50', '50'], isBold: true),
];

class DgsSoruDagilimiScreen extends StatefulWidget {
  const DgsSoruDagilimiScreen({super.key});

  @override
  State<DgsSoruDagilimiScreen> createState() => _DgsSoruDagilimiScreenState();
}

class _DgsSoruDagilimiScreenState extends State<DgsSoruDagilimiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Soru Dağılımı ekranı her açıldığında geçiş reklamı göster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.instance.showInterstitialAd();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTableView(
                    title: 'DGS Sayısal Soru Dağılımı',
                    years: _sayisalYears,
                    data: _sayisalData,
                    accentColor: const Color(0xFF00B4D8),
                  ),
                  _buildTableView(
                    title: 'DGS Türkçe Soru Dağılımı',
                    years: _turkcYears,
                    data: _turkceData,
                    accentColor: const Color(0xFFFFB800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: BannerAdWidget(),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: Theme.of(context).textTheme.bodyLarge?.color, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2CB67D), Color(0xFF2196F3)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.table_chart_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soru Dağılımı',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  'Çıkmış DGS sorularının ayrıştırılmış hali',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withValues(alpha: 0.54)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
        ),
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.color
            ?.withValues(alpha: 0.38),
        labelStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Sayısal'),
          Tab(text: 'Sözel / Türkçe'),
        ],
      ),
    );
  }

  Widget _buildTableView({
    required String title,
    required List<int> years,
    required List<_TopicRow> data,
    required Color accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table container
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Header row
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.2),
                        accentColor.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Text(
                            'KONULAR',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      ...years.map(
                        (y) => Expanded(
                          flex: 1,
                          child: Center(
                            child: Text(
                              '$y',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Data rows
                ...List.generate(data.length, (i) {
                  final row = data[i];
                  final isEven = i % 2 == 0;
                  final isTotalOrSection = row.isBold;

                  return Container(
                    decoration: BoxDecoration(
                      color: isTotalOrSection
                          ? accentColor.withValues(alpha: 0.12)
                          : isEven
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.02)
                                  : Colors.black.withValues(alpha: 0.02))
                              : Colors.transparent,
                      border: isTotalOrSection
                          ? Border(
                              top: BorderSide(
                                  color: accentColor.withValues(alpha: 0.2),
                                  width: 1),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Text(
                              row.topic,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isTotalOrSection
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isTotalOrSection
                                    ? accentColor
                                    : textColor.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ),
                        ...row.values.map(
                          (v) => Expanded(
                            flex: 1,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: isTotalOrSection
                                    ? BoxDecoration(
                                        color:
                                            accentColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      )
                                    : null,
                                child: Text(
                                  v,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: isTotalOrSection
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: v == '–'
                                        ? textColor.withValues(alpha: 0.24)
                                        : isTotalOrSection
                                            ? accentColor
                                            : textColor.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
