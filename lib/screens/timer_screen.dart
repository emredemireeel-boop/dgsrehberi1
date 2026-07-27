import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../providers/timer_provider.dart';
import '../providers/data_provider.dart';
import '../models/study_session.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/ad_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODE META — maps every TimerMode to its identity
// ─────────────────────────────────────────────────────────────────────────────
class _ModeMeta {
  final String label;
  final String emoji;
  final String description;
  final Color primary;
  final Color secondary;
  const _ModeMeta({
    required this.label,
    required this.emoji,
    required this.description,
    required this.primary,
    required this.secondary,
  });
}

const _modeMetaMap = {
  TimerMode.serbest: _ModeMeta(
    label: 'Serbest',
    emoji: '🌊',
    description: 'Kendi Ritminle Çalış',
    primary: Color(0xFF7F5AF0),
    secondary: Color(0xFF6246DB),
  ),
  TimerMode.pomodoro: _ModeMeta(
    label: 'Pomodoro',
    emoji: '🍅',
    description: '25dk Çalış • 5dk Mola',
    primary: Color(0xFFFF6B6B),
    secondary: Color(0xFFE05050),
  ),
  TimerMode.derinOdak: _ModeMeta(
    label: 'Derin Odak',
    emoji: '🧠',
    description: '60dk Çalış • 15dk Mola',
    primary: Color(0xFF2CB67D),
    secondary: Color(0xFF1E9968),
  ),
  TimerMode.maraton: _ModeMeta(
    label: 'Maraton',
    emoji: '🏃',
    description: '120dk Çalış • 30dk Mola',
    primary: Color(0xFFFF9F1C),
    secondary: Color(0xFFE68A00),
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED RING PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress; // 0 → 1
  final Color color;
  final double strokeWidth;
  final List<Color> glowColors;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.glowColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    // Glow layers
    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + (i * 6.0)
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.06 * i)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweepAngle, false, glowPaint);
    }

    // Track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, trackPaint);

    // Main arc with gradient
    if (progress > 0) {
      final shader = SweepGradient(
        center: Alignment.center,
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [color.withValues(alpha: 0.4), color],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = shader;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweepAngle, false, arcPaint);

      // Tip dot
      final tipX = center.dx + radius * math.cos(startAngle + sweepAngle);
      final tipY = center.dy + radius * math.sin(startAngle + sweepAngle);
      final dotPaint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 2 + 2, dotPaint);
      canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 2,
          Paint()..color = Colors.white.withValues(alpha: 0.9));
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// PARTICLE PAINTER (subtle background particles)
// ─────────────────────────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double tick;
  final Color color;
  static final _rand = math.Random(42);
  static final _particles = List.generate(
      18,
      (_) => [
            _rand.nextDouble(), // x ratio
            _rand.nextDouble(), // y ratio
            _rand.nextDouble() * 2 * math.pi, // phase
            _rand.nextDouble() * 3 + 1, // radius
            _rand.nextDouble() * 0.4 + 0.05, // opacity
          ]);

  const _ParticlePainter({required this.tick, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final x = p[0] * size.width + math.sin(tick + p[2]) * 12;
      final y = p[1] * size.height + math.cos(tick * 0.7 + p[2]) * 10;
      final r = p[3];
      final o = p[4] * 0.6;
      canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..color = color.withValues(alpha: o)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.tick != tick;
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  late AnimationController _particleCtrl;
  late AnimationController _modeChangeCtrl;
  late Animation<double> _modeFadeAnim;
  late Animation<double> _modeScaleAnim;

  late AnimationController _cardEntranceCtrl;
  late Animation<double> _cardEntranceAnim;

  TimerMode? _lastMode;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _particleCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();

    _modeChangeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _modeFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _modeChangeCtrl, curve: Curves.easeOut));
    _modeScaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _modeChangeCtrl, curve: Curves.easeOutBack));

    _cardEntranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _cardEntranceAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _cardEntranceCtrl, curve: Curves.easeOutBack));
    _cardEntranceCtrl.forward();
    _modeChangeCtrl.forward();

    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Android 13+ için bildirim izni iste
    final NotificationPermission notificationPermissionStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    _modeChangeCtrl.dispose();
    _cardEntranceCtrl.dispose();
    super.dispose();
  }

  void _onModeChanged() {
    _modeChangeCtrl.forward(from: 0);
  }

  void _saveSession(
      BuildContext context, int durationSeconds, int breakSeconds) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);

    final TextEditingController verbalController = TextEditingController();
    final TextEditingController numericalController = TextEditingController();
    String selectedSubject = 'Matematik';
    final List<String> subjects = [
      'Matematik',
      'Türkçe',
      'Geometri',
      'Sayısal M.',
      'Sözel M.',
      'Diğer'
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
          final meta = _modeMetaMap[timerProvider.currentMode]!;

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E1B2E), const Color(0xFF13111C)]
                      : [Colors.white, const Color(0xFFF8F7FF)],
                ),
                border: Border.all(
                    color: meta.primary.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: meta.primary.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: -5),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            meta.primary.withValues(alpha: 0.15),
                            meta.primary.withValues(alpha: 0.05)
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [meta.primary, meta.secondary]),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: meta.primary.withValues(alpha: 0.4),
                                    blurRadius: 16)
                              ],
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 12),
                          Text('Oturum Tamamlandı!',
                              style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _sessionInfoChip(
                                  Icons.timer_outlined,
                                  '${durationSeconds ~/ 60}dk çalışma',
                                  meta.primary),
                              const SizedBox(width: 8),
                              _sessionInfoChip(Icons.coffee_outlined,
                                  '${breakSeconds ~/ 60}dk mola', Colors.amber),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Body
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Konu Seçimi
                          Text('Hangi Konuya Çalıştın?',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor.withValues(alpha: 0.5),
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: subjects.map((sub) {
                              final isSelected = selectedSubject == sub;
                              return ChoiceChip(
                                label: Text(sub),
                                selected: isSelected,
                                selectedColor:
                                    meta.primary.withValues(alpha: 0.2),
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05),
                                labelStyle: GoogleFonts.inter(
                                  color: isSelected
                                      ? meta.primary
                                      : textColor.withValues(alpha: 0.7),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(
                                    color: isSelected
                                        ? meta.primary.withValues(alpha: 0.5)
                                        : Colors.transparent),
                                onSelected: (val) {
                                  if (val) {
                                    setDialogState(() => selectedSubject = sub);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          Text('Çözdüğün Soruları Gir (Opsiyonel)',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor.withValues(alpha: 0.5),
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 16),
                          _premiumTextField(ctx, verbalController, 'Sözel Soru',
                              Icons.book_outlined, const Color(0xFFE53170)),
                          const SizedBox(height: 12),
                          _premiumTextField(
                              ctx,
                              numericalController,
                              'Sayısal Soru',
                              Icons.calculate_outlined,
                              meta.primary),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        textColor.withValues(alpha: 0.6),
                                    side: BorderSide(
                                        color:
                                            textColor.withValues(alpha: 0.15)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  onPressed: () {
                                    dataProvider.addSession(StudySession(
                                      id: DateTime.now().toIso8601String(),
                                      date: DateTime.now(),
                                      durationSeconds: durationSeconds,
                                      breakSeconds: breakSeconds,
                                      verbalQuestions: 0,
                                      numericalQuestions: 0,
                                      subject: selectedSubject,
                                    ));
                                    timerProvider.resetTimer();
                                    Navigator.pop(ctx);
                                  },
                                  child: Text('Soruları Atla',
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        colors: [meta.primary, meta.secondary]),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                          color: meta.primary
                                              .withValues(alpha: 0.4),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4))
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                    onPressed: () {
                                      int vCount =
                                          int.tryParse(verbalController.text) ??
                                              0;
                                      int nCount = int.tryParse(
                                              numericalController.text) ??
                                          0;
                                      dataProvider.addSession(StudySession(
                                        id: DateTime.now().toIso8601String(),
                                        date: DateTime.now(),
                                        durationSeconds: durationSeconds,
                                        breakSeconds: breakSeconds,
                                        verbalQuestions: vCount,
                                        numericalQuestions: nCount,
                                        subject: selectedSubject,
                                      ));
                                      timerProvider.resetTimer();
                                      Navigator.pop(ctx);
                                    },
                                    child: Text('Kaydet',
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _sessionInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(text,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _premiumTextField(BuildContext ctx, TextEditingController controller,
      String label, IconData icon, Color color) {
    final theme = Theme.of(ctx);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.outfit(
          color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
            color: textColor.withValues(alpha: 0.45), fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textColor.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);

    final isRunning = timerProvider.isRunning;
    final isBreak = timerProvider.isBreakMode;
    final mode = timerProvider.currentMode;
    final meta = _modeMetaMap[mode]!;

    // Detect mode change for animation — post frame to avoid setState-during-build
    if (_lastMode != mode) {
      _lastMode = mode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onModeChanged();
      });
    }

    // Pulse — post frame to avoid setState-during-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (isRunning) {
        if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
      } else {
        if (_pulseCtrl.isAnimating) {
          _pulseCtrl.stop();
          _pulseCtrl.animateTo(0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut);
        }
      }
    });

    final ringColor = isBreak ? const Color(0xFFFFB800) : meta.primary;
    final bool isFocusFinished = mode != TimerMode.serbest &&
        !isBreak &&
        timerProvider.secondsElapsed >= timerProvider.focusTargetSeconds;
    final bool isBreakFinished = mode != TimerMode.serbest &&
        isBreak &&
        timerProvider.breakSecondsElapsed >= timerProvider.breakTargetSeconds;

    double ringProgress;
    if (mode == TimerMode.serbest) {
      ringProgress = 0;
    } else if (isBreak) {
      ringProgress = timerProvider.breakProgress.clamp(0.0, 1.0);
    } else {
      ringProgress = timerProvider.focusProgress.clamp(0.0, 1.0);
    }

    return Column(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _cardEntranceAnim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - _cardEntranceAnim.value)),
                child: Opacity(
                    opacity: _cardEntranceAnim.value.clamp(0.0, 1.0),
                    child: child),
              );
            },
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (context, _) {
                return Stack(
                  children: [
                    // Background particles
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ParticlePainter(
                          tick: _particleCtrl.value * 2 * math.pi,
                          color: ringColor,
                        ),
                      ),
                    ),
                    // Main scrollable content
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            children: [
                              // ── MODE SELECTOR ──────────────────────────────
                              _ModeSelector(
                                currentMode: mode,
                                onModeChange: (newMode) {
                                  if (timerProvider.secondsElapsed > 0 ||
                                      timerProvider.breakSecondsElapsed > 0) {
                                    _showResetDialog(
                                        context, timerProvider, newMode);
                                  } else {
                                    timerProvider.setMode(newMode);
                                  }
                                },
                              ),
                              const SizedBox(height: 28),

                              // ── STATUS BADGE ───────────────────────────────
                              AnimatedBuilder(
                                animation: _modeScaleAnim,
                                builder: (context, child) => Transform.scale(
                                    scale: _modeScaleAnim.value,
                                    child: Opacity(
                                        opacity: _modeFadeAnim.value,
                                        child: child)),
                                child: _StatusBadge(
                                  mode: mode,
                                  isBreak: isBreak,
                                  isRunning: isRunning,
                                  isFocusFinished: isFocusFinished,
                                  isBreakFinished: isBreakFinished,
                                  meta: meta,
                                  timerProvider: timerProvider,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ── RING + TIMER ───────────────────────────────
                              AnimatedBuilder(
                                animation: _pulseAnim,
                                builder: (context, child) => Transform.scale(
                                    scale: _pulseAnim.value, child: child),
                                child: _TimerRing(
                                  timeText: isBreak
                                      ? timerProvider.formattedBreakTime
                                      : timerProvider.formattedTime,
                                  progress: mode == TimerMode.serbest
                                      ? null
                                      : ringProgress,
                                  ringColor: ringColor,
                                  isBreak: isBreak,
                                  isRunning: isRunning,
                                  mode: mode,
                                  meta: meta,
                                  timerProvider: timerProvider,
                                ),
                              ),
                              const SizedBox(height: 36),

                              // ── SERBEST STAT PILLS ─────────────────────────
                              if (mode == TimerMode.serbest) ...[
                                _SerbestStatRow(
                                    timerProvider: timerProvider, meta: meta),
                                const SizedBox(height: 32),
                              ],

                              // ── ACTION BUTTONS ─────────────────────────────
                              _ActionButtons(
                                timerProvider: timerProvider,
                                meta: meta,
                                isFocusFinished: isFocusFinished,
                                isBreakFinished: isBreakFinished,
                                onSave: (dur, brk) =>
                                    _saveSession(context, dur, brk),
                              ),

                              const SizedBox(height: 24),

                              // ── DAILY GOAL & STREAK ────────────────────────
                              _DailyGoalProgress(
                                dataProvider:
                                    Provider.of<DataProvider>(context),
                                timerProvider: timerProvider,
                                isDark: Theme.of(context).brightness ==
                                    Brightness.dark,
                              ),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: BannerAdWidget(),
          ),
        ),
      ],
    );
  }

  void _showResetDialog(
      BuildContext context, TimerProvider timerProvider, TimerMode newMode) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? const Color(0xFF1A1825) : Colors.white,
            border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.0)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), blurRadius: 40)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 44),
              const SizedBox(height: 14),
              Text('Mod Değişimi',
                  style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color)),
              const SizedBox(height: 8),
              Text(
                'Modu değiştirirseniz mevcut sayaç sıfırlanır. Emin misiniz?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: (theme.textTheme.bodyLarge?.color ?? Colors.white)
                        .withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: (theme.textTheme.bodyLarge?.color ??
                                    Colors.white)
                                .withValues(alpha: 0.15)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('İptal',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: (theme.textTheme.bodyLarge?.color ??
                                      Colors.white)
                                  .withValues(alpha: 0.6))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        timerProvider.setMode(newMode);
                      },
                      child: Text('Sıfırla',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// MODE SELECTOR WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _ModeSelector extends StatelessWidget {
  final TimerMode currentMode;
  final ValueChanged<TimerMode> onModeChange;

  const _ModeSelector({required this.currentMode, required this.onModeChange});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modes = TimerMode.values;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: modes.map((mode) {
          final meta = _modeMetaMap[mode]!;
          final isSelected = mode == currentMode;
          return Expanded(
            child: GestureDetector(
              onTap: () => onModeChange(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [meta.primary, meta.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)
                      : null,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: meta.primary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 3))
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(meta.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.45)
                                : Colors.black.withValues(alpha: 0.45)),
                      ),
                      child: Text(meta.label, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final TimerMode mode;
  final bool isBreak, isRunning, isFocusFinished, isBreakFinished;
  final _ModeMeta meta;
  final TimerProvider timerProvider;

  const _StatusBadge({
    required this.mode,
    required this.isBreak,
    required this.isRunning,
    required this.isFocusFinished,
    required this.isBreakFinished,
    required this.meta,
    required this.timerProvider,
  });

  @override
  Widget build(BuildContext context) {
    String statusText;
    String statusEmoji;
    Color statusColor;
    IconData? statusIcon;

    if (isFocusFinished) {
      statusText = 'Odaklanma Tamamlandı!';
      statusEmoji = '🎉';
      statusColor = meta.primary;
      statusIcon = Icons.check_circle_outline;
    } else if (isBreakFinished) {
      statusText = 'Mola Bitti!';
      statusEmoji = '⚡';
      statusColor = const Color(0xFFFFB800);
      statusIcon = Icons.bolt;
    } else if (isBreak) {
      statusText = timerProvider.currentSet >= timerProvider.totalSets
          ? 'Uzun Mola'
          : 'Mola Zamanı';
      statusEmoji = '☕';
      statusColor = const Color(0xFFFFB800);
      statusIcon = Icons.coffee_outlined;
    } else if (isRunning) {
      statusText = meta.description;
      statusEmoji = '🔥';
      statusColor = meta.primary;
      statusIcon = Icons.local_fire_department_outlined;
    } else if (timerProvider.secondsElapsed > 0) {
      statusText = 'Duraklatıldı';
      statusEmoji = '⏸';
      statusColor = Colors.grey;
      statusIcon = Icons.pause_circle_outline;
    } else {
      statusText = meta.description;
      statusEmoji = meta.emoji;
      statusColor = meta.primary;
      statusIcon = null;
    }

    // Pomodoro sets indicator
    Widget? setsWidget;
    if (mode == TimerMode.pomodoro && !isFocusFinished && !isBreakFinished) {
      setsWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(timerProvider.totalSets, (i) {
          final done = i < timerProvider.currentSet - 1;
          final current = i == timerProvider.currentSet - 1;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: current ? 18 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: done
                  ? meta.primary
                  : current
                      ? meta.primary.withValues(alpha: 0.7)
                      : meta.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (statusIcon != null) ...[
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 7),
              ] else ...[
                Text(statusEmoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 7),
              ],
              Text(statusText,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: statusColor)),
            ],
          ),
        ),
        if (setsWidget != null) ...[
          const SizedBox(height: 12),
          setsWidget,
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMER RING WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _TimerRing extends StatelessWidget {
  final String timeText;
  final double? progress; // null = serbest (no ring)
  final Color ringColor;
  final bool isBreak, isRunning;
  final TimerMode mode;
  final _ModeMeta meta;
  final TimerProvider timerProvider;

  const _TimerRing({
    required this.timeText,
    required this.progress,
    required this.ringColor,
    required this.isBreak,
    required this.isRunning,
    required this.mode,
    required this.meta,
    required this.timerProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    const double size = 280;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Outer glow disc
          if (isRunning)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: ringColor.withValues(alpha: 0.15),
                      blurRadius: 60,
                      spreadRadius: 20),
                ],
              ),
            ),

          // Glass disc
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1E1B2E),
                        const Color(0xFF13111C),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFF2F0FF),
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1.5,
              ),
            ),
          ),

          // Progress ring
          if (progress != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: CustomPaint(
                painter: _RingPainter(
                  progress: 1.0 - progress!,
                  color: ringColor,
                  strokeWidth: 10,
                  glowColors: [ringColor],
                ),
              ),
            ),

          // Serbest "free ring" decoration
          if (progress == null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: CustomPaint(
                painter: _RingPainter(
                  progress: 0.0,
                  color: meta.primary,
                  strokeWidth: 10,
                  glowColors: [meta.primary],
                ),
              ),
            ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBreak)
                  Text('☕', style: const TextStyle(fontSize: 22))
                else if (isRunning)
                  Text(meta.emoji, style: const TextStyle(fontSize: 22))
                else
                  const SizedBox.shrink(),
                if (isBreak || isRunning) const SizedBox(height: 4),
                Text(
                  timeText,
                  style: GoogleFonts.robotoMono(
                    fontSize: mode == TimerMode.serbest ? 52 : 48,
                    fontWeight: FontWeight.w200,
                    color: isBreak ? const Color(0xFFFFB800) : textColor,
                    letterSpacing: -1,
                  ),
                ),
                if (mode != TimerMode.serbest) ...[
                  const SizedBox(height: 4),
                  Text(
                    isBreak ? 'MOLA' : 'ODAKLANMA',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: (isBreak ? const Color(0xFFFFB800) : meta.primary)
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERBEST STAT ROW
// ─────────────────────────────────────────────────────────────────────────────
class _SerbestStatRow extends StatelessWidget {
  final TimerProvider timerProvider;
  final _ModeMeta meta;

  const _SerbestStatRow({required this.timerProvider, required this.meta});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            isDark: isDark,
            icon: Icons.timer_outlined,
            label: 'Çalışma',
            value: timerProvider.formattedTime,
            color: meta.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            isDark: isDark,
            icon: Icons.coffee_outlined,
            label: 'Mola',
            value: timerProvider.formattedBreakTime,
            color: const Color(0xFFFFB800),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.7))),
              Text(value,
                  style: GoogleFonts.robotoMono(
                      fontSize: 17, fontWeight: FontWeight.w300, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTONS
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final TimerProvider timerProvider;
  final _ModeMeta meta;
  final bool isFocusFinished;
  final bool isBreakFinished;
  final void Function(int dur, int brk) onSave;

  const _ActionButtons({
    required this.timerProvider,
    required this.meta,
    required this.isFocusFinished,
    required this.isBreakFinished,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = timerProvider.isRunning;
    final isBreak = timerProvider.isBreakMode;
    final mode = timerProvider.currentMode;

    // ── Primary Action
    String primaryLabel;
    IconData primaryIcon;
    Color primaryColor;
    VoidCallback primaryAction;

    if (isFocusFinished) {
      primaryLabel = 'Molaya Geç';
      primaryIcon = Icons.coffee_rounded;
      primaryColor = const Color(0xFFFFB800);
      primaryAction = () {
        AdService.instance.showInterstitialAd(
          onAdDismissed: () => timerProvider.startBreak(),
        );
      };
    } else if (isBreakFinished) {
      primaryLabel = 'Sonraki Tur';
      primaryIcon = Icons.skip_next_rounded;
      primaryColor = meta.primary;
      primaryAction = () {
        if (mode == TimerMode.pomodoro &&
            timerProvider.currentSet < timerProvider.totalSets) {
          timerProvider.skipToWork();
        } else {
          onSave(
              timerProvider.secondsElapsed, timerProvider.breakSecondsElapsed);
        }
      };
    } else if (!isRunning && !isBreak && timerProvider.secondsElapsed > 0) {
      primaryLabel = 'Devam Et';
      primaryIcon = Icons.play_arrow_rounded;
      primaryColor = meta.primary;
      primaryAction = () => timerProvider.startTimer();
    } else if (isRunning && !isBreak) {
      if (mode == TimerMode.serbest) {
        primaryLabel = 'Molaya Çık';
        primaryIcon = Icons.coffee_rounded;
        primaryColor = const Color(0xFFFFB800);
        primaryAction = () {
          AdService.instance.showInterstitialAd(
            onAdDismissed: () => timerProvider.startBreak(),
          );
        };
      } else {
        primaryLabel = 'Duraklat';
        primaryIcon = Icons.pause_rounded;
        primaryColor = meta.primary;
        primaryAction = () => timerProvider.pauseTimer();
      }
    } else if (isRunning && isBreak) {
      if (mode == TimerMode.serbest) {
        primaryLabel = 'Çalışmaya Dön';
        primaryIcon = Icons.play_arrow_rounded;
        primaryColor = meta.primary;
        primaryAction = () => timerProvider.startTimer();
      } else {
        primaryLabel = 'Molayı Duraklat';
        primaryIcon = Icons.pause_rounded;
        primaryColor = const Color(0xFFFFB800);
        primaryAction = () => timerProvider.pauseTimer();
      }
    } else if (!isRunning && isBreak && timerProvider.breakSecondsElapsed > 0) {
      primaryLabel = 'Molaya Devam';
      primaryIcon = Icons.play_arrow_rounded;
      primaryColor = const Color(0xFFFFB800);
      primaryAction = () => timerProvider.startBreak();
    } else {
      primaryLabel = 'Başlat';
      primaryIcon = Icons.play_arrow_rounded;
      primaryColor = meta.primary;
      primaryAction = () => timerProvider.startTimer();
    }

    return Column(
      children: [
        // ── PRIMARY BIG BUTTON
        GestureDetector(
          onTap: primaryAction,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                colors: [
                  primaryColor,
                  Color.lerp(primaryColor, Colors.black, 0.3)!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                    color: primaryColor.withValues(alpha: 0.45),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 8)),
                BoxShadow(
                    color: primaryColor.withValues(alpha: 0.15),
                    blurRadius: 60,
                    spreadRadius: 10),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(primaryIcon, color: Colors.white, size: 48),
                  const SizedBox(height: 6),
                  Text(primaryLabel,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.9))),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // ── SECONDARY BUTTONS ROW
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            // Bitir
            if (timerProvider.secondsElapsed > 0 &&
                !isFocusFinished &&
                !isBreakFinished)
              _SecondaryButton(
                  label: 'Bitir & Kaydet',
                  icon: Icons.stop_rounded,
                  color: const Color(0xFFFF4757),
                  onTap: () {
                    timerProvider.pauseTimer();
                    AdService.instance.showInterstitialAd(
                      onAdDismissed: () => onSave(timerProvider.secondsElapsed,
                          timerProvider.breakSecondsElapsed),
                    );
                  }),

            // Erken Mola (odak modlarında çalışırken)
            if (isRunning && !isBreak && mode != TimerMode.serbest)
              _SecondaryButton(
                  label: 'Erken Mola',
                  icon: Icons.fast_forward_rounded,
                  color: Colors.orangeAccent,
                  onTap: () => timerProvider.skipToBreak()),

            // Erken Dön (odak modlarında molada)
            if (isRunning && isBreak && mode != TimerMode.serbest)
              _SecondaryButton(
                  label: 'Erken Dön',
                  icon: Icons.fast_forward_rounded,
                  color: meta.primary,
                  onTap: () => timerProvider.skipToWork()),

            // Finish session
            if (isBreakFinished)
              _SecondaryButton(
                  label: 'Bitir & Kaydet',
                  icon: Icons.save_outlined,
                  color: const Color(0xFF2CB67D),
                  onTap: () => onSave(timerProvider.secondsElapsed,
                      timerProvider.breakSecondsElapsed)),
          ],
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAILY GOAL & STREAK WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _DailyGoalProgress extends StatelessWidget {
  final DataProvider dataProvider;
  final TimerProvider timerProvider;
  final bool isDark;

  const _DailyGoalProgress({
    required this.dataProvider,
    required this.timerProvider,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final primary = const Color(0xFF7F5AF0);

    // Anlık olarak timer süresini de ekleyerek gerçek zamanlı hedefi güncelle
    final currentSessionMinutes =
        timerProvider.isRunning && !timerProvider.isBreakMode
            ? timerProvider.secondsElapsed ~/ 60
            : 0;

    final int todayStudiedMins =
        (dataProvider.todayStudiedSeconds ~/ 60) + currentSessionMinutes;
    final int goalMins = dataProvider.dailyGoalMinutes;
    final double progress =
        goalMins > 0 ? (todayStudiedMins / goalMins).clamp(0.0, 1.0) : 0.0;
    final bool goalAchieved = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13111C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.flag_rounded, color: primary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text('Günlük Hedef',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor)),
                ],
              ),
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text('${dataProvider.currentStreak} Gün Seri',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: const Color(0xFFFF9F1C))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$todayStudiedMins / $goalMins dk',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: textColor.withValues(alpha: 0.5))),
              Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: goalAchieved ? const Color(0xFF2CB67D) : primary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: textColor.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                  goalAchieved ? const Color(0xFF2CB67D) : primary),
            ),
          ),
        ],
      ),
    );
  }
}
