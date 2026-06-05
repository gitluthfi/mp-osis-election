import 'package:election_flutter_app/admin/admin_dashboard.dart';
import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/countdown.dart';
import 'package:election_flutter_app/contract/login_contract.dart';
import 'package:election_flutter_app/model/Login.dart' as LoginModel;
import 'package:election_flutter_app/presenter/login_presenter.dart';
import 'package:election_flutter_app/post.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LoginScreen();
}

class LoginScreen extends State<Login> implements LoginContractView {
  final _nikCtrl      = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late LoginPresenter _presenter;

  bool _loading    = false;
  bool _obscure    = true;
  bool _hasError   = false;

  @override
  void initState() {
    super.initState();
    _presenter = LoginPresenter(this);
  }

  @override
  void dispose() {
    _nikCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.softGradient),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(child: _formCard()),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
            ),
            child: const Icon(Icons.how_to_vote_rounded, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'STARBHAK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Student Council Election',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Form Card ────────────────────────────────────────────────────────────

  Widget _formCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat Datang 👋',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Masuk menggunakan NIK dan password Anda',
              style: TextStyle(fontSize: 14, color: AppTheme.textMid),
            ),
            const SizedBox(height: 32),

            // NIK field
            _fieldLabel('NIK / Username'),
            const SizedBox(height: 8),
            TextField(
              controller: _nikCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.primary, size: 20),
                hintText: 'Masukkan NIK Anda',
                hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 14),
              ),
            ),
            const SizedBox(height: 18),

            // Password field
            _fieldLabel('Password'),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w500),
              onSubmitted: (_) => _doLogin(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary, size: 20),
                hintText: 'Masukkan password Anda',
                hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 14),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.textMid,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Login button
            GradientButton(
              label: 'Masuk',
              icon: Icons.arrow_forward_rounded,
              onPressed: _loading ? null : _doLogin,
              loading: _loading,
            ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                'STARBHAK Election App v1.0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
          letterSpacing: 0.3,
        ),
      );

  // ─── Logic ────────────────────────────────────────────────────────────────

  void _doLogin() {
    final nik  = _nikCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();

    if (nik.isEmpty) {
      _showSnack('NIK tidak boleh kosong');
      return;
    }
    if (pass.isEmpty) {
      _showSnack('Password tidak boleh kosong');
      return;
    }

    setState(() { _loading = true; _hasError = false; });
    _presenter.loadLoginData(nik, pass);
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

  @override
  setLoginData(LoginModel.Login loginData) async {
    if (loginData.status == 'success') {
      final user  = loginData.data![0];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nik',      user.nik_voter      ?? '');
      await prefs.setString('password', user.password_voter ?? '');
      await prefs.setString('id',       user.id_voter       ?? '');
      await prefs.setString('role',     user.role           ?? 'voter');
      if (!mounted) return;
      setState(() => _loading = false);

      if (user.role == 'admin') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => AdminDashboard(nik: user.nik_voter ?? '')));
        return;
      }
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => user.ischosen == '1' ? Post() : Countdown()));
    } else {
      if (!mounted) return;
      setState(() { _loading = false; _hasError = true; });
      _showSnack(loginData.message ?? 'NIK atau password salah');
    }
  }

  @override
  onErrorLogin(error) {
    if (!mounted) return;
    setState(() { _loading = false; _hasError = true; });
    _showSnack('Tidak dapat terhubung ke server');
  }
}
