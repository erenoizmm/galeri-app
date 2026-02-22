import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const NeonGaleriApp());
}

// ── Renkler ───────────────────────────────────────────────────────────────
class NeonRenkler {
  static const arkaplan = Color(0xFF050508);
  static const kart = Color(0xFF0D0D14);
  static const cyan = Color(0xFF00FFEA);
  static const mor = Color(0xFFB400FF);
  static const pembe = Color(0xFFFF006E);
  static const altin = Color(0xFFFFD700);
  static const yesil = Color(0xFF00FF88);
  static const cizgi = Color(0xFF1A1A2E);

  static const cyanGlow = BoxShadow(
    color: Color(0x6600FFEA),
    blurRadius: 20,
    spreadRadius: 2,
  );
  static const morGlow = BoxShadow(
    color: Color(0x66B400FF),
    blurRadius: 20,
    spreadRadius: 2,
  );
  static const pembeGlow = BoxShadow(
    color: Color(0x66FF006E),
    blurRadius: 20,
    spreadRadius: 2,
  );
}

// ── Model ─────────────────────────────────────────────────────────────────
enum MedyaTip { fotograf, video }

class MedyaDosya {
  final File dosya;
  final MedyaTip tip;
  final DateTime tarih;
  bool gizli;
  bool favori;
  String? album;

  MedyaDosya({
    required this.dosya,
    required this.tip,
    required this.tarih,
    this.gizli = false,
    this.favori = false,
    this.album,
  });
}

// ── App ───────────────────────────────────────────────────────────────────
class NeonGaleriApp extends StatelessWidget {
  const NeonGaleriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEON GALERİ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: NeonRenkler.arkaplan,
        colorScheme: const ColorScheme.dark(
          primary: NeonRenkler.cyan,
          secondary: NeonRenkler.mor,
          surface: NeonRenkler.kart,
        ),
        useMaterial3: true,
      ),
      home: const GirisEkrani(),
    );
  }
}

// ── Giriş / PIN Ekranı ────────────────────────────────────────────────────
class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const AnaSayfa()));
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonRenkler.arkaplan,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NeonGlow(
                  renk: NeonRenkler.cyan,
                  child: const Icon(Icons.photo_filter_rounded,
                      size: 80, color: NeonRenkler.cyan),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [NeonRenkler.cyan, NeonRenkler.mor],
                  ).createShader(bounds),
                  child: const Text(
                    'NEON GALERİ',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Anılarını sakla, gizle, keşfet',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      letterSpacing: 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ana Sayfa ─────────────────────────────────────────────────────────────
class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa>
    with TickerProviderStateMixin {
  List<MedyaDosya> _tumMedya = [];
  List<MedyaDosya> _gorunenMedya = [];
  final ImagePicker _picker = ImagePicker();
  int _altTabIndex = 0;
  bool _secimModu = false;
  Set<int> _secilenler = {};
  bool _gizliGoster = false;
  String _aktifAlbum = 'Tümü';
  late AnimationController _fabCtrl;
  late AnimationController _neonCtrl;
  late Animation<double> _neonAnim;
  bool _fabAcik = false;

  final List<String> _albumler = ['Tümü', 'Favoriler', 'Videolar', 'Gizli'];

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _neonCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _neonAnim = Tween<double>(begin: 0.5, end: 1.0).animate(_neonCtrl);
    _medyaYukle();
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    _neonCtrl.dispose();
    super.dispose();
  }

  Future<String> get _klasorYolu async {
    final dir = await getApplicationDocumentsDirectory();
    final k = Directory(p.join(dir.path, 'neon_galeri'));
    if (!await k.exists()) await k.create(recursive: true);
    return k.path;
  }

  Future<String> get _gizliKlasorYolu async {
    final dir = await getApplicationDocumentsDirectory();
    final k = Directory(p.join(dir.path, 'neon_gizli'));
    if (!await k.exists()) await k.create(recursive: true);
    return k.path;
  }

  Future<void> _medyaYukle() async {
    final klasor = await _klasorYolu;
    final gizliKlasor = await _gizliKlasorYolu;
    final prefs = await SharedPreferences.getInstance();

    List<MedyaDosya> liste = [];

    for (final klasorYolu in [klasor, gizliKlasor]) {
      final dir = Directory(klasorYolu);
      final dosyalar = dir.listSync().whereType<File>().toList()
        ..sort((a, b) =>
            b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      for (final dosya in dosyalar) {
        final ext = p.extension(dosya.path).toLowerCase();
        MedyaTip? tip;
        if (['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
          tip = MedyaTip.fotograf;
        } else if (['.mp4', '.mov', '.avi', '.mkv'].contains(ext)) {
          tip = MedyaTip.video;
        }
        if (tip == null) continue;

        final key = p.basename(dosya.path);
        liste.add(MedyaDosya(
          dosya: dosya,
          tip: tip,
          tarih: dosya.lastModifiedSync(),
          gizli: klasorYolu == gizliKlasor,
          favori: prefs.getBool('fav_$key') ?? false,
          album: prefs.getString('album_$key'),
        ));
      }
    }

    setState(() {
      _tumMedya = liste;
      _filtrele();
    });
  }

  void _filtrele() {
    setState(() {
      switch (_aktifAlbum) {
        case 'Favoriler':
          _gorunenMedya =
              _tumMedya.where((m) => m.favori && !m.gizli).toList();
          break;
        case 'Videolar':
          _gorunenMedya = _tumMedya
              .where((m) => m.tip == MedyaTip.video && !m.gizli)
              .toList();
          break;
        case 'Gizli':
          _gorunenMedya = _tumMedya.where((m) => m.gizli).toList();
          break;
        default:
          _gorunenMedya = _tumMedya.where((m) => !m.gizli).toList();
      }
    });
  }

  Future<void> _medyaEkle(ImageSource kaynak, bool video) async {
    XFile? secilen;
    if (video) {
      secilen = await _picker.pickVideo(source: kaynak);
    } else {
      secilen = await _picker.pickImage(source: kaynak, imageQuality: 92);
    }
    if (secilen == null) return;

    final klasor = await _klasorYolu;
    final ext = p.extension(secilen.path);
    final ad = '${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(secilen.path).copy(p.join(klasor, ad));
    await _medyaYukle();
  }

  Future<void> _gizle(List<int> indeksler) async {
    final gizliKlasor = await _gizliKlasorYolu;
    for (final i in indeksler) {
      final m = _gorunenMedya[i];
      final hedef =
          File(p.join(gizliKlasor, p.basename(m.dosya.path)));
      await m.dosya.copy(hedef.path);
      await m.dosya.delete();
    }
    setState(() {
      _secimModu = false;
      _secilenler = {};
    });
    await _medyaYukle();
    if (mounted) {
      _snack('${indeksler.length} öğe gizlendi 🔒', NeonRenkler.mor);
    }
  }

  Future<void> _gizlidenCikar(List<int> indeksler) async {
    final normalKlasor = await _klasorYolu;
    for (final i in indeksler) {
      final m = _gorunenMedya[i];
      final hedef =
          File(p.join(normalKlasor, p.basename(m.dosya.path)));
      await m.dosya.copy(hedef.path);
      await m.dosya.delete();
    }
    setState(() {
      _secimModu = false;
      _secilenler = {};
    });
    await _medyaYukle();
    if (mounted) {
      _snack('${indeksler.length} öğe görünür yapıldı ✅', NeonRenkler.yesil);
    }
  }

  Future<void> _favoriToggle(int i) async {
    final prefs = await SharedPreferences.getInstance();
    final m = _gorunenMedya[i];
    final key = 'fav_${p.basename(m.dosya.path)}';
    m.favori = !m.favori;
    await prefs.setBool(key, m.favori);
    setState(() {});
  }

  Future<void> _sil(List<int> indeksler) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => _NeonDialog(
        baslik: '${indeksler.length} öğe silinsin mi?',
        icerik: 'Bu işlem geri alınamaz.',
        onayMetni: 'Sil',
        onayRenk: NeonRenkler.pembe,
        onOnay: () => Navigator.pop(context, true),
        onIptal: () => Navigator.pop(context, false),
      ),
    );
    if (onay != true) return;

    for (final i in indeksler) {
      await _gorunenMedya[i].dosya.delete();
    }
    setState(() {
      _secimModu = false;
      _secilenler = {};
    });
    await _medyaYukle();
    if (mounted) _snack('Silindi 🗑️', NeonRenkler.pembe);
  }

  void _snack(String mesaj, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj,
          style: TextStyle(color: renk, fontWeight: FontWeight.bold)),
      backgroundColor: NeonRenkler.kart,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: renk, width: 1)),
    ));
  }

  void _fabToggle() {
    setState(() => _fabAcik = !_fabAcik);
    if (_fabAcik) {
      _fabCtrl.forward();
    } else {
      _fabCtrl.reverse();
    }
  }

  void _kaynakMenusu() {
    _fabToggle();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _EkleMenusu(
        onFotografKamera: () {
          Navigator.pop(context);
          _medyaEkle(ImageSource.camera, false);
        },
        onFotografGaleri: () {
          Navigator.pop(context);
          _medyaEkle(ImageSource.gallery, false);
        },
        onVideoKamera: () {
          Navigator.pop(context);
          _medyaEkle(ImageSource.camera, true);
        },
        onVideoGaleri: () {
          Navigator.pop(context);
          _medyaEkle(ImageSource.gallery, true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonRenkler.arkaplan,
      body: Column(
        children: [
          _NeonAppBar(
            secimModu: _secimModu,
            secilenSayi: _secilenler.length,
            medyaSayi: _gorunenMedya.length,
            neonAnim: _neonAnim,
            onSecimIptal: () => setState(() {
              _secimModu = false;
              _secilenler = {};
            }),
            onSil: () => _sil(_secilenler.toList()),
            onGizle: _aktifAlbum == 'Gizli'
                ? () => _gizlidenCikar(_secilenler.toList())
                : () => _gizle(_secilenler.toList()),
            gizliMod: _aktifAlbum == 'Gizli',
          ),
          _AlbumBar(
            albumler: _albumler,
            aktif: _aktifAlbum,
            onSecim: (a) {
              setState(() => _aktifAlbum = a);
              _filtrele();
            },
          ),
          Expanded(
            child: _gorunenMedya.isEmpty
                ? _BosEkran(aktifAlbum: _aktifAlbum)
                : _GaleriGrid(
                    medya: _gorunenMedya,
                    secimModu: _secimModu,
                    secilenler: _secilenler,
                    onTap: (i) {
                      if (_secimModu) {
                        setState(() {
                          if (_secilenler.contains(i)) {
                            _secilenler.remove(i);
                            if (_secilenler.isEmpty) _secimModu = false;
                          } else {
                            _secilenler.add(i);
                          }
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetayEkrani(
                              medya: _gorunenMedya,
                              baslangic: i,
                              onFavori: _favoriToggle,
                            ),
                          ),
                        );
                      }
                    },
                    onLongPress: (i) {
                      setState(() {
                        _secimModu = true;
                        _secilenler.add(i);
                      });
                    },
                    onFavori: _favoriToggle,
                  ),
          ),
        ],
      ),
      floatingActionButton: _secimModu
          ? null
          : AnimatedBuilder(
              animation: _neonAnim,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: NeonRenkler.cyan
                          .withOpacity(0.4 * _neonAnim.value),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: _kaynakMenusu,
                  backgroundColor: NeonRenkler.cyan,
                  foregroundColor: Colors.black,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add_rounded, size: 32),
                ),
              ),
            ),
    );
  }
}

// ── NeonAppBar ────────────────────────────────────────────────────────────
class _NeonAppBar extends StatelessWidget {
  final bool secimModu;
  final int secilenSayi;
  final int medyaSayi;
  final Animation<double> neonAnim;
  final VoidCallback onSecimIptal;
  final VoidCallback onSil;
  final VoidCallback onGizle;
  final bool gizliMod;

  const _NeonAppBar({
    required this.secimModu,
    required this.secilenSayi,
    required this.medyaSayi,
    required this.neonAnim,
    required this.onSecimIptal,
    required this.onSil,
    required this.onGizle,
    required this.gizliMod,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: neonAnim,
      builder: (_, __) => Container(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 20,
            right: 16,
            bottom: 16),
        decoration: BoxDecoration(
          color: NeonRenkler.arkaplan,
          border: Border(
            bottom: BorderSide(
              color: NeonRenkler.cyan.withOpacity(0.15 * neonAnim.value),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            if (!secimModu) ...[
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: [
                    NeonRenkler.cyan,
                    NeonRenkler.mor.withOpacity(neonAnim.value),
                  ],
                ).createShader(b),
                child: const Text(
                  'NEON',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'GALERİ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 4,
                  color: Colors.white38,
                ),
              ),
              const Spacer(),
              Text(
                '$medyaSayi öğe',
                style: const TextStyle(
                    color: Colors.white24, fontSize: 12),
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white70),
                onPressed: onSecimIptal,
              ),
              Text(
                '$secilenSayi seçildi',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  gizliMod
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  color: NeonRenkler.mor,
                ),
                onPressed: onGizle,
                tooltip: gizliMod ? 'Gizliden Çıkar' : 'Gizle',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: NeonRenkler.pembe),
                onPressed: onSil,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Albüm Bar ─────────────────────────────────────────────────────────────
class _AlbumBar extends StatelessWidget {
  final List<String> albumler;
  final String aktif;
  final Function(String) onSecim;

  const _AlbumBar(
      {required this.albumler,
      required this.aktif,
      required this.onSecim});

  IconData _ikon(String a) {
    switch (a) {
      case 'Favoriler':
        return Icons.favorite_rounded;
      case 'Videolar':
        return Icons.videocam_rounded;
      case 'Gizli':
        return Icons.lock_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albumler.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final secili = albumler[i] == aktif;
          return GestureDetector(
            onTap: () => onSecim(albumler[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: secili ? NeonRenkler.cyan.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: secili ? NeonRenkler.cyan : Colors.white12,
                  width: secili ? 1.5 : 1,
                ),
                boxShadow: secili ? [NeonRenkler.cyanGlow] : [],
              ),
              child: Row(
                children: [
                  Icon(_ikon(albumler[i]),
                      size: 14,
                      color:
                          secili ? NeonRenkler.cyan : Colors.white38),
                  const SizedBox(width: 6),
                  Text(
                    albumler[i],
                    style: TextStyle(
                      color:
                          secili ? NeonRenkler.cyan : Colors.white38,
                      fontSize: 13,
                      fontWeight: secili
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Galeri Grid ───────────────────────────────────────────────────────────
class _GaleriGrid extends StatelessWidget {
  final List<MedyaDosya> medya;
  final bool secimModu;
  final Set<int> secilenler;
  final Function(int) onTap;
  final Function(int) onLongPress;
  final Function(int) onFavori;

  const _GaleriGrid({
    required this.medya,
    required this.secimModu,
    required this.secilenler,
    required this.onTap,
    required this.onLongPress,
    required this.onFavori,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemCount: medya.length,
      itemBuilder: (_, i) => _MedyaKart(
        medya: medya[i],
        index: i,
        secili: secilenler.contains(i),
        secimModu: secimModu,
        onTap: () => onTap(i),
        onLongPress: () => onLongPress(i),
        onFavori: () => onFavori(i),
      ),
    );
  }
}

// ── Medya Kart ────────────────────────────────────────────────────────────
class _MedyaKart extends StatefulWidget {
  final MedyaDosya medya;
  final int index;
  final bool secili;
  final bool secimModu;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavori;

  const _MedyaKart({
    required this.medya,
    required this.index,
    required this.secili,
    required this.secimModu,
    required this.onTap,
    required this.onLongPress,
    required this.onFavori,
  });

  @override
  State<_MedyaKart> createState() => _MedyaKartState();
}

class _MedyaKartState extends State<_MedyaKart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    Future.delayed(Duration(milliseconds: widget.index * 40), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Görüntü
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: widget.medya.tip == MedyaTip.fotograf
                  ? Image.file(widget.medya.dosya,
                      fit: BoxFit.cover, cacheWidth: 300)
                  : _VideoThumbnail(dosya: widget.medya.dosya),
            ),
            // Neon seçim overlay
            if (widget.secimModu)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: widget.secili
                      ? NeonRenkler.cyan.withOpacity(0.35)
                      : Colors.black.withOpacity(0.25),
                  border: widget.secili
                      ? Border.all(color: NeonRenkler.cyan, width: 2)
                      : null,
                ),
              ),
            // Seçim işareti
            if (widget.secimModu)
              Positioned(
                top: 6,
                right: 6,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.secili
                        ? NeonRenkler.cyan
                        : Colors.transparent,
                    border: Border.all(
                      color: widget.secili
                          ? NeonRenkler.cyan
                          : Colors.white70,
                      width: 2,
                    ),
                    boxShadow: widget.secili
                        ? [NeonRenkler.cyanGlow]
                        : [],
                  ),
                  child: widget.secili
                      ? const Icon(Icons.check_rounded,
                          size: 13, color: Colors.black)
                      : null,
                ),
              ),
            // Video ikonu
            if (widget.medya.tip == MedyaTip.video && !widget.secimModu)
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: NeonRenkler.cyan.withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      size: 14, color: NeonRenkler.cyan),
                ),
              ),
            // Favori
            if (widget.medya.favori && !widget.secimModu)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.favorite_rounded,
                    size: 16, color: NeonRenkler.pembe),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Video Thumbnail ───────────────────────────────────────────────────────
class _VideoThumbnail extends StatefulWidget {
  final File dosya;
  const _VideoThumbnail({required this.dosya});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.file(widget.dosya)
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ctrl == null || !_ctrl!.value.isInitialized) {
      return Container(
        color: NeonRenkler.kart,
        child: const Center(
          child: Icon(Icons.videocam_rounded,
              color: NeonRenkler.cyan, size: 32),
        ),
      );
    }
    return VideoPlayer(_ctrl!);
  }
}

// ── Boş Ekran ─────────────────────────────────────────────────────────────
class _BosEkran extends StatelessWidget {
  final String aktifAlbum;
  const _BosEkran({required this.aktifAlbum});

  @override
  Widget build(BuildContext context) {
    final (ikon, mesaj) = switch (aktifAlbum) {
      'Favoriler' => (Icons.favorite_outline_rounded, 'Favori yok'),
      'Videolar' => (Icons.videocam_off_outlined, 'Video yok'),
      'Gizli' => (Icons.lock_outline_rounded, 'Gizli öğe yok'),
      _ => (Icons.photo_outlined, 'Henüz fotoğraf yok'),
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NeonGlow(
            renk: NeonRenkler.cyan.withOpacity(0.3),
            child: Icon(ikon, size: 72, color: NeonRenkler.cyan.withOpacity(0.4)),
          ),
          const SizedBox(height: 16),
          Text(mesaj,
              style: const TextStyle(
                  color: Colors.white24, fontSize: 16, letterSpacing: 2)),
          if (aktifAlbum == 'Tümü') ...[
            const SizedBox(height: 8),
            const Text('+ butonuna bas',
                style: TextStyle(color: Colors.white12, fontSize: 13)),
          ]
        ],
      ),
    );
  }
}

// ── Ekleme Menüsü ─────────────────────────────────────────────────────────
class _EkleMenusu extends StatelessWidget {
  final VoidCallback onFotografKamera;
  final VoidCallback onFotografGaleri;
  final VoidCallback onVideoKamera;
  final VoidCallback onVideoGaleri;

  const _EkleMenusu({
    required this.onFotografKamera,
    required this.onFotografGaleri,
    required this.onVideoKamera,
    required this.onVideoGaleri,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NeonRenkler.kart,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: NeonRenkler.cyan.withOpacity(0.2)),
        boxShadow: [NeonRenkler.cyanGlow],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: NeonRenkler.cyan.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MenuButon(
                  ikon: Icons.camera_alt_rounded,
                  etiket: 'Fotoğraf\nKamera',
                  renk: NeonRenkler.cyan,
                  onTap: onFotografKamera,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MenuButon(
                  ikon: Icons.photo_library_rounded,
                  etiket: 'Fotoğraf\nGaleri',
                  renk: NeonRenkler.mor,
                  onTap: onFotografGaleri,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MenuButon(
                  ikon: Icons.videocam_rounded,
                  etiket: 'Video\nKamera',
                  renk: NeonRenkler.pembe,
                  onTap: onVideoKamera,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MenuButon(
                  ikon: Icons.video_library_rounded,
                  etiket: 'Video\nGaleri',
                  renk: NeonRenkler.altin,
                  onTap: onVideoGaleri,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MenuButon extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final Color renk;
  final VoidCallback onTap;

  const _MenuButon(
      {required this.ikon,
      required this.etiket,
      required this.renk,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: renk.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: renk.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(ikon, color: renk, size: 32),
            const SizedBox(height: 8),
            Text(
              etiket,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: renk, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Neon Dialog ───────────────────────────────────────────────────────────
class _NeonDialog extends StatelessWidget {
  final String baslik;
  final String icerik;
  final String onayMetni;
  final Color onayRenk;
  final VoidCallback onOnay;
  final VoidCallback onIptal;

  const _NeonDialog({
    required this.baslik,
    required this.icerik,
    required this.onayMetni,
    required this.onayRenk,
    required this.onOnay,
    required this.onIptal,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: NeonRenkler.kart,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: onayRenk.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: onayRenk, size: 48),
            const SizedBox(height: 16),
            Text(baslik,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(icerik,
                style: const TextStyle(color: Colors.white38),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onIptal,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('İptal',
                        style: TextStyle(color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onOnay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onayRenk.withOpacity(0.2),
                      side: BorderSide(color: onayRenk),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(onayMetni,
                        style: TextStyle(color: onayRenk)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Neon Glow Widget ──────────────────────────────────────────────────────
class _NeonGlow extends StatelessWidget {
  final Widget child;
  final Color renk;

  const _NeonGlow({required this.child, required this.renk});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: renk.withOpacity(0.4), blurRadius: 30, spreadRadius: 8),
        ],
      ),
      child: child,
    );
  }
}

// ── Detay / Tam Ekran ─────────────────────────────────────────────────────
class DetayEkrani extends StatefulWidget {
  final List<MedyaDosya> medya;
  final int baslangic;
  final Function(int) onFavori;

  const DetayEkrani({
    super.key,
    required this.medya,
    required this.baslangic,
    required this.onFavori,
  });

  @override
  State<DetayEkrani> createState() => _DetayEkraniState();
}

class _DetayEkraniState extends State<DetayEkrani> {
  late PageController _ctrl;
  late int _mevcut;
  bool _uiGoster = true;
  VideoPlayerController? _videoCtrl;

  @override
  void initState() {
    super.initState();
    _mevcut = widget.baslangic;
    _ctrl = PageController(initialPage: _mevcut);
    _videoYukle(_mevcut);
  }

  void _videoYukle(int i) {
    _videoCtrl?.dispose();
    _videoCtrl = null;
    if (widget.medya[i].tip == MedyaTip.video) {
      _videoCtrl =
          VideoPlayerController.file(widget.medya[i].dosya)
            ..initialize().then((_) {
              if (mounted) {
                setState(() {});
                _videoCtrl!.play();
              }
            });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.medya[_mevcut];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _uiGoster = !_uiGoster),
        child: Stack(
          children: [
            // İçerik
            PageView.builder(
              controller: _ctrl,
              itemCount: widget.medya.length,
              onPageChanged: (i) {
                setState(() => _mevcut = i);
                _videoYukle(i);
              },
              itemBuilder: (_, i) {
                final med = widget.medya[i];
                if (med.tip == MedyaTip.fotograf) {
                  return InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5,
                    child: Center(
                        child: Image.file(med.dosya)),
                  );
                } else {
                  return Center(
                    child: _videoCtrl != null &&
                            _videoCtrl!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _videoCtrl!.value.aspectRatio,
                            child: VideoPlayer(_videoCtrl!),
                          )
                        : const CircularProgressIndicator(
                            color: NeonRenkler.cyan),
                  );
                }
              },
            ),
            // Üst bar
            AnimatedOpacity(
              opacity: _uiGoster ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      '${_mevcut + 1} / ${widget.medya.length}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        m.favori
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: m.favori
                            ? NeonRenkler.pembe
                            : Colors.white,
                      ),
                      onPressed: () {
                        widget.onFavori(_mevcut);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Video kontrol
            if (m.tip == MedyaTip.video &&
                _videoCtrl != null &&
                _videoCtrl!.value.isInitialized)
              AnimatedOpacity(
                opacity: _uiGoster ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _videoCtrl!.value.isPlaying
                            ? _videoCtrl!.pause()
                            : _videoCtrl!.play();
                      });
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                        border:
                            Border.all(color: NeonRenkler.cyan, width: 2),
                        boxShadow: [NeonRenkler.cyanGlow],
                      ),
                      child: Icon(
                        _videoCtrl!.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: NeonRenkler.cyan,
                        size: 36,
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
