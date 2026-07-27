import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../widgets/banner_ad_widget.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  static const List<String> _sayisalKonular = [
    'Temel Kavramlar - Dört İşlem',
    'Tek Çift Sayılar',
    'Ardışık ve Asal Sayılar',
    'Faktöriyel',
    'Basamak Kavramı',
    'Bölme Bölünebilme',
    'Basit Eşitsizlikler',
    'Mutlak Değer',
    'Rasyonel Sayılar',
    'Üslü İfadeler',
    'Köklü İfadeler',
    'Çarpanlara Ayırma',
    'Denklem Çözme',
    'Oran-Orantı',
    'Sayı - Kesir Problemleri',
    'Yaş Problemleri',
    'Hız-Hareket Problemleri',
    'Yüzde-Kar-Zarar Problemleri',
    'Grafik ve Tablo Problemleri',
    'Rutin Olmayan Problemler',
    'SAYISAL MANTIK',
    'Kümeler',
    'Fonksiyonlar',
    'Permütasyon-Kombinasyon',
    'Olasılık',
    'İşlem - Modüler Aritmetik',
    'Üçgenler',
    'Dörtgenler',
    'Çokgenler',
    'Çember - Daire',
    'Şekil - Mantık',
    'Katı Cisimler',
    'Analitik Geometri'
  ];

  static const List<String> _turkceKonular = [
    'Sözcükte Anlam',
    'Cümlede Anlam',
    'Paragrafta Anlam',
    'Sözel Mantık'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final completed = dataProvider.completedTopics;

    int sayisalCompleted =
        _sayisalKonular.where((k) => completed.contains(k)).length;
    int turkceCompleted =
        _turkceKonular.where((k) => completed.contains(k)).length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Geri Butonu & Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: textColor, size: 22),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Konularım',
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildPillHeader(sayisalCompleted, _sayisalKonular.length,
                turkceCompleted, _turkceKonular.length),

            const SizedBox(height: 20),

            // Arama Çubuğu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                onChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase()),
                style: GoogleFonts.inter(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Konu ara...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 14, color: textColor.withValues(alpha: 0.4)),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: textColor.withValues(alpha: 0.4), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 16,
                              color: textColor.withValues(alpha: 0.5)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: Color(0xFF7F5AF0), width: 1.5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 16),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_sayisalKonular, completed, dataProvider,
                      const Color(0xFF00B4D8)),
                  _buildList(_turkceKonular, completed, dataProvider,
                      const Color(0xFFFFB800)),
                ],
              ),
            )
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

  Widget _buildPillHeader(
      int sayCompleted, int sayTotal, int turkCompleted, int turkTotal) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
                child: _progressCircularCard(context, 'Sayısal', sayCompleted,
                    sayTotal, const Color(0xFF00B4D8))),
            const SizedBox(width: 16),
            Expanded(
                child: _progressCircularCard(context, 'Türkçe', turkCompleted,
                    turkTotal, const Color(0xFFFFB800))),
          ],
        ));
  }

  Widget _progressCircularCard(BuildContext context, String title,
      int completed, int total, Color color) {
    double prg = total == 0 ? 0 : completed / total;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13111C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: prg,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '${(prg * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('$completed / $total',
                  style: GoogleFonts.inter(
                      color: textColor.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
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
        color: isDark ? const Color(0xFF13111C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.color
            ?.withValues(alpha: 0.54),
        labelStyle:
            GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: 'Sayısal Konuları'),
          Tab(text: 'Türkçe Konuları'),
        ],
      ),
    );
  }

  Widget _buildList(List<String> topics, List<String> completed,
      DataProvider provider, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    // Arama filtresi
    final filteredTopics =
        topics.where((t) => t.toLowerCase().contains(_searchQuery)).toList();

    if (filteredTopics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: textColor.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text('Sonuç bulunamadı',
                style:
                    GoogleFonts.inter(color: textColor.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: filteredTopics.length,
      itemBuilder: (context, index) {
        final topic = filteredTopics[index];
        final isCompleted = completed.contains(topic);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isCompleted
                ? accentColor.withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF13111C) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCompleted
                  ? accentColor.withValues(alpha: 0.6)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05)),
            ),
            boxShadow: isCompleted
                ? [
                    BoxShadow(
                        color: accentColor.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              highlightColor: accentColor.withValues(alpha: 0.1),
              splashColor: accentColor.withValues(alpha: 0.2),
              onTap: () => provider.toggleTopic(topic),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? accentColor : Colors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? accentColor
                              : (isDark ? Colors.white38 : Colors.black26),
                          width: 2,
                        ),
                        boxShadow: isCompleted
                            ? [
                                BoxShadow(
                                    color: accentColor.withValues(alpha: 0.4),
                                    blurRadius: 8)
                              ]
                            : [],
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        topic,
                        style: GoogleFonts.inter(
                          color: isCompleted
                              ? (isDark ? Colors.white : accentColor)
                              : textColor.withValues(alpha: 0.85),
                          fontSize: 15,
                          fontWeight:
                              isCompleted ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
