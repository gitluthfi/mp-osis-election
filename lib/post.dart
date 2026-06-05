import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/contract/logout_contract.dart';
import 'package:election_flutter_app/login.dart';
import 'package:election_flutter_app/model/Logout.dart';
import 'package:election_flutter_app/presenter/logout_presenter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Post extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PostState();
}

class _PostState extends State<Post>
    with TickerProviderStateMixin
    implements LogoutContractView {

  late LogoutPresenter _presenter;
  late AnimationController _scaleCtrl;
  late AnimationController _slideCtrl;
  late Animation<double>   _scaleAnim;
  late Animation<Offset>   _slideAnim;

  SharedPreferences? _prefs;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _presenter = LogoutPresenter(this);

    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) { _scaleCtrl.forward(); _slideCtrl.forward(); }
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // Background gradient
        Container(decoration: const BoxDecoration(gradient: AppTheme.softGradient)),

        // Decorative circles
        Positioned(top: -60, right: -60,
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        Positioned(bottom: -80, left: -40,
          child: Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),

        // Main content
        SafeArea(
          child: _loading ? _loadingView() : _successView(),
        ),
      ]),
    );
  }

  Widget _loadingView() => const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      );

  Widget _successView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnim,
            child: _checkIcon(),
          ),
          const SizedBox(height: 32),
          SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _slideCtrl,
              child: _textContent(),
            ),
          ),
          const SizedBox(height: 48),
          SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _slideCtrl,
              child: _logoutButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withValues(alpha: 0.35),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.check_circle_rounded,
        color: AppTheme.success,
        size: 72,
      ),
    );
  }

  Widget _textContent() {
    return Column(children: [
      const Text(
        'Suara Anda\nTelah Dicatat!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'Terima kasih telah berpartisipasi dalam\nproses demokrasi sekolah kita.\nSetiap suara sangat berarti. 🗳️',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          color: Colors.white.withValues(alpha: 0.85),
          height: 1.6,
        ),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_rounded, color: Colors.white.withValues(alpha: 0.85), size: 16),
          const SizedBox(width: 8),
          Text(
            'Suara Anda bersifat rahasia',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        icon: _loading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
        label: Text(
          _loading ? 'Keluar…' : 'Keluar dari Aplikasi',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
          foregroundColor: Colors.white,
        ),
        onPressed: _loading ? null : _confirmLogout,
      ),
    );
  }

  void _confirmLogout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Icon(Icons.logout_rounded, color: AppTheme.primary, size: 36),
          const SizedBox(height: 12),
          const Text('Keluar?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          const Text(
            'Sesi Anda akan diakhiri. Anda perlu\nlogin kembali untuk mengakses aplikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textMid, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textMid,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientButton(
                label: 'Ya, Keluar',
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _loading = true);
                  _prefs = await SharedPreferences.getInstance();
                  _presenter.loadLogoutData(
                    _prefs!.get('nik').toString(),
                    _prefs!.get('password').toString(),
                  );
                },
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ─── Contracts ────────────────────────────────────────────────────────────

  @override
  setLogoutData(Logout logout) async {
    if (logout.status == 'success') {
      await _prefs?.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => Login()), (_) => false);
    } else {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack('Gagal keluar. Coba lagi.');
    }
  }

  @override
  setOnErrorLogout(error) {
    if (!mounted) return;
    setState(() => _loading = false);
    _showSnack('Tidak dapat terhubung ke server.');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}
