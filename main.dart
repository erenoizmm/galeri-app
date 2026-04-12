import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AskerApp());
}

class AskerApp extends StatelessWidget {
  const AskerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Askerlik Sayacı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        fontFamily: 'Courier',
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF4CAF50),
          surface: const Color(0xFF111111),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ── SPLASH ──────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
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
      backgroundColor: const Color(0xFF0A0A0A),
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('☆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                'ASKERLİK\nSAYACI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4CAF50),
                  letterSpacing: 8,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'VAT. ER',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white24,
                  letterSpacing: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── HOME ─────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  // Kayıtlı tarihler yoksa seçim ekranına, varsa sayaç ekranına git
  @override
  Widget build(BuildContext context) {
    if (_startDate == null || _endDate == null) {
      return DateSetupScreen(
        onDatesSet: (start, end) {
          setState(() {
            _startDate = start;
            _endDate = end;
          });
        },
      );
    }
    return CountdownScreen(
      startDate: _startDate!,
      endDate: _endDate!,
      onReset: () {
        setState(() {
          _startDate = null;
          _endDate = null;
        });
      },
    );
  }
}

// ── DATE SETUP ───────────────────────────────────────────────────────────────

class DateSetupScreen extends StatefulWidget {
  final void Function(DateTime start, DateTime end) onDatesSet;

  const DateSetupScreen({super.key, required this.onDatesSet});

  @override
  State<DateSetupScreen> createState() => _DateSetupScreenState();
}

class _DateSetupScreenState extends State<DateSetupScreen> {
  DateTime? _start;
  DateTime? _end;

  Future<void> _pick(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4CAF50),
            onPrimary: Colors.black,
            surface: Color(0xFF1A1A1A),
          ),
          dialogBackgroundColor: const Color(0xFF1A1A1A),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '-- / -- / ----';
    return '${d.day.toString().padLeft(2, '0')} / '
        '${d.month.toString().padLeft(2, '0')} / '
        '${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final canSave =
        _start != null && _end != null && _end!.isAfter(_start!);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TARİHLERİ\nGİR',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                  letterSpacing: 4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Göreve başlama ve terhis tarihini seç.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
              const Spacer(),
              _DateTile(
                label: 'GÖREVE BAŞLAMA',
                value: _fmt(_start),
                onTap: () => _pick(true),
              ),
              const SizedBox(height: 20),
              _DateTile(
                label: 'TERHİS TARİHİ',
                value: _fmt(_end),
                onTap: () => _pick(false),
              ),
              const Spacer(),
              GestureDetector(
                onTap: canSave
                    ? () => widget.onDatesSet(_start!, _end!)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: canSave
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: canSave
                          ? const Color(0xFF4CAF50)
                          : Colors.white12,
                    ),
                  ),
                  child: Text(
                    'SAYACI BAŞLAT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: canSave ? Colors.black : Colors.white24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTile(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── COUNTDOWN ────────────────────────────────────────────────────────────────

class CountdownScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onReset;

  const CountdownScreen({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onReset,
  });

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Toplam askerlik süresi (gün)
  int get _totalDays =>
      widget.endDate.difference(widget.startDate).inDays;

  // Kalan gün
  int get _remainingDays {
    final diff = widget.endDate.difference(_now).inDays;
    return diff < 0 ? 0 : diff;
  }

  // Geçen gün
  int get _passedDays {
    final diff = _now.difference(widget.startDate).inDays;
    return diff < 0 ? 0 : (diff > _totalDays ? _totalDays : diff);
  }

  // İlerleme yüzdesi
  double get _progress {
    if (_totalDays == 0) return 1.0;
    return (_passedDays / _totalDays).clamp(0.0, 1.0);
  }

  bool get _terhisOldu => _now.isAfter(widget.endDate);

  // Kalan saat/dakika/saniye
  Duration get _remainingDuration {
    final diff = widget.endDate.difference(_now);
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  Widget build(BuildContext context) {
    final dur = _remainingDuration;
    final hours = dur.inHours.remainder(24).toString().padLeft(2, '0');
    final mins = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = dur.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '☆ ASKERLİK',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showResetDialog(context),
                    child: const Text(
                      'SIFIRLA',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              if (_terhisOldu) ...[
                const Center(
                  child: Column(
                    children: [
                      Text('🎖️',
                          style: TextStyle(fontSize: 72)),
                      SizedBox(height: 20),
                      Text(
                        'TERHİS!',
                        style: TextStyle(
                          fontSize: 48,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Hayırlı olsun askerim.',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Kalan gün – büyük numara
                Text(
                  _remainingDays.toString(),
                  style: const TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                    height: 1,
                    letterSpacing: -4,
                  ),
                ),
                const Text(
                  'GÜN KALDI',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white38,
                    letterSpacing: 5,
                  ),
                ),

                const SizedBox(height: 32),

                // Saat:dakika:saniye
                Row(
                  children: [
                    _TimeBox(value: hours, label: 'SAAT'),
                    const _Colon(),
                    _TimeBox(value: mins, label: 'DAK'),
                    const _Colon(),
                    _TimeBox(value: secs, label: 'SAN'),
                  ],
                ),

                const SizedBox(height: 40),

                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_passedDays GÜN GEÇTİ',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          '%${(_progress * 100).toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFF1E1E1E),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF4CAF50)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'TOPLAM $_totalDays GÜN',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Tarih bilgileri
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        label: 'GÖREVE BAŞLAMA',
                        value: _fmtDate(widget.startDate),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        label: 'TERHİS TARİHİ',
                        value: _fmtDate(widget.endDate),
                        accent: true,
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              // Alt slogan
              Center(
                child: Text(
                  '"Vatan sağolsun."',
                  style: TextStyle(
                    color: Colors.white12,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Sıfırla?',
            style: TextStyle(color: Colors.white, letterSpacing: 2)),
        content: const Text(
          'Tarihleri sıfırlamak ve yeniden girmek istediğine emin misin?',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL',
                style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onReset();
            },
            child: const Text('SIFIRLA',
                style: TextStyle(color: Color(0xFF4CAF50))),
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String value;
  final String label;

  const _TimeBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white24,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14, left: 6, right: 6),
      child: Text(
        ':',
        style: TextStyle(
            fontSize: 28, color: Colors.white24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;

  const _InfoCard(
      {required this.label, required this.value, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(
            color: accent
                ? const Color(0xFF4CAF50).withOpacity(0.4)
                : Colors.white12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white24,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accent ? const Color(0xFF4CAF50) : Colors.white60,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
