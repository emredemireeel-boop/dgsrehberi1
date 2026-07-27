import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Ana logo animasyonu
  late AnimationController _logoCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoGlow;

  // Başlık kayma
  late AnimationController _titleCtrl;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;

  // Alt yazı
  late AnimationController _subtitleCtrl;
  late Animation<double> _subtitleOpacity;

  // Parçacık sistemi
  late AnimationController _particleCtrl;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  // Loading bar
  late AnimationController _loadCtrl;
  late Animation<double> _loadProgress;

  // Shine/shimmer efekti logo üzerinde
  late AnimationController _shineCtrl;
  late Animation<double> _shineAnim;

  // Geri sayım badge
  late AnimationController _badgeCtrl;
  late Animation<double> _badgeScale;

  // Arka plan rotation
  late AnimationController _bgCtrl;

  final List<String> _loadingMessages = [
    'Sorular hazırlanıyor...',
    'Konular yükleniyor...',
    'İstatistikler hazır...',
    'DGS\'ye hazır mısın? 🚀',
  ];
  int _msgIndex = 0;
  late Timer _msgTimer;

  @override
  void initState() {
    super.initState();

    // Sistem UI ayarı
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Parçacıklar
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(rng: _rng));
    }

    // BG dönen daireler
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();

    // Logo
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _logoGlow = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    // Shine
    _shineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _shineAnim = Tween<double>(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _shineCtrl, curve: Curves.easeInOut));

    // Başlık
    _titleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOutCubic));
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOut));

    // Alt yazı
    _subtitleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _subtitleCtrl, curve: Curves.easeOut));

    // Particle ctrl
    _particleCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();

    // Loading bar
    _loadCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800));
    _loadProgress = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _loadCtrl, curve: Curves.easeInOut));

    // Badge bounce
    _badgeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _badgeScale = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeInOut));

    // Mesaj değiştirici
    _msgTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (mounted) {
        setState(() => _msgIndex = (_msgIndex + 1) % _loadingMessages.length);
      }
    });

    // Animasyon zinciri
    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();
    _loadCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _titleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 350));
    _subtitleCtrl.forward();
    // Ana uygulamaya geç
    await Future.delayed(const Duration(milliseconds: 2800));
    if (mounted) {
      _msgTimer.cancel();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => HomeScreen(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _particleCtrl.dispose();
    _loadCtrl.dispose();
    _badgeCtrl.dispose();
    _shineCtrl.dispose();
    _bgCtrl.dispose();
    _msgTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0914),
      body: Stack(
        children: [
          // ── ARKA PLAN GRADİENT ─────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.4,
                colors: [
                  Color(0xFF1B104E),
                  Color(0xFF0A0914),
                ],
              ),
            ),
          ),

          // ── DÖNEN DEKORATİF DAİRELER ────────────────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) {
              return CustomPaint(
                size: size,
                painter: _BgCirclesPainter(progress: _bgCtrl.value),
              );
            },
          ),

          // ── UÇUŞAn PARÇACIKLAR ──────────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) {
              return CustomPaint(
                size: size,
                painter: _ParticlesPainter(
                  particles: _particles,
                  progress: _particleCtrl.value,
                ),
              );
            },
          ),

          // ── YILDIZ NOKTALARI ─────────────────────────────────────────────
          ...List.generate(25, (i) {
            final rx = _rng.nextDouble();
            final ry = _rng.nextDouble();
            final rs = _rng.nextDouble() * 2 + 1;
            return Positioned(
              left: rx * size.width,
              top: ry * size.height * 0.7,
              child: AnimatedBuilder(
                animation: _badgeCtrl,
                builder: (_, __) => Opacity(
                  opacity: (0.3 + 0.7 * sin(_badgeCtrl.value * pi + i))
                      .clamp(0.1, 1.0),
                  child: Container(
                    width: rs,
                    height: rs,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ),
            );
          }),

          // ── ANA İÇERİK ────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // LOGO + GLOW
                        AnimatedBuilder(
                          animation: Listenable.merge([_logoCtrl, _shineCtrl]),
                          builder: (_, __) {
                            return Transform.scale(
                              scale: _logoScale.value,
                              child: Opacity(
                                opacity: _logoOpacity.value,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer glow ring
                                    ...List.generate(
                                        3,
                                        (i) => Container(
                                              width: 160.0 + i * 20,
                                              height: 160.0 + i * 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(0xFF7F5AF0)
                                                      .withValues(
                                                          alpha: _logoGlow
                                                                  .value *
                                                              (0.35 - i * 0.1)),
                                                  width: 1.5,
                                                ),
                                              ),
                                            )),
                                    // Glowing bg circle
                                    Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            const Color(
                                              0xFF7F5AF0,
                                            ).withValues(
                                              alpha: 0.25 * _logoGlow.value,
                                            ),
                                            Colors.transparent,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF7F5AF0)
                                                .withValues(
                                                    alpha:
                                                        0.5 * _logoGlow.value),
                                            blurRadius: 60,
                                            spreadRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Logo image — boyutu ekrana göre kırpılmaz
                                    SizedBox(
                                      width: 130,
                                      height: 130,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(28),
                                        child: Image.asset(
                                          'assets/logosefaf.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    // Shine sweep
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(28),
                                        child: IgnorePointer(
                                          child: ShaderMask(
                                            blendMode: BlendMode.srcATop,
                                            shaderCallback: (bounds) =>
                                                LinearGradient(
                                              begin: Alignment(
                                                  _shineAnim.value - 1, -1),
                                              end: Alignment(
                                                  _shineAnim.value, 1),
                                              colors: [
                                                Colors.transparent,
                                                Colors.white
                                                    .withValues(alpha: 0.15),
                                                Colors.transparent,
                                              ],
                                            ).createShader(bounds),
                                            child: Container(
                                                color: Colors.white
                                                    .withValues(alpha: 0.01)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // BAŞLIK
                        SlideTransition(
                          position: _titleSlide,
                          child: FadeTransition(
                            opacity: _titleOpacity,
                            child: Column(children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFF7F5AF0),
                                    Color(0xFF00B4D8),
                                    Color(0xFF2CB67D)
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                ).createShader(bounds),
                                child: Text(
                                  'DGS Rehberi',
                                  style: GoogleFonts.outfit(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hedefine bir adım daha yakın',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ]),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // HEDEF BADGE
                        FadeTransition(
                          opacity: _subtitleOpacity,
                          child: AnimatedBuilder(
                            animation: _badgeCtrl,
                            builder: (_, __) {
                              return Transform.scale(
                                scale: _badgeScale.value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF7F5AF0)
                                            .withValues(alpha: 0.25),
                                        const Color(0xFF00B4D8)
                                            .withValues(alpha: 0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFF7F5AF0)
                                          .withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7F5AF0)
                                            .withValues(alpha: 0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🎯',
                                            style: TextStyle(fontSize: 20)),
                                        const SizedBox(width: 10),
                                        Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('HEDEFİNİ BELİRLE',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.6),
                                                      fontWeight:
                                                          FontWeight.w500)),
                                              Text('Planını oluştur',
                                                  style: GoogleFonts.outfit(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      letterSpacing: -0.5)),
                                            ]),
                                        const SizedBox(width: 10),
                                        const Text('📅',
                                            style: TextStyle(fontSize: 20)),
                                      ]),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // FEATURE CHIPS
                        FadeTransition(
                          opacity: _subtitleOpacity,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _featureChip(
                                  '⏱ Zamanlayıcı', const Color(0xFF7F5AF0)),
                              _featureChip(
                                  '📊 İstatistik', const Color(0xFF00B4D8)),
                              _featureChip(
                                  '📝 Deneme', const Color(0xFFFF6B6B)),
                              _featureChip('🔁 Rutin', const Color(0xFF2CB67D)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── LOADING KISMI ──────────────────────────────────────────
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Mesaj
                      FadeTransition(
                        opacity: _subtitleOpacity,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _loadingMessages[_msgIndex],
                            key: ValueKey(_msgIndex),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.45),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Loading bar
                      AnimatedBuilder(
                        animation: _loadProgress,
                        builder: (_, __) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Column(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(children: [
                                  Container(
                                      height: 4,
                                      color:
                                          Colors.white.withValues(alpha: 0.08)),
                                  FractionallySizedBox(
                                    widthFactor: _loadProgress.value,
                                    child: Container(
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF7F5AF0),
                                            Color(0xFF00B4D8)
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Color(0xFF7F5AF0),
                                              blurRadius: 8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${(_loadProgress.value * 100).toInt()}%',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 11,
                                  color: const Color(0xFF7F5AF0)
                                      .withValues(alpha: 0.8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      // Versiyon
                      Text(
                        'v1.1.0  •  © 2026 DGS Rehberi',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── ARKA PLAN DAİRELERİ ─────────────────────────────────────────────────────
class _BgCirclesPainter extends CustomPainter {
  final double progress;
  _BgCirclesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.35;

    final circles = [
      _CircleConfig(radius: 280, opacity: 0.04, speed: 1.0),
      _CircleConfig(radius: 200, opacity: 0.06, speed: -0.7),
      _CircleConfig(radius: 120, opacity: 0.08, speed: 1.3),
    ];

    for (final c in circles) {
      final angle = progress * 2 * pi * c.speed;
      final paint = Paint()
        ..color = const Color(0xFF7F5AF0).withValues(alpha: c.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: c.radius * 2, height: c.radius * 1.4),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BgCirclesPainter old) =>
      old.progress != progress;
}

class _CircleConfig {
  final double radius;
  final double opacity;
  final double speed;
  _CircleConfig(
      {required this.radius, required this.opacity, required this.speed});
}

// ─── PARÇACIK SİSTEMİ ────────────────────────────────────────────────────────
class _Particle {
  late double x, y, vx, vy, size, opacity;
  late Color color;

  _Particle({required Random rng}) {
    _reset(rng);
    y = rng.nextDouble(); // başlangıç pozisyonu dağıtık
  }

  void _reset(Random rng) {
    x = rng.nextDouble();
    y = 1.0 + rng.nextDouble() * 0.2;
    vx = (rng.nextDouble() - 0.5) * 0.005;
    vy = -(rng.nextDouble() * 0.003 + 0.001);
    size = rng.nextDouble() * 3 + 1;
    opacity = rng.nextDouble() * 0.6 + 0.1;
    final colors = [
      const Color(0xFF7F5AF0),
      const Color(0xFF00B4D8),
      const Color(0xFF2CB67D),
      Colors.white
    ];
    color = colors[rng.nextInt(colors.length)];
  }
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Random _rng = Random();

  _ParticlesPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      p.x += p.vx;
      p.y += p.vy;
      if (p.y < -0.05) p._reset(_rng);

      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) => true;
}
