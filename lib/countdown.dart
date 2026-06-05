import 'package:confetti/confetti.dart';
import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';

class Countdown extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> with TickerProviderStateMixin {
  final int _endTs = DateTime(2020, 10, 20, 20, 50).millisecondsSinceEpoch;
  bool _done = false;
  late ConfettiController _confetti;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 12));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    if (DateTime.now().millisecondsSinceEpoch >= _endTs) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { setState(() => _done = true); _confetti.play(); }
      });
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.softGradient),
          ),
          // Content
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: _done ? _doneScreen() : _countingScreen(),
            ),
          ),
          // Confetti
          if (_done)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 30,
                colors: const [
                  Colors.white, Color(0xFFFFD700), Color(0xFF00E5FF),
                  Color(0xFFFF6584), Color(0xFFB2FF59),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Counting screen ──────────────────────────────────────────────────────

  Widget _countingScreen() {
    return Column(
      children: [
        const SizedBox(height: 24),
        _topIcon(),
        const SizedBox(height: 20),
        _title(),
        const SizedBox(height: 40),
        CountdownTimer(
          endTime: _endTs,
          onEnd: () => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) { setState(() => _done = true); _confetti.play(); }
          }),
          widgetBuilder: (_, time) {
            if (time == null) return _tapToStart();
            return _timerBoxes(time.days, time.hours, time.min, time.sec);
          },
        ),
        const Spacer(),
        _dateNote(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _topIcon() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      child: const Icon(Icons.how_to_vote_rounded, color: Colors.white, size: 40),
    );
  }

  Widget _title() {
    return Column(children: [
      const Text(
        'HARI PEMILIHAN',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 4,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Ketua OSIS 2020',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    ]);
  }

  Widget _timerBoxes(int? days, int? hours, int? min, int? sec) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (days  != null) ...[_box('$days',    'hari'),  _sep()],
          if (hours != null) ...[_box(_pad(hours), 'jam'),  _sep()],
          if (min   != null) ...[_box(_pad(min),   'menit'), _sep()],
          if (sec   != null)   _box(_pad(sec),   'detik'),
        ],
      ),
    );
  }

  Widget _box(String value, String label) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.75),
            letterSpacing: 0.5,
          ),
        ),
      ]),
    );
  }

  Widget _sep() => Padding(
        padding: const EdgeInsets.only(bottom: 18, left: 6, right: 6),
        child: Text(
          ':',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      );

  Widget _dateNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, color: Colors.white.withValues(alpha: 0.8), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pemilihan dilaksanakan pada\nRabu, 28 Oktober 2020 pukul 08.00 WIB',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tapToStart() {
    return GestureDetector(
      onTap: () { setState(() => _done = true); _confetti.play(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'Ketuk untuk Mulai',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ─── Done screen ──────────────────────────────────────────────────────────

  Widget _doneScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _doneIcon(),
        const SizedBox(height: 24),
        const Text(
          'Hari Pemilihan Tiba!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Gunakan hak pilih Anda dan tentukan\npemimpin terbaik untuk sekolah kita.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: GradientButton(
            label: 'Mulai Memilih',
            icon: Icons.how_to_vote_rounded,
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => Home())),
          ),
        ),
      ],
    );
  }

  Widget _doneIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
      ),
      child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 56),
    );
  }

  String _pad(int? v) => (v ?? 0).toString().padLeft(2, '0');
}
