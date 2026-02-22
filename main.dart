import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const GaleriApp());
}

class GaleriApp extends StatelessWidget {
  const GaleriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galeri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE0FF4F),
          surface: const Color(0xFF1A1A1A),
        ),
        useMaterial3: true,
      ),
      home: const GaleriSayfasi(),
    );
  }
}

class GaleriSayfasi extends StatefulWidget {
  const GaleriSayfasi({super.key});

  @override
  State<GaleriSayfasi> createState() => _GaleriSayfasiState();
}

class _GaleriSayfasiState extends State<GaleriSayfasi>
    with SingleTickerProviderStateMixin {
  List<File> _fotograflar = [];
  final ImagePicker _picker = ImagePicker();
  late AnimationController _fabAnimController;
  bool _secimModu = false;
  Set<int> _secilenler = {};

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fotograflariYukle();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  Future<String> get _fotografKlasoru async {
    final dir = await getApplicationDocumentsDirectory();
    final klasor = Directory(p.join(dir.path, 'galeri'));
    if (!await klasor.exists()) {
      await klasor.create(recursive: true);
    }
    return klasor.path;
  }

  Future<void> _fotograflariYukle() async {
    final klasorYolu = await _fotografKlasoru;
    final klasor = Directory(klasorYolu);
    final dosyalar = klasor
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.jpg') ||
            f.path.endsWith('.jpeg') ||
            f.path.endsWith('.png'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    setState(() {
      _fotograflar = dosyalar;
    });
  }

  Future<void> _fotografEkle(ImageSource kaynak) async {
    final XFile? secilen = await _picker.pickImage(
      source: kaynak,
      imageQuality: 90,
    );
    if (secilen == null) return;

    final klasorYolu = await _fotografKlasoru;
    final dosyaAdi = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final hedef = File(p.join(klasorYolu, dosyaAdi));
    await File(secilen.path).copy(hedef.path);

    await _fotograflariYukle();
  }

  void _kaynakSec() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _BottomSheetButon(
              ikon: Icons.camera_alt_rounded,
              etiket: 'Kamera',
              onTap: () {
                Navigator.pop(context);
                _fotografEkle(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _BottomSheetButon(
              ikon: Icons.photo_library_rounded,
              etiket: 'Galeri',
              onTap: () {
                Navigator.pop(context);
                _fotografEkle(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _secilenlerSil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${_secilenler.length} fotoğraf silinsin mi?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (onay != true) return;

    for (final i in _secilenler) {
      await _fotograflar[i].delete();
    }

    setState(() {
      _secimModu = false;
      _secilenler = {};
    });
    await _fotograflariYukle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xFF0A0A0A),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _secimModu
                    ? '${_secilenler.length} seçildi'
                    : 'Galeri',
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              if (_secimModu) ...[
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent),
                  onPressed: _secilenlerSil,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() {
                    _secimModu = false;
                    _secilenler = {};
                  }),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${_fotograflar.length} fotoğraf',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 13),
                  ),
                ),
            ],
          ),
          if (_fotograflar.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_outlined,
                        size: 80, color: Colors.white12),
                    const SizedBox(height: 16),
                    const Text(
                      'Henüz fotoğraf yok',
                      style:
                          TextStyle(color: Colors.white24, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Eklemek için + butonuna bas',
                      style:
                          TextStyle(color: Colors.white12, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(4),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _FotografKart(
                    dosya: _fotograflar[i],
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
                            builder: (_) => FotografDetay(
                              fotograflar: _fotograflar,
                              baslangicIndex: i,
                            ),
                          ),
                        );
                      }
                    },
                    onLongPress: () {
                      setState(() {
                        _secimModu = true;
                        _secilenler.add(i);
                      });
                    },
                  ),
                  childCount: _fotograflar.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _secimModu
          ? null
          : FloatingActionButton(
              onPressed: _kaynakSec,
              backgroundColor: const Color(0xFFE0FF4F),
              foregroundColor: Colors.black,
              elevation: 8,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 32),
            ),
    );
  }
}

class _FotografKart extends StatelessWidget {
  final File dosya;
  final bool secili;
  final bool secimModu;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FotografKart({
    required this.dosya,
    required this.secili,
    required this.secimModu,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            dosya,
            fit: BoxFit.cover,
            cacheWidth: 300,
          ),
          if (secimModu)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: secili
                    ? const Color(0xFFE0FF4F).withOpacity(0.4)
                    : Colors.black.withOpacity(0.3),
              ),
            ),
          if (secimModu)
            Positioned(
              top: 6,
              right: 6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      secili ? const Color(0xFFE0FF4F) : Colors.transparent,
                  border: Border.all(
                    color: secili
                        ? const Color(0xFFE0FF4F)
                        : Colors.white,
                    width: 2,
                  ),
                ),
                child: secili
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.black)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomSheetButon extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final VoidCallback onTap;

  const _BottomSheetButon({
    required this.ikon,
    required this.etiket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(ikon, color: const Color(0xFFE0FF4F), size: 24),
            const SizedBox(width: 16),
            Text(etiket,
                style:
                    const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// ── Fotoğraf Detay / Tam Ekran Görüntüleyici ──────────────────────────────

class FotografDetay extends StatefulWidget {
  final List<File> fotograflar;
  final int baslangicIndex;

  const FotografDetay({
    super.key,
    required this.fotograflar,
    required this.baslangicIndex,
  });

  @override
  State<FotografDetay> createState() => _FotografDetayState();
}

class _FotografDetayState extends State<FotografDetay> {
  late PageController _ctrl;
  late int _mevcut;

  @override
  void initState() {
    super.initState();
    _mevcut = widget.baslangicIndex;
    _ctrl = PageController(initialPage: _mevcut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${_mevcut + 1} / ${widget.fotograflar.length}',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.fotograflar.length,
        onPageChanged: (i) => setState(() => _mevcut = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Center(
            child: Image.file(widget.fotograflar[i]),
          ),
        ),
      ),
    );
  }
}
