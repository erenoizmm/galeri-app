import 'dart:io';
import 'dart:math';
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
    systemNavigationBarColor: Color(0xFF050508),
  ));
  runApp(const NeonGaleriApp());
}

// ─── RENKLER ───────────────────────────────────────────────────────────────
class R {
  static const bg = Color(0xFF050508);
  static const kart = Color(0xFF0D0D18);
  static const cyan = Color(0xFF00FFEA);
  static const mor = Color(0xFFB400FF);
  static const pembe = Color(0xFFFF006E);
  static const altin = Color(0xFFFFD700);
  static const yesil = Color(0xFF00FF88);
}

// ─── MODEL ─────────────────────────────────────────────────────────────────
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

// ─── KAR YAĞIŞI ────────────────────────────────────────────────────────────
class KarTanesi {
  double x, y, hiz, boyut, seffaflik, salinim, salinimFaz;
  KarTanesi(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        hiz = 0.3 + rng.nextDouble() * 0.7,
        boyut = 1.5 + rng.nextDouble() * 4.0,
        seffaflik = 0.15 + rng.nextDouble() * 0.55,
        salinim = 0.3 + rng.nextDouble() * 0.5,
        salinimFaz = rng.nextDouble() * 2 * pi;
}

class KarPainter extends CustomPainter {
  final List<KarTanesi> taneler;
  final double zaman;
  KarPainter(this.taneler, this.zaman);

  @override
  void paint(Canvas canvas, Size size) {
    for (final t in taneler) {
      final x = (t.x + sin(zaman * t.salinim + t.salinimFaz) * 0.025) * size.width;
      final y = (t.y + zaman * t.hiz * 0.012) % 1.0 * size.height;
      final paint = Paint()
        ..color = Colors.white.withOpacity(t.seffaflik)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset(x, y), t.boyut / 2, paint);
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
    _taneler = List.generate(90, (_) => KarTanesi(_rng));
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: KarPainter(_taneler, _ctrl.value * 60),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── NEON METİN ────────────────────────────────────────────────────────────
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
            Shadow(color: renk.withOpacity(0.9), blurRadius: 12),
            Shadow(color: renk.withOpacity(0.5), blurRadius: 28),
          ],
        ));
  }
}

// ─── NEON BUTON ────────────────────────────────────────────────────────────
class NeonButon extends StatefulWidget {
  final IconData ikon;
  final String etiket;
  final Color renk;
  final VoidCallback onTap;
  const NeonButon({super.key, required this.ikon, required this.etiket, required this.renk, required this.onTap});
  @override
  State<NeonButon> createState() => _NeonButonState();
}

class _NeonButonState extends State<NeonButon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: widget.renk.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.renk.withOpacity(0.4), width: 1.5),
            boxShadow: [BoxShadow(color: widget.renk.withOpacity(0.15), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Column(
            children: [
              Icon(widget.ikon, color: widget.renk, size: 32,
                  shadows: [Shadow(color: widget.renk.withOpacity(0.8), blurRadius: 16)]),
              const SizedBox(height: 8),
              Text(widget.etiket, style: TextStyle(color: widget.renk, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── UYGULAMA ──────────────────────────────────────────────────────────────
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
      ),
      home: const GirisEkrani(),
    );
  }
}

// ─── GİRİŞ EKRANI ──────────────────────────────────────────────────────────
class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});
  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale, _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeIn));
    _scale = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.elasticOut)));
    _slide = Tween(begin: 40.0, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.pushReplacement(context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 900),
            pageBuilder: (_, __, ___) => const AnaSayfa(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: R.bg,
      body: KarWidget(
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => FadeTransition(
              opacity: _fade,
              child: Transform.translate(
                offset: Offset(0, _slide.value),
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(colors: [Color(0xFF003333), R.bg]),
                          boxShadow: [
                            BoxShadow(color: R.cyan.withOpacity(0.6), blurRadius: 50, spreadRadius: 10),
                            BoxShadow(color: R.mor.withOpacity(0.3), blurRadius: 80, spreadRadius: 20),
                          ],
                          border: Border.all(color: R.cyan.withOpacity(0.5), width: 1.5),
                        ),
                        child: const Icon(Icons.photo_filter_rounded, size: 52, color: R.cyan),
                      ),
                      const SizedBox(height: 36),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [R.cyan, R.mor, R.pembe],
                          stops: [0, 0.5, 1],
                        ).createShader(b),
                        child: const Text('NEON GALERİ',
                          style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 10, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Anılarını sakla · gizle · keşfet',
                        style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13, letterSpacing: 3),
                      ),
                      const SizedBox(height: 52),
                      SizedBox(
                        width: 130,
                        child: LinearProgressIndicator(
                          backgroundColor: R.cyan.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation(R.cyan.withOpacity(0.8)),
                          minHeight: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ANA SAYFA ─────────────────────────────────────────────────────────────
class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});
  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
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
  late AnimationController _neonCtrl;
  late Animation<double> _neonAnim;
  final TextEditingController _aramaCtrl = TextEditingController();
  final List<String> _albumler = ['Genel', 'Tatil', 'Aile', 'İş', 'Diğer'];

  @override
  void initState() {
    super.initState();
    _neonCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _neonAnim = Tween<double>(begin: 0.3, end: 1.0).animate(_neonCtrl);
    _medyaYukle();
  }

  @override
  void dispose() {
    _neonCtrl.dispose();
    _aramaCtrl.dispose();
    super.dispose();
  }

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
    final gizli = await _gizliYolu;
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
          dosya: d,
          tarih: d.lastModifiedSync(),
          gizli: ky == gizli,
          favori: prefs.getBool('fav_$key') ?? false,
          album: prefs.getString('alb_$key') ?? 'Genel',
        ));
      }
    }
    setState(() {
      _tumMedya = liste;
      _filtrele();
    });
  }

  void _filtrele() {
    List<MedyaDosya> liste;
    switch (_aktifSekme) {
      case 1:
        liste = _tumMedya.where((m) => !m.gizli).toList();
        break;
      case 2:
        liste = _tumMedya.where((m) => m.favori && !m.gizli).toList();
        break;
      case 3:
        liste = _tumMedya.where((m) => m.gizli).toList();
        break;
      default:
        liste = _tumMedya.where((m) => !m.gizli).toList();
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
      final prefs = await SharedPreferences.getInstance();
      for (int i = 0; i < secilen.length; i++) {
        final ad = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        await File(secilen[i].path).copy(p.join(klasor, ad));
        await prefs.setString('alb_$ad', album);
      }
    } else {
      final secilen = await _picker.pickImage(source: kaynak, imageQuality: 92);
      if (secilen == null) return;
      final klasor = await _klasorYolu;
      final prefs = await SharedPreferences.getInstance();
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
      builder: (_) => AlertDialog(
        backgroundColor: R.kart,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const NeonMetin('Sil', renk: R.pembe, fontSize: 20),
        content: Text('${indeksler.length} fotoğraf kalıcı olarak silinsin mi?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const NeonMetin('Sil', renk: R.pembe, fontSize: 14)),
        ],
      ),
    );
    if (onay != true) return;
    for (final i in indeksler) await _gorunenMedya[i].dosya.delete();
    setState(() { _secimModu = false; _secilenler.clear(); });
    await _medyaYukle();
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
        onSec: (kaynak, album) {
          Navigator.pop(context);
          _fotografEkle(kaynak, album: album);
        },
      ),
    );
  }

  PageRouteBuilder _sayfaGecis(Widget sayfa) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => sayfa,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
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
      body: KarWidget(
        child: SafeArea(
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
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [R.cyan, R.mor]).createShader(b),
            child: const Text('NEON GALERİ',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 6, color: Colors.white),
            ),
          ),
          const Spacer(),
          _ikonButon(
            ikon: _aramaAcik ? Icons.close_rounded : Icons.search_rounded,
            renk: R.cyan,
            aktif: _aramaAcik,
            onTap: () => setState(() {
              _aramaAcik = !_aramaAcik;
              if (!_aramaAcik) { _aramaMetni = ''; _aramaCtrl.clear(); _filtrele(); }
            }),
          ),
          const SizedBox(width: 6),
          _ikonButon(
            ikon: _secimModu ? Icons.deselect_rounded : Icons.select_all_rounded,
            renk: Colors.white70,
            aktif: _secimModu,
            onTap: () => setState(() { _secimModu = !_secimModu; _secilenler.clear(); }),
          ),
        ],
      ),
    );
  }

  Widget _ikonButon({required IconData ikon, required Color renk, required bool aktif, required VoidCallback onTap}) {
    return AnimatedBuilder(
      animation: _neonAnim,
      builder: (_, __) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: aktif ? renk.withOpacity(0.15) : Colors.transparent,
            border: Border.all(color: renk.withOpacity(aktif ? 0.5 : 0.2 * _neonAnim.value), width: 1),
            boxShadow: aktif ? [BoxShadow(color: renk.withOpacity(0.2), blurRadius: 16)] : [],
          ),
          child: Icon(ikon, color: renk, size: 20),
        ),
      ),
    );
  }

  Widget _buildAramaBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: R.kart,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: R.cyan.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: R.cyan.withOpacity(0.08), blurRadius: 20)],
        ),
        child: TextField(
          controller: _aramaCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Fotoğraf veya albüm ara...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
            prefixIcon: Icon(Icons.search_rounded, color: R.cyan.withOpacity(0.5), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (v) { setState(() => _aramaMetni = v); _filtrele(); },
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final sekmeler = [
      (Icons.photo_library_outlined, Icons.photo_library_rounded, 'Tümü', R.cyan),
      (Icons.folder_outlined, Icons.folder_rounded, 'Albüm', R.altin),
      (Icons.favorite_border_rounded, Icons.favorite_rounded, 'Favori', R.pembe),
      (Icons.lock_outline_rounded, Icons.lock_rounded, 'Gizli', R.mor),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      height: 50,
      child: Row(
        children: List.generate(sekmeler.length, (i) {
          final aktif = _aktifSekme == i;
          final s = sekmeler[i];
          return Expanded(
            child: GestureDetector(
              onTap: () { setState(() => _aktifSekme = i); _filtrele(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: aktif ? s.$4.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: aktif ? s.$4.withOpacity(0.55) : Colors.white.withOpacity(0.07),
                    width: aktif ? 1.5 : 1,
                  ),
                  boxShadow: aktif ? [BoxShadow(color: s.$4.withOpacity(0.18), blurRadius: 14)] : [],
                ),
                child: Center(
                  child: Icon(
                    aktif ? s.$2 : s.$1,
                    color: aktif ? s.$4 : Colors.white.withOpacity(0.3),
                    size: 20,
                    shadows: aktif ? [Shadow(color: s.$4.withOpacity(0.9), blurRadius: 14)] : [],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGrid() {
    if (_gorunenMedya.isEmpty) return _buildBosEkran();
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2,
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
    for (final m in _gorunenMedya) {
      (gruplar[m.album] ??= []).add(m);
    }
    if (gruplar.isEmpty) return _buildBosEkran();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: gruplar.length,
      itemBuilder: (_, i) {
        final album = gruplar.keys.elementAt(i);
        final liste = gruplar[album]!;
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
    const ikonlar = [Icons.photo_outlined, Icons.folder_outlined, Icons.favorite_border_rounded, Icons.lock_outline_rounded];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikonlar[_aktifSekme], size: 56, color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 14),
          Text(mesajlar[_aktifSekme],
              style: TextStyle(color: Colors.white.withOpacity(0.18), fontSize: 14, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _neonAnim,
      builder: (_, __) => GestureDetector(
        onTap: _kaynakMenusu,
        child: Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [R.cyan, R.mor],
            ),
            boxShadow: [
              BoxShadow(color: R.cyan.withOpacity(0.45 * _neonAnim.value), blurRadius: 28, spreadRadius: 4),
              BoxShadow(color: R.mor.withOpacity(0.25 * _neonAnim.value), blurRadius: 44, spreadRadius: 8),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.black, size: 30),
        ),
      ),
    );
  }

  Widget _buildSecimBar() {
    final gizliMod = _aktifSekme == 3;
    return Container(
      color: R.kart,
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 4,
          left: 8, right: 8, top: 10),
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
          Text('${_secilenler.length} seçili',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          _SecimBtn(ikon: Icons.close_rounded, etiket: 'İptal', renk: Colors.white54,
              onTap: () => setState(() { _secimModu = false; _secilenler.clear(); })),
        ],
      ),
    );
  }
}

// ─── EKLE MENÜSÜ ───────────────────────────────────────────────────────────
class _EkleMenusu extends StatefulWidget {
  final List<String> albumler;
  final Function(ImageSource, String) onSec;
  const _EkleMenusu({required this.albumler, required this.onSec});
  @override
  State<_EkleMenusu> createState() => _EkleMenusuState();
}

class _EkleMenusuState extends State<_EkleMenusu> {
  String _seciliAlbum = 'Genel';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 20, right: 20, top: 16),
      decoration: const BoxDecoration(
        color: R.kart,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 3.5,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const NeonMetin('Fotoğraf Ekle', fontSize: 18, letterSpacing: 2),
          const SizedBox(height: 14),
          Text('Albüm seç', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, letterSpacing: 1)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: aktif ? R.altin.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: aktif ? R.altin.withOpacity(0.55) : Colors.white.withOpacity(0.12)),
                    ),
                    child: Text(a, style: TextStyle(
                        color: aktif ? R.altin : Colors.white54,
                        fontSize: 12,
                        fontWeight: aktif ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: NeonButon(ikon: Icons.photo_library_rounded, etiket: 'Galeri', renk: R.cyan,
                  onTap: () => widget.onSec(ImageSource.gallery, _seciliAlbum))),
              const SizedBox(width: 12),
              Expanded(child: NeonButon(ikon: Icons.camera_alt_rounded, etiket: 'Kamera', renk: R.mor,
                  onTap: () => widget.onSec(ImageSource.camera, _seciliAlbum))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── SEÇİM BUTONU ──────────────────────────────────────────────────────────
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
        opacity: aktif ? 1.0 : 0.35,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ikon, color: renk, size: 26,
                  shadows: aktif ? [Shadow(color: renk.withOpacity(0.7), blurRadius: 12)] : []),
              const SizedBox(height: 4),
              Text(etiket, style: TextStyle(color: renk, fontSize: 10, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ALBÜM KARTI ───────────────────────────────────────────────────────────
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: R.kart,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: R.altin.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: R.altin.withOpacity(0.05), blurRadius: 20)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              child: SizedBox(
                height: 120,
                child: Row(
                  children: List.generate(min(medyalar.length, 3), (i) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < min(medyalar.length, 3) - 1 ? 2 : 0),
                      child: Image.file(medyalar[i].dosya, fit: BoxFit.cover),
                    ),
                  )),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.folder_rounded, color: R.altin.withOpacity(0.8), size: 17,
                      shadows: [Shadow(color: R.altin.withOpacity(0.6), blurRadius: 10)]),
                  const SizedBox(width: 8),
                  NeonMetin(album, renk: R.altin, fontSize: 14),
                  const Spacer(),
                  Text('${medyalar.length} fotoğraf',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FOTO KART ─────────────────────────────────────────────────────────────
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

  @override
  State<_FotoKart> createState() => _FotoKartState();
}

class _FotoKartState extends State<_FotoKart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = Tween(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: (widget.index % 12) * 40), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.file(widget.medya.dosya, fit: BoxFit.cover, cacheWidth: 300),
            ),
            if (widget.secimModu)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: widget.secili ? R.cyan.withOpacity(0.32) : Colors.black.withOpacity(0.1),
                  border: widget.secili ? Border.all(color: R.cyan, width: 2.5) : null,
                ),
              ),
            if (widget.secimModu)
              Positioned(
                top: 6, right: 6,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.secili ? R.cyan : Colors.black.withOpacity(0.55),
                    border: Border.all(color: widget.secili ? R.cyan : Colors.white70, width: 2),
                    boxShadow: widget.secili
                        ? [BoxShadow(color: R.cyan.withOpacity(0.65), blurRadius: 10)]
                        : [],
                  ),
                  child: widget.secili
                      ? const Icon(Icons.check_rounded, size: 13, color: Colors.black)
                      : null,
                ),
              ),
            if (widget.medya.favori && !widget.secimModu)
              Positioned(
                top: 5, right: 5,
                child: Icon(Icons.favorite_rounded, size: 14, color: R.pembe,
                    shadows: [Shadow(color: R.pembe.withOpacity(0.8), blurRadius: 10)]),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── DETAY EKRANI ──────────────────────────────────────────────────────────
class DetayEkrani extends StatefulWidget {
  final List<MedyaDosya> medya;
  final int baslangic;
  final Function(int) onFavori;
  final Function(MedyaDosya, String) onAlbumDegistir;
  final List<String> albumler;

  const DetayEkrani({
    super.key,
    required this.medya,
    required this.baslangic,
    required this.onFavori,
    required this.onAlbumDegistir,
    required this.albumler,
  });

  @override
  State<DetayEkrani> createState() => _DetayEkraniState();
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
    _uiAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 250), value: 1);
  }

  @override
  void dispose() { _ctrl.dispose(); _uiAnim.dispose(); super.dispose(); }

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
        child: Stack(
          children: [
            // Fotoğraflar
            PageView.builder(
              controller: _ctrl,
              itemCount: widget.medya.length,
              onPageChanged: (i) => setState(() => _mevcut = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 0.8, maxScale: 6,
                child: Center(child: Image.file(widget.medya[i].dosya)),
              ),
            ),
            // Üst bar
            FadeTransition(
              opacity: _uiAnim,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text('${_mevcut + 1} / ${widget.medya.length}',
                        style: const TextStyle(color: Colors.white60, fontSize: 13, letterSpacing: 1)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        m.favori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: m.favori ? R.pembe : Colors.white,
                        shadows: m.favori ? [Shadow(color: R.pembe.withOpacity(0.9), blurRadius: 18)] : [],
                      ),
                      onPressed: () { widget.onFavori(_mevcut); setState(() {}); },
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder_open_rounded, color: Colors.white70),
                      onPressed: () => _albumSecDialog(m),
                    ),
                  ],
                ),
              ),
            ),
            // Sayfa indikatörü
            if (widget.medya.length > 1)
              FadeTransition(
                opacity: _uiAnim,
                child: Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(min(widget.medya.length, 15), (i) =>
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: _mevcut == i ? 18 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _mevcut == i ? R.cyan : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: _mevcut == i
                              ? [BoxShadow(color: R.cyan.withOpacity(0.7), blurRadius: 10)]
                              : [],
                        ),
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

  void _albumSecDialog(MedyaDosya m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 20, right: 20, top: 16),
        decoration: const BoxDecoration(
          color: R.kart,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 3.5,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const NeonMetin('Albüm Seç', renk: R.altin, fontSize: 17),
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
                      color: aktif ? R.altin.withOpacity(0.12) : R.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: aktif ? R.altin.withOpacity(0.55) : Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(a, style: TextStyle(
                        color: aktif ? R.altin : Colors.white70,
                        fontWeight: aktif ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
