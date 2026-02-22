import 'dart:io';
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
  ));
  runApp(const NeonGaleriApp());
}

class NeonRenkler {
  static const arkaplan = Color(0xFF050508);
  static const kart = Color(0xFF0D0D14);
  static const cyan = Color(0xFF00FFEA);
  static const mor = Color(0xFFB400FF);
  static const pembe = Color(0xFFFF006E);
  static const altin = Color(0xFFFFD700);
  static const yesil = Color(0xFF00FF88);
}

class MedyaDosya {
  final File dosya;
  final DateTime tarih;
  bool gizli;
  bool favori;

  MedyaDosya({
    required this.dosya,
    required this.tarih,
    this.gizli = false,
    this.favori = false,
  });
}

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
        useMaterial3: true,
      ),
      home: const GirisEkrani(),
    );
  }
}

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});
  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AnaSayfa()));
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
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: NeonRenkler.cyan.withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 10),
                    ],
                  ),
                  child: const Icon(Icons.photo_filter_rounded,
                      size: 90, color: NeonRenkler.cyan),
                ),
                const SizedBox(height: 28),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                      colors: [NeonRenkler.cyan, NeonRenkler.mor])
                      .createShader(b),
                  child: const Text('NEON GALERİ',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          color: Colors.white)),
                ),
                const SizedBox(height: 10),
                const Text('Anılarını sakla · gizle · keşfet',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                        letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
  Set<int> _secilenler = {};
  String _aktifAlbum = 'Tümü';
  late AnimationController _neonCtrl;
  late Animation<double> _neonAnim;

  final List<String> _albumler = ['Tümü', 'Favoriler', 'Gizli'];

  @override
  void initState() {
    super.initState();
    _neonCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _neonAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_neonCtrl);
    _medyaYukle();
  }

  @override
  void dispose() {
    _neonCtrl.dispose();
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
        ..sort((a, b) =>
            b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      for (final d in dosyalar) {
        final key = p.basename(d.path);
        liste.add(MedyaDosya(
          dosya: d,
          tarih: d.lastModifiedSync(),
          gizli: ky == gizli,
          favori: prefs.getBool('fav_$key') ?? false,
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
        case 'Gizli':
          _gorunenMedya = _tumMedya.where((m) => m.gizli).toList();
          break;
        default:
          _gorunenMedya = _tumMedya.where((m) => !m.gizli).toList();
      }
    });
  }

  Future<void> _fotografEkle(ImageSource kaynak) async {
    final XFile? secilen =
        await _picker.pickImage(source: kaynak, imageQuality: 92);
    if (secilen == null) return;
    final klasor = await _klasorYolu;
    final ad = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(secilen.path).copy(p.join(klasor, ad));
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
    setState(() { _secimModu = false; _secilenler = {}; });
    await _medyaYukle();
    _snack('Gizlendi 🔒', NeonRenkler.mor);
  }

  Future<void> _gizlidenCikar(List<int> indeksler) async {
    final normalKlasor = await _klasorYolu;
    for (final i in indeksler) {
      final m = _gorunenMedya[i];
      final hedef = File(p.join(normalKlasor, p.basename(m.dosya.path)));
      await m.dosya.copy(hedef.path);
      await m.dosya.delete();
    }
    setState(() { _secimModu = false; _secilenler = {}; });
    await _medyaYukle();
    _snack('Görünür yapıldı ✅', NeonRenkler.yesil);
  }

  Future<void> _favoriToggle(int i) async {
    final prefs = await SharedPreferences.getInstance();
    final m = _gorunenMedya[i];
    m.favori = !m.favori;
    await prefs.setBool('fav_${p.basename(m.dosya.path)}', m.favori);
    setState(() {});
  }

  Future<void> _sil(List<int> indeksler) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: NeonRenkler.kart,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: NeonRenkler.pembe.withOpacity(0.4))),
        title: Text('${indeksler.length} öğe silinsin mi?',
            style: const TextStyle(color: Colors.white)),
        content: const Text('Bu işlem geri alınamaz.',
            style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal',
                  style: TextStyle(color: Colors.white38))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil',
                  style: TextStyle(color: NeonRenkler.pembe))),
        ],
      ),
    );
    if (onay != true) return;
    for (final i in indeksler) await _gorunenMedya[i].dosya.delete();
    setState(() { _secimModu = false; _secilenler = {}; });
    await _medyaYukle();
    _snack('Silindi 🗑️', NeonRenkler.pembe);
  }

  void _snack(String msg, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style:
              TextStyle(color: renk, fontWeight: FontWeight.bold)),
      backgroundColor: NeonRenkler.kart,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: renk)),
    ));
  }

  void _kaynakMenusu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: NeonRenkler.kart,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: NeonRenkler.cyan.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
                color: NeonRenkler.cyan.withOpacity(0.2),
                blurRadius: 30)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 3,
              decoration: BoxDecoration(
                  color: NeonRenkler.cyan.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _MenuBtn(
                  ikon: Icons.camera_alt_rounded,
                  etiket: 'Kamera',
                  renk: NeonRenkler.cyan,
                  onTap: () { Navigator.pop(context); _fotografEkle(ImageSource.camera); },
                )),
                const SizedBox(width: 12),
                Expanded(child: _MenuBtn(
                  ikon: Icons.photo_library_rounded,
                  etiket: 'Galeri',
                  renk: NeonRenkler.mor,
                  onTap: () { Navigator.pop(context); _fotografEkle(ImageSource.gallery); },
                )),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonRenkler.arkaplan,
      body: Column(
        children: [
          // AppBar
          AnimatedBuilder(
            animation: _neonAnim,
            builder: (_, __) => Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 20, right: 12, bottom: 16),
              decoration: BoxDecoration(
                color: NeonRenkler.arkaplan,
                border: Border(
                  bottom: BorderSide(
                    color: NeonRenkler.cyan.withOpacity(0.1 * _neonAnim.value),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (!_secimModu) ...[
                    ShaderMask(
                      shaderCallback: (b) => LinearGradient(colors: [
                        NeonRenkler.cyan,
                        NeonRenkler.mor.withOpacity(_neonAnim.value),
                      ]).createShader(b),
                      child: const Text('NEON',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: Colors.white)),
                    ),
                    const SizedBox(width: 6),
                    const Text('GALERİ',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w200,
                            letterSpacing: 4,
                            color: Colors.white38)),
                    const Spacer(),
                    Text('${_gorunenMedya.length} öğe',
                        style: const TextStyle(
                            color: Colors.white24, fontSize: 12)),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => setState(() {
                        _secimModu = false; _secilenler = {};
                      }),
                    ),
                    Text('${_secilenler.length} seçildi',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _aktifAlbum == 'Gizli'
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                        color: NeonRenkler.mor,
                      ),
                      onPressed: _aktifAlbum == 'Gizli'
                          ? () => _gizlidenCikar(_secilenler.toList())
                          : () => _gizle(_secilenler.toList()),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: NeonRenkler.pembe),
                      onPressed: () => _sil(_secilenler.toList()),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Albüm bar
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _albumler.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sec = _albumler[i] == _aktifAlbum;
                return GestureDetector(
                  onTap: () {
                    setState(() => _aktifAlbum = _albumler[i]);
                    _filtrele();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sec
                          ? NeonRenkler.cyan.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: sec ? NeonRenkler.cyan : Colors.white12,
                        width: sec ? 1.5 : 1,
                      ),
                      boxShadow: sec
                          ? [BoxShadow(
                              color: NeonRenkler.cyan.withOpacity(0.3),
                              blurRadius: 12)]
                          : [],
                    ),
                    child: Text(
                      _albumler[i],
                      style: TextStyle(
                        color: sec ? NeonRenkler.cyan : Colors.white38,
                        fontSize: 13,
                        fontWeight: sec ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Grid
          Expanded(
            child: _gorunenMedya.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _aktifAlbum == 'Gizli'
                              ? Icons.lock_outline_rounded
                              : _aktifAlbum == 'Favoriler'
                                  ? Icons.favorite_outline_rounded
                                  : Icons.photo_outlined,
                          size: 72,
                          color: NeonRenkler.cyan.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _aktifAlbum == 'Tümü'
                              ? 'Henüz fotoğraf yok'
                              : '$_aktifAlbum boş',
                          style: const TextStyle(
                              color: Colors.white24, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(3),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 3,
                      crossAxisSpacing: 3,
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
                      onLongPress: () => setState(() {
                        _secimModu = true;
                        _secilenler.add(i);
                      }),
                    ),
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
                            .withOpacity(0.5 * _neonAnim.value),
                        blurRadius: 24,
                        spreadRadius: 4),
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

class _MenuBtn extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final Color renk;
  final VoidCallback onTap;
  const _MenuBtn({required this.ikon, required this.etiket, required this.renk, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: renk.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: renk.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Icon(ikon, color: renk, size: 34),
            const SizedBox(height: 8),
            Text(etiket, style: TextStyle(color: renk, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _FotoKart extends StatefulWidget {
  final MedyaDosya medya;
  final int index;
  final bool secili;
  final bool secimModu;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FotoKart({
    required this.medya, required this.index,
    required this.secili, required this.secimModu,
    required this.onTap, required this.onLongPress,
  });

  @override
  State<_FotoKart> createState() => _FotoKartState();
}

class _FotoKartState extends State<_FotoKart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: widget.index * 35), () {
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
              borderRadius: BorderRadius.circular(4),
              child: Image.file(widget.medya.dosya,
                  fit: BoxFit.cover, cacheWidth: 300),
            ),
            if (widget.secimModu)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: widget.secili
                      ? NeonRenkler.cyan.withOpacity(0.35)
                      : Colors.black.withOpacity(0.2),
                  border: widget.secili
                      ? Border.all(color: NeonRenkler.cyan, width: 2)
                      : null,
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
                    color: widget.secili ? NeonRenkler.cyan : Colors.transparent,
                    border: Border.all(
                      color: widget.secili ? NeonRenkler.cyan : Colors.white,
                      width: 2,
                    ),
                    boxShadow: widget.secili
                        ? [BoxShadow(color: NeonRenkler.cyan.withOpacity(0.5), blurRadius: 8)]
                        : [],
                  ),
                  child: widget.secili
                      ? const Icon(Icons.check_rounded, size: 13, color: Colors.black)
                      : null,
                ),
              ),
            if (widget.medya.favori && !widget.secimModu)
              const Positioned(
                top: 4, right: 4,
                child: Icon(Icons.favorite_rounded,
                    size: 16, color: NeonRenkler.pembe),
              ),
          ],
        ),
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _mevcut = widget.baslangic;
    _ctrl = PageController(initialPage: _mevcut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final m = widget.medya[_mevcut];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _uiGoster = !_uiGoster),
        child: Stack(
          children: [
            PageView.builder(
              controller: _ctrl,
              itemCount: widget.medya.length,
              onPageChanged: (i) => setState(() => _mevcut = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                    child: Image.file(widget.medya[i].dosya)),
              ),
            ),
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
                    Text('${_mevcut + 1} / ${widget.medya.length}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        m.favori
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: m.favori ? NeonRenkler.pembe : Colors.white,
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
          ],
        ),
      ),
    );
  }
}
