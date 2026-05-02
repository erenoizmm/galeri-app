import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF020208),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const NeonGaleriApp());
}

// ─── PALET ─────────────────────────────────────────────────────────────────
class R {
  static const bg      = Color(0xFF020208);
  static const surface = Color(0xFF0A0A18);
  static const glass   = Color(0x14FFFFFF);
  static const glassBorder = Color(0x22FFFFFF);
  static const cyan    = Color(0xFF00F5FF);
  static const mor     = Color(0xFFAA00FF);
  static const pembe   = Color(0xFFFF2D87);
  static const altin   = Color(0xFFFFCC00);
  static const yesil   = Color(0xFF00FFB0);
  static const beyaz   = Colors.white;

  static const cyanGlow  = Color(0x5500F5FF);
  static const morGlow   = Color(0x44AA00FF);
  static const pembeGlow = Color(0x44FF2D87);
}

// ─── MODEL ──────────────────────────────────────────────────────────────────
class MedyaDosya {
  final File dosya;
  final DateTime tarih;
  bool gizli;
  bool favori;
  String album;

  MedyaDosya({
    required this.dosya,
    required this.tarih,
    this.gizli = false,
    this.favori = false,
    this.album = 'Genel',
  });
}

// ─── KAR ANIMASYONU (Ultra) ─────────────────────────────────────────────────
class KarTanesi {
  double x, y, hiz, boyut, opaklık, salinim, salinimFaz, parlaklık;
  bool parlak;

  KarTanesi(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        hiz = 0.2 + rng.nextDouble() * 0.6,
        boyut = 1.0 + rng.nextDouble() * 3.5,
        opaklık = 0.08 + rng.nextDouble() * 0.45,
        salinim = 0.2 + rng.nextDouble() * 0.4,
        salinimFaz = rng.nextDouble() * 2 * pi,
        parlaklık = rng.nextDouble(),
        parlak = rng.nextDouble() > 0.85;
}

class KarPainter extends CustomPainter {
  final List<KarTanesi> taneler;
  final double zaman;

  KarPainter(this.taneler, this.zaman);

  @override
  void paint(Canvas canvas, Size size) {
    for (final t in taneler) {
      final x = (t.x + sin(zaman * t.salinim + t.salinimFaz) * 0.03) * size.width;
      final y = (t.y + zaman * t.hiz * 0.01) % 1.0 * size.height;

      if (t.parlak) {
        // Parlak yıldız kar tanesi
        final glow = Paint()
          ..color = R.cyan.withOpacity(0.08 * t.opaklık)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, t.boyut * 4);
        canvas.drawCircle(Offset(x, y), t.boyut * 3, glow);

        final core = Paint()
          ..color = Colors.white.withOpacity(t.opaklık * 1.2)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.0);
        canvas.drawCircle(Offset(x, y), t.boyut * 0.6, core);
      } else {
        final paint = Paint()
          ..color = Colors.white.withOpacity(t.opaklık)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.8);
        canvas.drawCircle(Offset(x, y), t.boyut / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(KarPainter old) => true;
}

class KarWidget extends StatefulWidget {
  final Widget child;
  const KarWidget({super.key, required this.child});
  @override
  State<KarWidget> createState() => _KarWidgetState();
}

class _KarWidgetState extends State<KarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rng = Random();
  late List<KarTanesi> _taneler;

  @override
  void initState() {
    super.initState();
    _taneler = List.generate(120, (_) => KarTanesi(_rng));
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 90))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: KarPainter(_taneler, _ctrl.value * 90),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─── GLASSMORPHISM KART ─────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Color? borderColor;
  final Color? bgColor;
  final List<BoxShadow>? shadows;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.borderColor,
    this.bgColor,
    this.shadows,
    this.blur = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor ?? R.glass,
            borderRadius: borderRadius,
            border: Border.all(
              color: borderColor ?? R.glassBorder,
              width: 1.0,
            ),
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── NEON METİN ─────────────────────────────────────────────────────────────
class NeonMetin extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color renk;
  final FontWeight weight;
  final double letterSpacing;

  const NeonMetin(this.text, {
    super.key,
    this.fontSize = 16,
    this.renk = R.cyan,
    this.weight = FontWeight.bold,
    this.letterSpacing = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Text(text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: renk,
        shadows: [
          Shadow(color: renk.withOpacity(0.95), blurRadius: 10),
          Shadow(color: renk.withOpacity(0.6),  blurRadius: 24),
          Shadow(color: renk.withOpacity(0.3),  blurRadius: 48),
        ],
      ),
    );
  }
}

// ─── PULSE WIDGET ────────────────────────────────────────────────────────────
class PulseWidget extends StatefulWidget {
  final Widget child;
  final Color color;
  final double minOpacity;
  final double maxOpacity;
  const PulseWidget({super.key, required this.child, required this.color, this.minOpacity = 0.3, this.maxOpacity = 1.0});
  @override State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _anim = Tween(begin: widget.minOpacity, end: widget.maxOpacity)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, child) => Opacity(opacity: _anim.value, child: child),
    child: widget.child,
  );
}

// ─── UYGULAMA ────────────────────────────────────────────────────────────────
class NeonGaleriApp extends StatelessWidget {
  const NeonGaleriApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEON GALERİ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: R.bg,
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
      ),
      home: const GirisEkrani(),
    );
  }
}

// ─── GİRİŞ EKRANI (Ultra Splash) ────────────────────────────────────────────
class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});
  @override State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _haloCtrl;
  late AnimationController _orbCtrl;

  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _slide;
  late Animation<double> _haloPulse;
  late Animation<double> _orbRotate;
  late Animation<double> _textReveal;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _haloCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _orbCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

    _fade       = CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeIn));
    _scale      = Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.0, 0.65, curve: Curves.elasticOut)));
    _slide      = Tween(begin: 60.0, end: 0.0).animate(CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)));
    _textReveal = CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.45, 1.0, curve: Curves.easeOut));
    _haloPulse  = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _haloCtrl, curve: Curves.easeInOut));
    _orbRotate  = Tween(begin: 0.0, end: 2 * pi).animate(_orbCtrl);

    _mainCtrl.forward();

    Future.delayed(const Duration(milliseconds: 3600), () {
      if (mounted) {
        Navigator.pushReplacement(context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1000),
            pageBuilder: (_, __, ___) => const AnaSayfa(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
              child: child,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _haloCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: R.bg,
      body: KarWidget(
        child: Stack(
          children: [
            // Arka plan ambient glow
            Positioned(
              top: size.height * 0.2,
              left: size.width * 0.1,
              child: AnimatedBuilder(
                animation: _haloPulse,
                builder: (_, __) => Container(
                  width: size.width * 0.8,
                  height: size.width * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        R.cyan.withOpacity(0.07 * _haloPulse.value),
                        R.mor.withOpacity(0.04 * _haloPulse.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Center(
              child: AnimatedBuilder(
                animation: _mainCtrl,
                builder: (_, __) => FadeTransition(
                  opacity: _fade,
                  child: Transform.translate(
                    offset: Offset(0, _slide.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo orb
                        ScaleTransition(
                          scale: _scale,
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_haloCtrl, _orbCtrl]),
                            builder: (_, __) => Stack(
                              alignment: Alignment.center,
                              children: [
                                // Dış halo ring
                                Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: R.cyan.withOpacity(0.12 * _haloPulse.value),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                // Orta halo
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        R.cyan.withOpacity(0.18 * _haloPulse.value),
                                        R.mor.withOpacity(0.08 * _haloPulse.value),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                // İç blur glow
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: R.bg,
                                    border: Border.all(
                                      color: R.cyan.withOpacity(0.45 * _haloPulse.value),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: R.cyan.withOpacity(0.4 * _haloPulse.value), blurRadius: 30, spreadRadius: 5),
                                      BoxShadow(color: R.mor.withOpacity(0.2 * _haloPulse.value), blurRadius: 60, spreadRadius: 10),
                                    ],
                                  ),
                                  child: const Icon(Icons.photo_filter_rounded, size: 42, color: R.cyan),
                                ),
                                // Dönen orb nokta
                                Transform.rotate(
                                  angle: _orbRotate.value,
                                  child: Transform.translate(
                                    offset: const Offset(54, 0),
                                    child: Container(
                                      width: 7, height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: R.cyan,
                                        boxShadow: [BoxShadow(color: R.cyanGlow, blurRadius: 12, spreadRadius: 2)],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 44),

                        // Gradient başlık
                        FadeTransition(
                          opacity: _textReveal,
                          child: ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [R.cyan, Color(0xFF7B00FF), R.pembe],
                              stops: [0.0, 0.5, 1.0],
                            ).createShader(b),
                            child: const Text(
                              'NEON GALERİ',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        FadeTransition(
                          opacity: _textReveal,
                          child: Text(
                            'Anılarını sakla  ·  gizle  ·  keşfet',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),

                        const SizedBox(height: 64),

                        // Loading bar
                        FadeTransition(
                          opacity: _textReveal,
                          child: SizedBox(
                            width: 120,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                backgroundColor: R.cyan.withOpacity(0.06),
                                valueColor: AlwaysStoppedAnimation(R.cyan.withOpacity(0.7)),
                                minHeight: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ANA SAYFA ───────────────────────────────────────────────────────────────
class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});
  @override State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> with TickerProviderStateMixin {
  List<MedyaDosya> _tumMedya = [];
  List<MedyaDosya> _gorunenMedya = [];
  final ImagePicker _picker = ImagePicker();
  bool _secimModu = false;
  final Set<int> _secilenler = {};
  int _aktifSekme = 0;
  String _aramaMetni = '';
  bool _aramaAcik = false;
  late AnimationController _fabCtrl;
  late Animation<double> _fabPulse;
  final TextEditingController _aramaCtrl = TextEditingController();
  final List<String> _albumler = ['Genel', 'Tatil', 'Aile', 'İş', 'Diğer'];

  static const _sekmeler = [
    (Icons.photo_library_outlined, Icons.photo_library_rounded, 'Tümü',    R.cyan),
    (Icons.folder_outlined,         Icons.folder_rounded,        'Albüm',   R.altin),
    (Icons.favorite_border_rounded, Icons.favorite_rounded,      'Favori',  R.pembe),
    (Icons.lock_outline_rounded,    Icons.lock_rounded,          'Gizli',   R.mor),
  ];

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _fabPulse = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _fabCtrl, curve: Curves.easeInOut));
    _medyaYukle();
  }

  @override
  void dispose() { _fabCtrl.dispose(); _aramaCtrl.dispose(); super.dispose(); }

  Future<String> get _klasorYolu async {
    final dir = await getApplicationDocumentsDirectory();
    final k = Directory(p.join(dir.path, 'neon_galeri'));
    if (!await k.exists()) await k.create(recursive: true);
    return k.path;
  }

  Future<String> get _gizliYolu async {
    final dir = await getApplicationDocumentsDirectory();
    final k = Directory(p.join(dir.path, 'neon_gizli'));
    if (!await k.exists()) await k.create(recursive: true);
    return k.path;
  }

  Future<void> _medyaYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final normal = await _klasorYolu;
    final gizli  = await _gizliYolu;
    List<MedyaDosya> liste = [];

    for (final ky in [normal, gizli]) {
      final dir = Directory(ky);
      final dosyalar = dir.listSync().whereType<File>().where((f) {
        final ext = p.extension(f.path).toLowerCase();
        return ['.jpg', '.jpeg', '.png', '.webp'].contains(ext);
      }).toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      for (final d in dosyalar) {
        final key = p.basename(d.path);
        liste.add(MedyaDosya(
          dosya:  d,
          tarih:  d.lastModifiedSync(),
          gizli:  ky == gizli,
          favori: prefs.getBool('fav_$key') ?? false,
          album:  prefs.getString('alb_$key') ?? 'Genel',
        ));
      }
    }
    setState(() { _tumMedya = liste; _filtrele(); });
  }

  void _filtrele() {
    List<MedyaDosya> liste;
    switch (_aktifSekme) {
      case 1: liste = _tumMedya.where((m) => !m.gizli).toList(); break;
      case 2: liste = _tumMedya.where((m) => m.favori && !m.gizli).toList(); break;
      case 3: liste = _tumMedya.where((m) => m.gizli).toList(); break;
      default: liste = _tumMedya.where((m) => !m.gizli).toList();
    }
    if (_aramaMetni.isNotEmpty) {
      liste = liste.where((m) =>
        p.basename(m.dosya.path).toLowerCase().contains(_aramaMetni.toLowerCase()) ||
        m.album.toLowerCase().contains(_aramaMetni.toLowerCase())
      ).toList();
    }
    setState(() => _gorunenMedya = liste);
  }

  Future<void> _fotografEkle(ImageSource kaynak, {String album = 'Genel'}) async {
    if (kaynak == ImageSource.gallery) {
      final secilen = await _picker.pickMultiImage(imageQuality: 92);
      if (secilen.isEmpty) return;
      final klasor = await _klasorYolu;
      final prefs  = await SharedPreferences.getInstance();
      for (int i = 0; i < secilen.length; i++) {
        final ad = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        await File(secilen[i].path).copy(p.join(klasor, ad));
        await prefs.setString('alb_$ad', album);
      }
    } else {
      final secilen = await _picker.pickImage(source: kaynak, imageQuality: 92);
      if (secilen == null) return;
      final klasor = await _klasorYolu;
      final prefs  = await SharedPreferences.getInstance();
      final ad = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(secilen.path).copy(p.join(klasor, ad));
      await prefs.setString('alb_$ad', album);
    }
    await _medyaYukle();
  }

  Future<void> _gizle(List<int> indeksler) async {
    final gizliKlasor = await _gizliYolu;
    for (final i in indeksler) {
      final m = _gorunenMedya[i];
      final hedef = File(p.join(gizliKlasor, p.basename(m.dosya.path)));
      await m.dosya.copy(hedef.path);
      await m.dosya.delete();
    }
    setState(() { _secimModu = false; _secilenler.clear(); });
    await _medyaYukle();
  }

  Future<void> _gizliCikar(List<int> indeksler) async {
    final normalKlasor = await _klasorYolu;
    for (final i in indeksler) {
      final m = _gorunenMedya[i];
      final hedef = File(p.join(normalKlasor, p.basename(m.dosya.path)));
      await m.dosya.copy(hedef.path);
      await m.dosya.delete();
    }
    setState(() { _secimModu = false; _secilenler.clear(); });
    await _medyaYukle();
  }

  Future<void> _sil(List<int> indeksler) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          bgColor: const Color(0xCC0A0A18),
          borderColor: R.pembe.withOpacity(0.3),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_forever_rounded, color: R.pembe, size: 40,
                shadows: [Shadow(color: R.pembeGlow, blurRadius: 20)]),
              const SizedBox(height: 16),
              const NeonMetin('Sil', renk: R.pembe, fontSize: 20, letterSpacing: 3),
              const SizedBox(height: 12),
              Text('${indeksler.length} fotoğraf kalıcı olarak silinsin mi?',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _dialogBtn('İptal', Colors.white24, () => Navigator.pop(context, false))),
                const SizedBox(width: 12),
                Expanded(child: _dialogBtn('Sil', R.pembe.withOpacity(0.2), () => Navigator.pop(context, true), textColor: R.pembe)),
              ]),
            ],
          ),
        ),
      ),
    );
    if (onay != true) return;
    for (final i in indeksler) await _gorunenMedya[i].dosya.delete();
    setState(() { _secimModu = false; _secilenler.clear(); });
    await _medyaYukle();
  }

  Widget _dialogBtn(String label, Color bg, VoidCallback onTap, {Color textColor = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: textColor.withOpacity(0.3))),
        child: Center(child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, letterSpacing: 1))),
      ),
    );
  }

  Future<void> _favoriToggle(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final m = _gorunenMedya[index];
    m.favori = !m.favori;
    await prefs.setBool('fav_${p.basename(m.dosya.path)}', m.favori);
    setState(() {});
  }

  Future<void> _albumDegistir(MedyaDosya m, String yeniAlbum) async {
    final prefs = await SharedPreferences.getInstance();
    m.album = yeniAlbum;
    await prefs.setString('alb_${p.basename(m.dosya.path)}', yeniAlbum);
    setState(() {});
  }

  void _kaynakMenusu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EkleMenusu(
        albumler: _albumler,
        onSec: (kaynak, album) { Navigator.pop(context); _fotografEkle(kaynak, album: album); },
      ),
    );
  }

  PageRouteBuilder _sayfaGecis(Widget sayfa) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => sayfa,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.03), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: R.bg,
      extendBody: true,
      body: KarWidget(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              if (_aramaAcik) _buildAramaBar(),
              _buildTabBar(),
              Expanded(
                child: _aktifSekme == 1
                    ? _buildAlbumView()
                    : _buildGrid(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _secimModu ? null : _buildFAB(),
      bottomNavigationBar: _secimModu ? _buildSecimBar() : null,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 10),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [R.cyan, R.mor],
            ).createShader(b),
            child: const Text('NEON GALERİ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 6, color: Colors.white),
            ),
          ),
          const Spacer(),
          if (_gorunenMedya.isNotEmpty)
            Text('${_gorunenMedya.length} öğe',
              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11, letterSpacing: 1),
            ),
          const SizedBox(width: 12),
          _ikonButon(
            ikon: _aramaAcik ? Icons.close_rounded : Icons.search_rounded,
            renk: R.cyan, aktif: _aramaAcik,
            onTap: () => setState(() {
              _aramaAcik = !_aramaAcik;
              if (!_aramaAcik) { _aramaMetni = ''; _aramaCtrl.clear(); _filtrele(); }
            }),
          ),
          const SizedBox(width: 6),
          _ikonButon(
            ikon: _secimModu ? Icons.deselect_rounded : Icons.select_all_rounded,
            renk: Colors.white60, aktif: _secimModu,
            onTap: () => setState(() { _secimModu = !_secimModu; _secilenler.clear(); }),
          ),
        ],
      ),
    );
  }

  Widget _ikonButon({required IconData ikon, required Color renk, required bool aktif, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: aktif ? renk.withOpacity(0.18) : Colors.transparent,
          border: Border.all(color: aktif ? renk.withOpacity(0.55) : Colors.white.withOpacity(0.1), width: 1),
          boxShadow: aktif ? [BoxShadow(color: renk.withOpacity(0.3), blurRadius: 16, spreadRadius: 2)] : [],
        ),
        child: Icon(ikon, color: aktif ? renk : Colors.white.withOpacity(0.5), size: 20),
      ),
    );
  }

  Widget _buildAramaBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderColor: R.cyan.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
        child: TextField(
          controller: _aramaCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Fotoğraf veya albüm ara...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            prefixIcon: Icon(Icons.search_rounded, color: R.cyan.withOpacity(0.6), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (v) { setState(() => _aramaMetni = v); _filtrele(); },
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: GlassCard(
        padding: const EdgeInsets.all(5),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: List.generate(_sekmeler.length, (i) {
            final aktif = _aktifSekme == i;
            final s = _sekmeler[i];
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _aktifSekme = i); _filtrele(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: aktif ? s.$4.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: aktif ? s.$4.withOpacity(0.5) : Colors.transparent,
                      width: 1,
                    ),
                    boxShadow: aktif ? [BoxShadow(color: s.$4.withOpacity(0.2), blurRadius: 16)] : [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        aktif ? s.$2 : s.$1,
                        color: aktif ? s.$4 : Colors.white.withOpacity(0.25),
                        size: 18,
                        shadows: aktif ? [Shadow(color: s.$4.withOpacity(0.8), blurRadius: 12)] : [],
                      ),
                      if (aktif) ...[
                        const SizedBox(height: 3),
                        Text(s.$3, style: TextStyle(color: s.$4, fontSize: 9, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    if (_gorunenMedya.isEmpty) return _buildBosEkran();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _gorunenMedya.length,
      itemBuilder: (_, i) => _FotoKart(
        medya: _gorunenMedya[i],
        index: i,
        secili: _secilenler.contains(i),
        secimModu: _secimModu,
        onTap: () {
          if (_secimModu) {
            setState(() {
              if (_secilenler.contains(i)) _secilenler.remove(i);
              else _secilenler.add(i);
            });
          } else {
            Navigator.push(context, _sayfaGecis(DetayEkrani(
              medya: _gorunenMedya, baslangic: i,
              onFavori: _favoriToggle,
              onAlbumDegistir: _albumDegistir,
              albumler: _albumler,
            )));
          }
        },
        onLongPress: () => setState(() { _secimModu = true; _secilenler.add(i); }),
      ),
    );
  }

  Widget _buildAlbumView() {
    final Map<String, List<MedyaDosya>> gruplar = {};
    for (final m in _gorunenMedya) (gruplar[m.album] ??= []).add(m);
    if (gruplar.isEmpty) return _buildBosEkran();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
      itemCount: gruplar.length,
      itemBuilder: (_, i) {
        final album  = gruplar.keys.elementAt(i);
        final liste  = gruplar[album]!;
        return _AlbumKart(
          album: album,
          medyalar: liste,
          onTap: () => Navigator.push(context, _sayfaGecis(DetayEkrani(
            medya: liste, baslangic: 0,
            onFavori: (j) async {
              final prefs = await SharedPreferences.getInstance();
              final m = liste[j];
              m.favori = !m.favori;
              await prefs.setBool('fav_${p.basename(m.dosya.path)}', m.favori);
              setState(() {});
            },
            onAlbumDegistir: _albumDegistir,
            albumler: _albumler,
          ))),
        );
      },
    );
  }

  Widget _buildBosEkran() {
    const mesajlar = ['Henüz fotoğraf yok', 'Albüm boş', 'Favori yok', 'Gizli fotoğraf yok'];
    const ikonlar  = [Icons.photo_outlined, Icons.folder_outlined, Icons.favorite_border_rounded, Icons.lock_outline_rounded];
    final renk = _sekmeler[_aktifSekme].$4;

    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(ikonlar[_aktifSekme], size: 60, color: renk.withOpacity(0.1),
          shadows: [Shadow(color: renk.withOpacity(0.2), blurRadius: 30)]),
        const SizedBox(height: 16),
        Text(mesajlar[_aktifSekme],
          style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 14, letterSpacing: 3)),
      ]),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _fabPulse,
      builder: (_, __) => GestureDetector(
        onTap: _kaynakMenusu,
        child: Stack(alignment: Alignment.center, children: [
          // Outer pulse ring
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: R.cyan.withOpacity(0.15 * _fabPulse.value), width: 1),
            ),
          ),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [R.cyan, Color(0xFF6600FF)],
              ),
              boxShadow: [
                BoxShadow(color: R.cyan.withOpacity(0.5 * _fabPulse.value), blurRadius: 24, spreadRadius: 3),
                BoxShadow(color: R.mor.withOpacity(0.3 * _fabPulse.value),  blurRadius: 40, spreadRadius: 6),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
          ),
        ]),
      ),
    );
  }

  Widget _buildSecimBar() {
    final gizliMod = _aktifSekme == 3;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: const Color(0xCC080810),
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 4,
              left: 8, right: 8, top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!gizliMod)
                _SecimBtn(ikon: Icons.lock_rounded, etiket: 'Gizle', renk: R.mor,
                    onTap: _secilenler.isEmpty ? null : () => _gizle(_secilenler.toList())),
              if (gizliMod)
                _SecimBtn(ikon: Icons.lock_open_rounded, etiket: 'Çıkar', renk: R.yesil,
                    onTap: _secilenler.isEmpty ? null : () => _gizliCikar(_secilenler.toList())),
              _SecimBtn(ikon: Icons.delete_rounded, etiket: 'Sil', renk: R.pembe,
                  onTap: _secilenler.isEmpty ? null : () => _sil(_secilenler.toList())),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Text('${_secilenler.length} seçili',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 0.5)),
              ),
              _SecimBtn(ikon: Icons.close_rounded, etiket: 'İptal', renk: Colors.white54,
                  onTap: () => setState(() { _secimModu = false; _secilenler.clear(); })),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── EKLE MENÜSÜ (Glassmorphism) ────────────────────────────────────────────
class _EkleMenusu extends StatefulWidget {
  final List<String> albumler;
  final Function(ImageSource, String) onSec;
  const _EkleMenusu({required this.albumler, required this.onSec});
  @override State<_EkleMenusu> createState() => _EkleMenusuState();
}

class _EkleMenusuState extends State<_EkleMenusu> {
  String _seciliAlbum = 'Genel';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 20, right: 20, top: 14),
          decoration: BoxDecoration(
            color: const Color(0xE0060612),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const SizedBox(height: 22),
              const NeonMetin('Fotoğraf Ekle', fontSize: 18, letterSpacing: 3),
              const SizedBox(height: 18),
              Text('Albüm', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, letterSpacing: 2)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.albumler.map((a) {
                    final aktif = _seciliAlbum == a;
                    return GestureDetector(
                      onTap: () => setState(() => _seciliAlbum = a),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: aktif ? R.altin.withOpacity(0.14) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: aktif ? R.altin.withOpacity(0.55) : Colors.white.withOpacity(0.08),
                          ),
                          boxShadow: aktif ? [BoxShadow(color: R.altin.withOpacity(0.2), blurRadius: 14)] : [],
                        ),
                        child: Text(a, style: TextStyle(
                          color: aktif ? R.altin : Colors.white.withOpacity(0.4),
                          fontSize: 13, fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
                        )),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _GlassButton(
                  ikon: Icons.photo_library_rounded, label: 'Galeri', renk: R.cyan,
                  onTap: () => widget.onSec(ImageSource.gallery, _seciliAlbum),
                )),
                const SizedBox(width: 12),
                Expanded(child: _GlassButton(
                  ikon: Icons.camera_alt_rounded, label: 'Kamera', renk: R.mor,
                  onTap: () => widget.onSec(ImageSource.camera, _seciliAlbum),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatefulWidget {
  final IconData ikon;
  final String label;
  final Color renk;
  final VoidCallback onTap;
  const _GlassButton({required this.ikon, required this.label, required this.renk, required this.onTap});
  @override State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: widget.renk.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.renk.withOpacity(0.35), width: 1),
            boxShadow: [BoxShadow(color: widget.renk.withOpacity(0.12), blurRadius: 20, spreadRadius: 1)],
          ),
          child: Column(children: [
            Icon(widget.ikon, color: widget.renk, size: 30,
              shadows: [Shadow(color: widget.renk.withOpacity(0.8), blurRadius: 18)]),
            const SizedBox(height: 8),
            Text(widget.label, style: TextStyle(
              color: widget.renk, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5,
            )),
          ]),
        ),
      ),
    );
  }
}

// ─── SEÇİM BUTONU ───────────────────────────────────────────────────────────
class _SecimBtn extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final Color renk;
  final VoidCallback? onTap;
  const _SecimBtn({required this.ikon, required this.etiket, required this.renk, this.onTap});

  @override
  Widget build(BuildContext context) {
    final aktif = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: aktif ? 1.0 : 0.3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(ikon, color: renk, size: 26,
              shadows: aktif ? [Shadow(color: renk.withOpacity(0.7), blurRadius: 14)] : []),
            const SizedBox(height: 4),
            Text(etiket, style: TextStyle(color: renk, fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

// ─── ALBÜM KARTI (Glassmorphism) ────────────────────────────────────────────
class _AlbumKart extends StatelessWidget {
  final String album;
  final List<MedyaDosya> medyalar;
  final VoidCallback onTap;
  const _AlbumKart({required this.album, required this.medyalar, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: R.altin.withOpacity(0.18)),
          boxShadow: [BoxShadow(color: R.altin.withOpacity(0.06), blurRadius: 24)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 130,
              child: Row(
                children: List.generate(min(medyalar.length, 3), (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < min(medyalar.length, 3) - 1 ? 2 : 0),
                    child: Image.file(medyalar[i].dosya, fit: BoxFit.cover),
                  ),
                )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Icon(Icons.folder_rounded, color: R.altin.withOpacity(0.85), size: 16,
                  shadows: [Shadow(color: R.altin.withOpacity(0.6), blurRadius: 12)]),
                const SizedBox(width: 8),
                NeonMetin(album, renk: R.altin, fontSize: 14),
                const Spacer(),
                Text('${medyalar.length}',
                  style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12, letterSpacing: 0.5)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 16),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── FOTO KART (Ultra) ───────────────────────────────────────────────────────
class _FotoKart extends StatefulWidget {
  final MedyaDosya medya;
  final int index;
  final bool secili, secimModu;
  final VoidCallback onTap, onLongPress;

  const _FotoKart({
    required this.medya, required this.index,
    required this.secili, required this.secimModu,
    required this.onTap, required this.onLongPress,
  });

  @override State<_FotoKart> createState() => _FotoKartState();
}

class _FotoKartState extends State<_FotoKart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = Tween(begin: 0.72, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: (widget.index % 12) * 35), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(fit: StackFit.expand, children: [
            Image.file(widget.medya.dosya, fit: BoxFit.cover, cacheWidth: 300),

            // Seçim overlay
            if (widget.secimModu)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: widget.secili ? R.cyan.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                  border: widget.secili
                      ? Border.all(color: R.cyan, width: 2.5)
                      : null,
                ),
              ),

            // Seçim işareti
            if (widget.secimModu)
              Positioned(
                top: 7, right: 7,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.secili ? R.cyan : Colors.black.withOpacity(0.5),
                    border: Border.all(
                      color: widget.secili ? R.cyan : Colors.white.withOpacity(0.6), width: 2),
                    boxShadow: widget.secili
                        ? [BoxShadow(color: R.cyanGlow, blurRadius: 12)]
                        : [],
                  ),
                  child: widget.secili
                      ? const Icon(Icons.check_rounded, size: 12, color: Colors.black)
                      : null,
                ),
              ),

            // Favori ikonu
            if (widget.medya.favori && !widget.secimModu)
              Positioned(
                top: 6, right: 6,
                child: Icon(Icons.favorite_rounded, size: 14, color: R.pembe,
                  shadows: [Shadow(color: R.pembeGlow, blurRadius: 12)]),
              ),

            // Gizli badge
            if (widget.medya.gizli && !widget.secimModu)
              Positioned(
                bottom: 5, left: 5,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: R.mor.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(Icons.lock_rounded, size: 9, color: Colors.white),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ─── DETAY EKRANI ────────────────────────────────────────────────────────────
class DetayEkrani extends StatefulWidget {
  final List<MedyaDosya> medya;
  final int baslangic;
  final Function(int) onFavori;
  final Function(MedyaDosya, String) onAlbumDegistir;
  final List<String> albumler;

  const DetayEkrani({
    super.key,
    required this.medya, required this.baslangic,
    required this.onFavori, required this.onAlbumDegistir, required this.albumler,
  });

  @override State<DetayEkrani> createState() => _DetayEkraniState();
}

class _DetayEkraniState extends State<DetayEkrani> with SingleTickerProviderStateMixin {
  late PageController _ctrl;
  late int _mevcut;
  bool _uiGoster = true;
  late AnimationController _uiAnim;

  @override
  void initState() {
    super.initState();
    _mevcut = widget.baslangic;
    _ctrl = PageController(initialPage: _mevcut);
    _uiAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 280), value: 1);
  }

  @override void dispose() { _ctrl.dispose(); _uiAnim.dispose(); super.dispose(); }

  void _toggleUI() {
    setState(() => _uiGoster = !_uiGoster);
    if (_uiGoster) _uiAnim.forward(); else _uiAnim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.medya[_mevcut];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleUI,
        child: Stack(children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.medya.length,
            onPageChanged: (i) => setState(() => _mevcut = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.8, maxScale: 6,
              child: Center(child: Image.file(widget.medya[i].dosya)),
            ),
          ),

          // Üst bar (glassmorphism)
          FadeTransition(
            opacity: _uiAnim,
            child: Align(
              alignment: Alignment.topCenter,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 6,
                        bottom: 10, left: 4, right: 4),
                    child: Row(children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text('${_mevcut + 1}  /  ${widget.medya.length}',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, letterSpacing: 2)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          m.favori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: m.favori ? R.pembe : Colors.white.withOpacity(0.7),
                          shadows: m.favori ? [Shadow(color: R.pembeGlow, blurRadius: 18)] : [],
                        ),
                        onPressed: () { widget.onFavori(_mevcut); setState(() {}); },
                      ),
                      IconButton(
                        icon: Icon(Icons.folder_open_rounded, color: Colors.white.withOpacity(0.6), size: 22),
                        onPressed: () => _albumSecDialog(m),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // Sayfa indikatörü
          if (widget.medya.length > 1)
            FadeTransition(
              opacity: _uiAnim,
              child: Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(min(widget.medya.length, 15), (i) =>
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: _mevcut == i ? 20 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _mevcut == i ? R.cyan : Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: _mevcut == i
                            ? [BoxShadow(color: R.cyanGlow, blurRadius: 12)]
                            : [],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  void _albumSecDialog(MedyaDosya m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 20, right: 20, top: 14),
            decoration: BoxDecoration(
              color: const Color(0xE6080812),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 36, height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
                const SizedBox(height: 18),
                const NeonMetin('Albüm Seç', renk: R.altin, fontSize: 17, letterSpacing: 3),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: widget.albumler.map((a) {
                    final aktif = m.album == a;
                    return GestureDetector(
                      onTap: () { widget.onAlbumDegistir(m, a); Navigator.pop(context); setState(() {}); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: aktif ? R.altin.withOpacity(0.14) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: aktif ? R.altin.withOpacity(0.55) : Colors.white.withOpacity(0.08)),
                          boxShadow: aktif ? [BoxShadow(color: R.altin.withOpacity(0.2), blurRadius: 14)] : [],
                        ),
                        child: Text(a, style: TextStyle(
                          color: aktif ? R.altin : Colors.white.withOpacity(0.4),
                          fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
                        )),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
