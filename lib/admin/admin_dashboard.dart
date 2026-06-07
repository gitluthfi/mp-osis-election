import 'dart:convert';

import 'package:election_flutter_app/admin/candidate_management.dart';
import 'package:election_flutter_app/admin/voter_management.dart';
import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboard extends StatefulWidget {
  final String nik;
  const AdminDashboard({required this.nik});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {

  bool   _loading       = true;
  int    _totalVoters   = 0;
  int    _totalVoted    = 0;
  int    _totalUnvoted  = 0;
  List<_VoteResult> _results = [];

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await http.get(Uri.parse('${UrlConst().domain}Dashboard'));
      final d = json.decode(resp.body)['data'];
      setState(() {
        _totalVoters  = (d['total_voters']  as num).toInt();
        _totalVoted   = (d['total_voted']   as num).toInt();
        _totalUnvoted = (d['total_unvoted'] as num).toInt();
        _results = (d['vote_results'] as List)
            .map((e) => _VoteResult(
                  name:  e['candidate_name'] as String,
                  count: (e['vote_count'] as num).toInt(),
                ))
            .toList();
      });
      _fadeCtrl.forward(from: 0);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await http.post(
      Uri.parse('${UrlConst().domain}Logout'),
      body: {'nik': prefs.getString('nik') ?? '', 'password': prefs.getString('password') ?? ''},
    );
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => Login()), (_) => false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          _sliverAppBar(),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeTransition(opacity: _fadeAnim, child: _content()),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primary,
      automaticallyImplyLeading: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
            label: const Text('Keluar', style: TextStyle(color: Colors.white, fontSize: 13)),
            onPressed: _logout,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Halo, ${widget.nik} 👋',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      )),
                  const Text('Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      )),
                ]),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('Statistik Pemilihan'),
      const SizedBox(height: 12),
      _statsRow(),
      const SizedBox(height: 28),
      if (_totalVoters > 0) ...[
        _sectionLabel('Partisipasi Pemilih'),
        const SizedBox(height: 12),
        _participationBar(),
        const SizedBox(height: 28),
      ],
      _sectionLabel('Perolehan Suara'),
      const SizedBox(height: 12),
      _voteResults(),
      const SizedBox(height: 28),
      _sectionLabel('Manajemen'),
      const SizedBox(height: 12),
      _menuCard(),
      const SizedBox(height: 20),
    ]);
  }

  Widget _sectionLabel(String text) {
    return Row(children: [
      Container(
        width: 4, height: 18,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppTheme.textDark,
          letterSpacing: 0.2,
        ),
      ),
    ]);
  }

  Widget _statsRow() {
    return Row(children: [
      Expanded(child: _statCard('Total Pemilih', _totalVoters,
          Icons.people_alt_rounded, AppTheme.primary, const Color(0xFFEDE7FF))),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Sudah Memilih', _totalVoted,
          Icons.check_circle_rounded, AppTheme.success, const Color(0xFFE0FAF3))),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Belum Memilih', _totalUnvoted,
          Icons.pending_rounded, AppTheme.warning, const Color(0xFFFFF3E0))),
    ]);
  }

  Widget _statCard(String label, int value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: AppTheme.textMid, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }

  Widget _participationBar() {
    final pct = _totalVoters > 0 ? _totalVoted / _totalVoters : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tingkat Partisipasi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(pct * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: AppTheme.bgLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$_totalVoted dari $_totalVoters pemilih telah menggunakan hak pilihnya',
          style: const TextStyle(fontSize: 12, color: AppTheme.textMid),
        ),
      ]),
    );
  }

  Widget _voteResults() {
    if (_results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardShadow,
        ),
        child: const Center(
          child: Text('Belum ada kandidat',
              style: TextStyle(color: AppTheme.textMid, fontSize: 14)),
        ),
      );
    }
    final maxVotes = _results.fold<int>(0, (m, r) => r.count > m ? r.count : m);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: _results.asMap().entries.map((e) {
          final colors = [AppTheme.primary, AppTheme.accent, AppTheme.success, AppTheme.warning];
          return _resultRow(e.value, maxVotes, colors[e.key % colors.length]);
        }).toList(),
      ),
    );
  }

  Widget _resultRow(_VoteResult r, int maxVotes, Color color) {
    final ratio = maxVotes == 0 ? 0.0 : r.count / maxVotes;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(r.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${r.count} suara',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: ratio),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (_, v, __) => ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: AppTheme.bgLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _menuCard() {
    return Column(children: [
      _menuItem(
        icon: Icons.manage_accounts_rounded,
        gradient: AppTheme.primaryGradient,
        title: 'Kelola Kandidat',
        subtitle: 'Tambah, edit, atau hapus kandidat',
        onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CandidateManagement()));
          _load();
        },
      ),
      const SizedBox(height: 10),
      _menuItem(
        icon: Icons.people_alt_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF00C48C), Color(0xFF00916E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        title: 'Kelola Data Voter',
        subtitle: 'Download template & import data voter via Excel',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const VoterManagement())),
      ),
    ]);
  }

  Widget _menuItem({
    required IconData icon,
    required Gradient gradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppTheme.primary),
          ),
        ]),
      ),
    );
  }
}

class _VoteResult {
  final String name;
  final int count;
  _VoteResult({required this.name, required this.count});
}
