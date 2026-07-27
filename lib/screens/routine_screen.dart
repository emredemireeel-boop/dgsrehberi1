import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/data_provider.dart';

class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final routine = dataProvider.todayRoutine;
    if (routine == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    final completedCount = routine.items.where((i) => i.isCompleted).length;
    final total = routine.items.length;
    final progress = total > 0 ? completedCount / total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Günlük Rutin',
                  style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              Text('${_todayLabel()} • $completedCount/$total tamamlandı',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: textColor.withValues(alpha: 0.4))),
            ]),
            if (routine.isSuccessful)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.amber.withValues(alpha: 0.2),
                    Colors.amber.withValues(alpha: 0.05)
                  ]),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Row(children: [
                  const Text('🏆', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text('Günün Hedefi',
                      style: GoogleFonts.inter(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ]),
              ),
          ]),
          const SizedBox(height: 20),

          // ── PROGRESS BAR ─────────────────────────────────────────────────
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('İlerleme',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600)),
              Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── LIST ─────────────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              itemCount: routine.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = routine.items[index];
                return _buildRoutineItem(
                    context, item, dataProvider, isDark, theme, textColor);
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── ADD BUTTON ───────────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showAddDialog(
                    context, dataProvider, theme, textColor, isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.25),
                        style: BorderStyle.solid),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded,
                            color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Yeni Rutin Ekle',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: theme.colorScheme.primary)),
                      ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── QUICK LOG ────────────────────────────────────────────────────
          _buildQuickLog(context, dataProvider, theme, textColor, isDark),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRoutineItem(BuildContext context, dynamic item,
      DataProvider provider, bool isDark, ThemeData theme, Color textColor) {
    final isCompleted = item.isCompleted as bool;

    return GestureDetector(
      onTap: () => provider.toggleRoutineItem(item.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCompleted
              ? theme.colorScheme.primary
                  .withValues(alpha: isDark ? 0.12 : 0.07)
              : (isDark ? const Color(0xFF13111C) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05)),
          ),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 8)
                ]
              : [],
        ),
        child: Row(children: [
          // Checkbox
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color:
                  isCompleted ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCompleted
                    ? theme.colorScheme.primary
                    : textColor.withValues(alpha: 0.25),
                width: 2,
              ),
              boxShadow: isCompleted
                  ? [
                      BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 6)
                    ]
                  : [],
            ),
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 14),

          // Title
          Expanded(
              child: Text(
            item.title as String,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
              color: isCompleted
                  ? theme.colorScheme.primary
                  : textColor.withValues(alpha: 0.85),
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              decorationColor: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          )),

          // Delete
          GestureDetector(
            onTap: () =>
                provider.removeRoutineTemplate(item.id, item.title as String),
            child: Icon(Icons.close_rounded,
                size: 18, color: textColor.withValues(alpha: 0.25)),
          ),
        ]),
      ),
    );
  }

  void _showAddDialog(BuildContext context, DataProvider provider,
      ThemeData theme, Color textColor, bool isDark) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1825) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 30)
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.add_task_rounded,
                  color: theme.colorScheme.primary, size: 26),
            ),
            const SizedBox(height: 14),
            Text('Yeni Rutin Ekle',
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: GoogleFonts.inter(
                  color: textColor, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Örn: 30 Geometri Sorusu',
                hintStyle:
                    GoogleFonts.inter(color: textColor.withValues(alpha: 0.3)),
                filled: true,
                fillColor: textColor.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: theme.colorScheme.primary, width: 1.5)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
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
                        color: textColor.withValues(alpha: 0.5))),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                ),
                onPressed: () {
                  if (ctrl.text.isNotEmpty) {
                    provider.addRoutineTemplate(ctrl.text);
                    Navigator.pop(ctx);
                  }
                },
                child: Text('Ekle',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildQuickLog(BuildContext context, DataProvider provider,
      ThemeData theme, Color textColor, bool isDark) {
    final sozCtrl = TextEditingController();
    final sayCtrl = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13111C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('✏️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('Hızlı Soru Kaydı',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _miniTextField(sozCtrl, 'Sözel', Icons.book_outlined,
                  const Color(0xFFE53170), textColor, isDark)),
          const SizedBox(width: 10),
          Expanded(
              child: _miniTextField(
                  sayCtrl,
                  'Sayısal',
                  Icons.calculate_outlined,
                  theme.colorScheme.primary,
                  textColor,
                  isDark)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              final soz = int.tryParse(sozCtrl.text) ?? 0;
              final say = int.tryParse(sayCtrl.text) ?? 0;
              if (soz > 0 || say > 0) {
                provider.addManualLog(soz, say);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('✅ Sorular kaydedildi!'),
                  backgroundColor: theme.colorScheme.secondary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
                sozCtrl.clear();
                sayCtrl.clear();
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  theme.colorScheme.primary,
                  Color.lerp(theme.colorScheme.primary, Colors.black, 0.2)!
                ]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 10)
                ],
              ),
              child:
                  const Icon(Icons.save_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _miniTextField(TextEditingController ctrl, String label, IconData icon,
      Color color, Color textColor, bool isDark) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
            color: textColor.withValues(alpha: 0.4), fontSize: 12),
        prefixIcon: Icon(icon, color: color, size: 18),
        filled: true,
        fillColor: color.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];
    return '${days[now.weekday - 1]}, ${now.day}.${now.month}.${now.year}';
  }
}
