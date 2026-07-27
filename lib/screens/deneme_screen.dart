import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'deneme_tabs/simulator_tab.dart';
import 'deneme_tabs/kayitlar_tab.dart';
import 'deneme_tabs/analiz_tab.dart';

class DenemeSScreen extends StatefulWidget {
  const DenemeSScreen({super.key});
  @override
  State<DenemeSScreen> createState() => _DenemeSScreenState();
}

class _DenemeSScreenState extends State<DenemeSScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F0E17), const Color(0xFF13111F)]
              : [const Color(0xFFF7F7F8), const Color(0xFFEEEEF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // ─── HEADER + TAB BAR ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: textColor.withValues(alpha: 0.07)),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_outlined,
                          color: Color(0xFF7F5AF0), size: 22),
                      const SizedBox(width: 10),
                      Text('DGS Deneme',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF7F5AF0).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF7F5AF0)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Text('100 Soru • 2s 15dk',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: const Color(0xFF7F5AF0))),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabCtrl,
                  indicatorColor: const Color(0xFF7F5AF0),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF7F5AF0),
                  unselectedLabelColor: textColor.withValues(alpha: 0.45),
                  labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                  tabs: const [
                    Tab(text: '🎯 Simülatör'),
                    Tab(text: '📋 Kayıtlar'),
                    Tab(text: '📈 Analiz'),
                  ],
                ),
              ],
            ),
          ),
          // ─── TAB CONTENT ────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [
                SimulatorTab(),
                KayitlarTab(),
                AnalizTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
