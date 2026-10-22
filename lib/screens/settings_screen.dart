import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/data_provider.dart';
import '../providers/theme_provider.dart';
import '../services/ad_service.dart';
import '../widgets/banner_ad_widget.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──────────────────────────────────────────────────────
              Row(children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: textColor, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7F5AF0), Color(0xFF2CB67D)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF7F5AF0).withValues(alpha: 0.4),
                          blurRadius: 16)
                    ],
                  ),
                  child: const Icon(Icons.settings_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ayarlar',
                      style: GoogleFonts.outfit(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  Text('Uygulama tercihleri',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: textColor.withValues(alpha: 0.4))),
                ]),
              ]),
              const SizedBox(height: 32),

              // ── SECTION: GÖRÜNÜM ────────────────────────────────────────────
              _sectionLabel('Görünüm', Icons.palette_outlined, textColor),
              const SizedBox(height: 12),
              _settingsCard(
                context: context,
                icon:
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                iconColor:
                    isDark ? const Color(0xFF7F5AF0) : const Color(0xFFFFB800),
                title: isDark ? 'Karanlık Mod' : 'Aydınlık Mod',
                subtitle: 'Göz konforu için karanlık ya da aydınlık temayı seç',
                trailing: _premiumSwitch(
                    isDark, (v) => themeProvider.toggleTheme(v), context),
              ),
              const SizedBox(height: 32),

              // ── SECTION: HEDEFLER ───────────────────────────────────────────
              _sectionLabel(
                  'Hedefler', Icons.track_changes_outlined, textColor),
              const SizedBox(height: 12),
              _goalCard(context, dataProvider, isDark, textColor),
              const SizedBox(height: 32),

              // ── SECTION: VERİ ───────────────────────────────────────────────
              _sectionLabel('Veri Yönetimi', Icons.storage_outlined, textColor),
              const SizedBox(height: 12),
              _settingsCard(
                context: context,
                icon: Icons.delete_sweep_rounded,
                iconColor: const Color(0xFFFF4757),
                title: 'Tüm Verileri Sıfırla',
                subtitle:
                    'İstatistikler, rutinler ve konu ilerlemeleri kalıcı olarak silinir',
                trailing: _dangerButton(
                    'Sıfırla', () => _confirmReset(context, dataProvider)),
              ),
              const SizedBox(height: 32),

              // ── SECTION: GİZLİLİK ────────────────────────────────────────────
              _sectionLabel('Gizlilik', Icons.privacy_tip_outlined, textColor),
              const SizedBox(height: 12),
              _settingsCard(
                context: context,
                icon: Icons.policy_outlined,
                title: 'Gizlilik Politikası',
                subtitle:
                    'Verilerin ve reklam hizmetlerinin nasıl işlendiğini gör',
                trailing: IconButton(
                  tooltip: 'Gizlilik politikasını aç',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: AdService.instance.privacyOptionsRequired,
                builder: (context, isRequired, _) => _settingsCard(
                  context: context,
                  icon: Icons.ads_click_rounded,
                  iconColor: const Color(0xFF2CB67D),
                  title: 'Reklam Gizliliği',
                  subtitle: isRequired
                      ? 'Reklam ve kişisel veri tercihlerini değiştir'
                      : 'Reklam tercihleri bulunduğunuz bölgede gerekli değil',
                  trailing: IconButton(
                    tooltip: 'Reklam gizliliği seçeneklerini aç',
                    icon: const Icon(Icons.tune_rounded),
                    onPressed:
                        isRequired ? () => _showPrivacyOptions(context) : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── INFO CARD ────────────────────────────────────────────────────
              _infoCard(context, isDark, textColor),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: BannerAdWidget(),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon, Color textColor) {
    return Row(children: [
      Icon(icon, size: 16, color: textColor.withValues(alpha: 0.4)),
      const SizedBox(width: 8),
      Text(text.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: 0.4),
              letterSpacing: 1.5)),
    ]);
  }

  Widget _settingsCard({
    required BuildContext context,
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final color = iconColor ?? const Color(0xFF7F5AF0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13111C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: GoogleFonts.inter(
                  fontSize: 12, color: textColor.withValues(alpha: 0.5))),
        ])),
        const SizedBox(width: 16),
        trailing,
      ]),
    );
  }

  Widget _premiumSwitch(
      bool value, ValueChanged<bool> onChanged, BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 56,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: value
              ? const LinearGradient(
                  colors: [Color(0xFF7F5AF0), Color(0xFF6246DB)])
              : null,
          color: value ? null : Colors.grey.withValues(alpha: 0.3),
          boxShadow: value
              ? [
                  BoxShadow(
                      color: const Color(0xFF7F5AF0).withValues(alpha: 0.4),
                      blurRadius: 8)
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
              child: value
                  ? const Icon(Icons.dark_mode,
                      size: 14, color: Color(0xFF7F5AF0))
                  : const Icon(Icons.light_mode,
                      size: 14, color: Color(0xFFFFB800)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dangerButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4757).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFFFF4757).withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: const Color(0xFFFF4757))),
      ),
    );
  }

  Future<void> _showPrivacyOptions(BuildContext context) async {
    final error = await AdService.instance.showPrivacyOptionsForm();
    if (!context.mounted || error == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Reklam gizliliği seçenekleri şu anda açılamadı. Lütfen tekrar deneyin.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _infoCard(BuildContext context, bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7F5AF0).withValues(alpha: 0.08),
            const Color(0xFF2CB67D).withValues(alpha: 0.08)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF7F5AF0).withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF7F5AF0).withValues(alpha: 0.2),
                  blurRadius: 10)
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/logosefaf.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DGS Rehberi',
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          Text('Çalışma takip uygulaması • v1.1.1',
              style: GoogleFonts.inter(
                  fontSize: 12, color: textColor.withValues(alpha: 0.5))),
        ])),
        Text('✨', style: TextStyle(fontSize: 28)),
      ]),
    );
  }

  void _confirmReset(BuildContext context, DataProvider dataProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1825) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFFFF4757).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFFF4757).withValues(alpha: 0.15),
                  blurRadius: 30)
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: const Color(0xFFFF4757).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFFF4757).withValues(alpha: 0.3))),
              child: const Icon(Icons.warning_rounded,
                  color: Color(0xFFFF4757), size: 32),
            ),
            const SizedBox(height: 16),
            Text('Verileri Sıfırla',
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 8),
            Text(
                'Bu işlem geri alınamaz. Tüm istatistikler, rutinler ve ilerlemeler silinecek.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: textColor.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: textColor.withValues(alpha: 0.15)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('İptal',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.6))),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4757),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                ),
                onPressed: () {
                  dataProvider.resetAllData();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Tüm veriler sıfırlandı.'),
                    backgroundColor: const Color(0xFFFF4757),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ));
                },
                child: Text('Sıfırla',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _goalCard(BuildContext context, DataProvider provider, bool isDark,
      Color textColor) {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF13111C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF2CB67D).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF2CB67D).withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.flag_rounded,
                    color: Color(0xFF2CB67D), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Günlük Çalışma Hedefi',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    const SizedBox(height: 3),
                    Text('Timer ilerlemesi için günlük dakika hedefiniz',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.5))),
                  ])),
            ],
          ),
          const SizedBox(height: 24),
          Consumer<DataProvider>(
            // React to changes continuously
            builder: (ctx, data, _) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (data.dailyGoalMinutes > 30) {
                        data.setDailyGoal(data.dailyGoalMinutes - 30);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: const Color(0xFF2CB67D),
                    iconSize: 32,
                  ),
                  Text(
                    '${data.dailyGoalMinutes} Dk',
                    style: GoogleFonts.robotoMono(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  IconButton(
                    onPressed: () {
                      if (data.dailyGoalMinutes < 600) {
                        data.setDailyGoal(data.dailyGoalMinutes + 30);
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: const Color(0xFF2CB67D),
                    iconSize: 32,
                  ),
                ]),
          ),
        ]));
  }
}
