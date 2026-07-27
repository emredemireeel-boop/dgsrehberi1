import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/deneme_provider.dart';
import '../../models/deneme_kaydi.dart';

const _totalMinutes = 135;
const _totalSayisal = 50;
const _totalSozel = 50;

class SimulatorTab extends StatefulWidget {
  const SimulatorTab({super.key});
  @override
  State<SimulatorTab> createState() => _SimulatorTabState();
}

class _SimulatorTabState extends State<SimulatorTab>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  Duration _remaining = const Duration(minutes: _totalMinutes);
  bool _examStarted = false;
  bool _examFinished = false;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  bool _sayisalBitti = false;
  bool _sozelBitti = false;
  int _sayisalDogru = 0, _sayisalYanlis = 0;
  int _sozelDogru = 0, _sozelYanlis = 0;

  final _dogruCtrl = TextEditingController();
  final _yanlisCtrl = TextEditingController();

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _clockTimer?.cancel();
    _pulseCtrl.dispose();
    _dogruCtrl.dispose();
    _yanlisCtrl.dispose();
    super.dispose();
  }

  void _startExam() {
    setState(() {
      _examStarted = true;
      _elapsed = Duration.zero;
      _remaining = const Duration(minutes: _totalMinutes);
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed += const Duration(seconds: 1);
        _remaining = Duration(minutes: _totalMinutes) - _elapsed;
        if (_remaining <= Duration.zero) {
          _remaining = Duration.zero;
          _examFinished = true;
          _ticker?.cancel();
          _autoSave();
        }
      });
    });
  }

  void _resetExam() {
    _ticker?.cancel();
    setState(() {
      _examStarted = false;
      _examFinished = false;
      _elapsed = Duration.zero;
      _remaining = const Duration(minutes: _totalMinutes);
      _sayisalBitti = false;
      _sozelBitti = false;
      _sayisalDogru = 0;
      _sayisalYanlis = 0;
      _sozelDogru = 0;
      _sozelYanlis = 0;
    });
  }

  void _autoSave() {
    if (!mounted) return;
    final prov = Provider.of<DenemeProvider>(context, listen: false);
    final kayit = DenemeKaydi(
      id: DateTime.now().toIso8601String(),
      ad: prov.onerilAd(),
      tarih: DateTime.now(),
      sayisalDogru: _sayisalDogru,
      sayisalYanlis: _sayisalYanlis,
      sozelDogru: _sozelDogru,
      sozelYanlis: _sozelYanlis,
    );
    prov.denemeleriKaydet(kayit);
  }

  String _fmt(Duration d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.inHours)}:${p(d.inMinutes.remainder(60))}:${p(d.inSeconds.remainder(60))}';
  }

  DateTime _examClock() {
    final base = DateTime(_now.year, _now.month, _now.day, 10, 15);
    return _examStarted ? base.add(_elapsed) : base;
  }

  double get _progress =>
      (_elapsed.inSeconds / (_totalMinutes * 60)).clamp(0.0, 1.0);

  Color _remColor() {
    final m = _remaining.inMinutes;
    if (m > 60) return const Color(0xFF2CB67D);
    if (m > 30) return const Color(0xFFFFB800);
    return const Color(0xFFFF4D4D);
  }

  void _showBolumDialog(String title, int total, Function(int, int) onSave) {
    _dogruCtrl.clear();
    _yanlisCtrl.clear();
    showDialog(
      context: context,
      builder: (_) => _BolumDialog(
        title: title,
        totalSoru: total,
        dogruController: _dogruCtrl,
        yanlisController: _yanlisCtrl,
        onKaydet: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double toplamNet =
        (_sayisalDogru - _sayisalYanlis / 4) + (_sozelDogru - _sozelYanlis / 4);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // ─── SAAT & SÜRE PANELI ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                  : [const Color(0xFFE8E4FF), const Color(0xFFD4EEFF)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF7F5AF0).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF7F5AF0).withValues(alpha: 0.1),
                  blurRadius: 20)
            ],
          ),
          child: Row(children: [
            // SINAV SAATİ
            Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('SINAV SAATİ',
                  style: GoogleFonts.inter(
                      fontSize: 8,
                      color: tc.withValues(alpha: 0.4),
                      letterSpacing: 1.5)),
              const SizedBox(height: 6),
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  final dt = _examClock();
                  return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 38,
                            height: 38,
                            child: CustomPaint(
                                painter: AnalogClockPainter(
                                    time: dt, baseColor: tc))),
                        const SizedBox(width: 6),
                        Text(
                            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.robotoMono(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: tc)),
                      ]);
                },
              ),
            ])),
            Container(width: 1, height: 52, color: tc.withValues(alpha: 0.12)),
            // KALAN
            Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('KALAN',
                  style: GoogleFonts.inter(
                      fontSize: 8,
                      color: tc.withValues(alpha: 0.4),
                      letterSpacing: 1.5)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(_fmt(_remaining),
                    style: GoogleFonts.robotoMono(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _remColor(),
                        letterSpacing: 1)),
              ),
              Text('${_remaining.inMinutes}dk',
                  style: GoogleFonts.inter(
                      fontSize: 9, color: _remColor().withValues(alpha: 0.7))),
            ])),
            Container(width: 1, height: 52, color: tc.withValues(alpha: 0.12)),
            // GEÇEN
            Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('GEÇEN',
                  style: GoogleFonts.inter(
                      fontSize: 8,
                      color: tc.withValues(alpha: 0.4),
                      letterSpacing: 1.5)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(_fmt(_elapsed),
                    style: GoogleFonts.robotoMono(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: tc.withValues(alpha: 0.6),
                        letterSpacing: 1)),
              ),
              Text(
                  _examFinished
                      ? '✓ Bitti'
                      : (_examStarted ? '▶ Devam' : '○ Bekle'),
                  style: GoogleFonts.inter(
                      fontSize: 9, color: tc.withValues(alpha: 0.4))),
            ])),
          ]),
        ),
        const SizedBox(height: 12),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 10,
            backgroundColor: tc.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(_remColor()),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('10:15',
              style: GoogleFonts.inter(
                  fontSize: 10, color: tc.withValues(alpha: 0.35))),
          Text('${(_progress * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7F5AF0))),
          Text('12:30',
              style: GoogleFonts.inter(
                  fontSize: 10, color: tc.withValues(alpha: 0.35))),
        ]),
        const SizedBox(height: 18),
        // Başlat / Sıfırla butonu
        Row(children: [
          Expanded(
              child: _examStarted
                  ? _btn('Sıfırla', Icons.refresh, const Color(0xFFFF4D4D),
                      _resetExam)
                  : _btn('Sınavı Başlat', Icons.play_arrow_rounded,
                      const Color(0xFF2CB67D), _startExam)),
          const SizedBox(width: 12),
          Expanded(
              child: _btn(
            'Kaydet & Bitir',
            Icons.save_alt_rounded,
            const Color(0xFF7F5AF0),
            _examStarted && !_examFinished
                ? () {
                    _ticker?.cancel();
                    setState(() {
                      _examFinished = true;
                      _examStarted = false;
                    });
                    _autoSave();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Deneme kaydedildi! 📊 Kayıtlar sekmesine bakın.')));
                  }
                : null,
          )),
        ]),
        const SizedBox(height: 12),
        // Bölüm butonları
        Row(children: [
          Expanded(
              child: _sectionBtn(
            'Sayısal',
            Icons.calculate_outlined,
            const Color(0xFF00B4D8),
            _sayisalBitti,
            _sayisalBitti
                ? 'Net: ${(_sayisalDogru - _sayisalYanlis / 4).toStringAsFixed(1)}'
                : '$_totalSayisal soru',
            () {
              if (!_examStarted) return;
              if (!_sayisalBitti) {
                _showBolumDialog(
                    'Sayısal',
                    _totalSayisal,
                    (d, y) => setState(() {
                          _sayisalDogru = d;
                          _sayisalYanlis = y;
                          _sayisalBitti = true;
                        }));
              } else {
                setState(() {
                  _sayisalBitti = false;
                  _sayisalDogru = 0;
                  _sayisalYanlis = 0;
                });
              }
            },
          )),
          const SizedBox(width: 12),
          Expanded(
              child: _sectionBtn(
            'Sözel',
            Icons.menu_book_outlined,
            const Color(0xFFFFB800),
            _sozelBitti,
            _sozelBitti
                ? 'Net: ${(_sozelDogru - _sozelYanlis / 4).toStringAsFixed(1)}'
                : '$_totalSozel soru',
            () {
              if (!_examStarted) return;
              if (!_sozelBitti) {
                _showBolumDialog(
                    'Sözel',
                    _totalSozel,
                    (d, y) => setState(() {
                          _sozelDogru = d;
                          _sozelYanlis = y;
                          _sozelBitti = true;
                        }));
              } else {
                setState(() {
                  _sozelBitti = false;
                  _sozelDogru = 0;
                  _sozelYanlis = 0;
                });
              }
            },
          )),
        ]),
        const SizedBox(height: 16),
        _buildSonucPanel(toplamNet, tc, isDark),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback? onTap) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.white.withValues(alpha: 0.05)
              : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: disabled
                  ? Colors.white.withValues(alpha: 0.12)
                  : color.withValues(alpha: 0.5)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: disabled ? Colors.white24 : color, size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: disabled ? Colors.white24 : color)),
        ]),
      ),
    );
  }

  Widget _sectionBtn(String label, IconData icon, Color color, bool isDone,
      String sub, VoidCallback onTap) {
    final tc = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDone
              ? color.withValues(alpha: 0.18)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDone ? color : tc.withValues(alpha: 0.12),
              width: isDone ? 2 : 1),
        ),
        child: Row(children: [
          Icon(isDone ? Icons.check_circle_rounded : icon,
              color: isDone ? color : tc.withValues(alpha: 0.38), size: 24),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$label${isDone ? " ✓" : ""}',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDone ? color : tc)),
            Text(sub,
                style: GoogleFonts.inter(
                    fontSize: 11, color: tc.withValues(alpha: 0.38))),
          ]),
          if (!isDone) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('Bitir',
                  style: GoogleFonts.inter(fontSize: 11, color: color)),
            )
          ],
        ]),
      ),
    );
  }

  Widget _buildSonucPanel(double toplamNet, Color tc, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF0F0E17)]
              : [const Color(0xFFE8FFF4), const Color(0xFFD4F0FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: const Color(0xFF2CB67D).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF2CB67D).withValues(alpha: 0.1),
              blurRadius: 20)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFF2CB67D).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.insights,
                  color: Color(0xFF2CB67D), size: 20)),
          const SizedBox(width: 10),
          Text('Sonuç Analizi',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16, color: tc)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _statBox('Toplam Net', toplamNet.toStringAsFixed(1),
              const Color(0xFF2CB67D), Icons.done_all),
          const SizedBox(width: 10),
          _statBox('Tahmini Puan', (120 + toplamNet * 3).toStringAsFixed(0),
              const Color(0xFF7F5AF0), Icons.emoji_events),
          const SizedBox(width: 10),
          _statBox(
              'Sayısal',
              _sayisalBitti
                  ? (_sayisalDogru - _sayisalYanlis / 4).toStringAsFixed(1)
                  : '-',
              const Color(0xFF00B4D8),
              Icons.calculate_outlined),
          const SizedBox(width: 10),
          _statBox(
              'Sözel',
              _sozelBitti
                  ? (_sozelDogru - _sozelYanlis / 4).toStringAsFixed(1)
                  : '-',
              const Color(0xFFFFB800),
              Icons.menu_book_outlined),
        ]),
      ]),
    );
  }

  Widget _statBox(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 9, color: color.withValues(alpha: 0.7)),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ─── BÖLÜM DİYALOGU ────────────────────────────────────────────────────────
class _BolumDialog extends StatelessWidget {
  final String title;
  final int totalSoru;
  final TextEditingController dogruController;
  final TextEditingController yanlisController;
  final void Function(int, int) onKaydet;

  const _BolumDialog(
      {required this.title,
      required this.totalSoru,
      required this.dogruController,
      required this.yanlisController,
      required this.onKaydet});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: const Color(0xFF7F5AF0).withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF7F5AF0).withValues(alpha: 0.15),
                blurRadius: 30)
          ],
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: const Color(0xFF7F5AF0).withValues(alpha: 0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.assignment_turned_in,
                        color: Color(0xFF7F5AF0), size: 24)),
                const SizedBox(width: 14),
                Text('$title Tamamlandı',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Doğru',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2CB67D))),
                      const SizedBox(height: 6),
                      _numField(dogruController, const Color(0xFF2CB67D)),
                    ])),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Yanlış',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF4D4D))),
                      const SizedBox(height: 6),
                      _numField(yanlisController, const Color(0xFFFF4D4D)),
                    ])),
              ]),
              const SizedBox(height: 14),
              StatefulBuilder(builder: (_, set) {
                dogruController.addListener(() => set(() {}));
                yanlisController.addListener(() => set(() {}));
                final d = int.tryParse(dogruController.text) ?? 0;
                final y = int.tryParse(yanlisController.text) ?? 0;
                final net = d - y / 4;
                final hasErr = d + y > totalSoru;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasErr
                        ? const Color(0xFFFF4D4D).withValues(alpha: 0.1)
                        : const Color(0xFF7F5AF0).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: hasErr
                            ? const Color(0xFFFF4D4D)
                            : const Color(0xFF7F5AF0).withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    if (hasErr)
                      Text('Toplam $totalSoru soruyu aşamazsınız!',
                          style: GoogleFonts.inter(
                              color: const Color(0xFFFF4D4D),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _prev(net.toStringAsFixed(1), 'Net',
                              const Color(0xFF00B4D8)),
                          _prev('${totalSoru - d - y}', 'Boş', Colors.white54),
                        ]),
                  ]),
                );
              }),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text('İptal',
                      style: GoogleFonts.inter(color: Colors.white54)),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F5AF0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13)),
                  onPressed: () {
                    final d = int.tryParse(dogruController.text) ?? 0;
                    final y = int.tryParse(yanlisController.text) ?? 0;
                    if (d + y <= totalSoru) {
                      onKaydet(d, y);
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Kaydet',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                )),
              ]),
            ]),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, Color color) => TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.inter(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          filled: true,
          fillColor: color.withValues(alpha: 0.08),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );

  Widget _prev(String val, String label, Color c) => Column(children: [
        Text(val,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, fontSize: 18, color: c)),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, color: c.withValues(alpha: 0.7))),
      ]);
}

// ─── ANALOG SAAT ────────────────────────────────────────────────────────────
class AnalogClockPainter extends CustomPainter {
  final DateTime time;
  final Color baseColor;
  AnalogClockPainter({required this.time, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = baseColor.withValues(alpha: 0.05)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = baseColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    for (int i = 0; i < 60; i++) {
      final angle = i * 6 * pi / 180;
      final len = i % 5 == 0 ? 6.0 : 3.0;
      final sw = i % 5 == 0 ? 2.0 : 1.0;
      canvas.drawLine(
        Offset(center.dx + (radius - len) * cos(angle),
            center.dy + (radius - len) * sin(angle)),
        Offset(
            center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
        Paint()
          ..color = baseColor.withValues(alpha: 0.4)
          ..strokeWidth = sw,
      );
    }

    void hand(double angle, double len, double sw, Color c) {
      canvas.drawLine(
          center,
          Offset(center.dx + len * cos(angle - pi / 2),
              center.dy + len * sin(angle - pi / 2)),
          Paint()
            ..color = c
            ..strokeWidth = sw
            ..strokeCap = StrokeCap.round);
    }

    hand((time.hour % 12 + time.minute / 60) * 30 * pi / 180, radius * 0.45, 3,
        baseColor.withValues(alpha: 0.9));
    hand((time.minute + time.second / 60) * 6 * pi / 180, radius * 0.7, 2,
        baseColor.withValues(alpha: 0.7));
    canvas.drawCircle(center, 3, Paint()..color = baseColor);
  }

  @override
  bool shouldRepaint(covariant AnalogClockPainter old) => old.time != time;
}
