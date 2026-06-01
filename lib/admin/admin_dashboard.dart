import 'dart:convert';

import 'package:election_flutter_app/admin/candidate_management.dart';
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

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = true;
  int _totalVoters = 0;
  int _totalVoted = 0;
  int _totalUnvoted = 0;
  List<_CandidateResult> _results = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final resp = await http.get(Uri.parse('${UrlConst().domain}Dashboard'));
      final body = json.decode(resp.body);
      if (body['status'] == 'success') {
        final d = body['data'];
        final raw = (d['vote_results'] as List)
            .map((e) => _CandidateResult(
                  name:  e['candidate_name'] as String,
                  count: (e['vote_count'] as num).toInt(),
                ))
            .toList();
        setState(() {
          _totalVoters  = (d['total_voters']  as num).toInt();
          _totalVoted   = (d['total_voted']   as num).toInt();
          _totalUnvoted = (d['total_unvoted'] as num).toInt();
          _results = raw;
        });
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final nik  = prefs.getString('nik')      ?? '';
    final pass = prefs.getString('password') ?? '';
    await http.post(
      Uri.parse('${UrlConst().domain}Logout'),
      body: {'nik': nik, 'password': pass},
    );
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => Login()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: AppColor().blueColor,
        foregroundColor: Colors.white,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle('Statistik Pemilihan'),
                  const SizedBox(height: 8),
                  _statsRow(),
                  const SizedBox(height: 24),
                  _sectionTitle('Hasil Suara'),
                  const SizedBox(height: 8),
                  _voteResults(),
                  const SizedBox(height: 24),
                  _sectionTitle('Manajemen'),
                  const SizedBox(height: 8),
                  _menuCard(
                    icon: Icons.people_alt,
                    label: 'Kelola Kandidat',
                    subtitle: 'Tambah, edit, atau hapus kandidat',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CandidateManagement()),
                      );
                      _loadDashboard();
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColor().blueColor),
      );

  Widget _statsRow() {
    return Row(children: [
      Expanded(child: _statCard('Total Pemilih', _totalVoters, Icons.people, Colors.blue)),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Sudah Memilih', _totalVoted, Icons.check_circle, Colors.green)),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Belum Memilih', _totalUnvoted, Icons.pending, Colors.orange)),
    ]);
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text('$value',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ]),
      ),
    );
  }

  Widget _voteResults() {
    if (_results.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Belum ada kandidat')),
        ),
      );
    }
    final maxVotes = _results.fold<int>(0, (m, r) => r.count > m ? r.count : m);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _results.map((r) => _resultBar(r, maxVotes)).toList(),
        ),
      ),
    );
  }

  Widget _resultBar(_CandidateResult r, int maxVotes) {
    final ratio = maxVotes == 0 ? 0.0 : r.count / maxVotes;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(r.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text('${r.count} suara',
              style: TextStyle(color: AppColor().blueColor, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppColor().blueColor),
          ),
        ),
      ]),
    );
  }

  Widget _menuCard(
      {required IconData icon,
      required String label,
      required String subtitle,
      required VoidCallback onTap}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColor().blueColor,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _CandidateResult {
  final String name;
  final int count;
  _CandidateResult({required this.name, required this.count});
}
