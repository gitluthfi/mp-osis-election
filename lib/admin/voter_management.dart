import 'dart:convert';
import 'dart:io';

import 'package:election_flutter_app/constants.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class VoterManagement extends StatefulWidget {
  const VoterManagement({Key? key}) : super(key: key);

  @override
  State<VoterManagement> createState() => _VoterManagementState();
}

class _VoterManagementState extends State<VoterManagement> {
  bool _downloading = false;
  bool _importing = false;

  Future<void> _downloadTemplate() async {
    setState(() => _downloading = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Voter'];
      excel.delete('Sheet1');

      sheet.appendRow([
        TextCellValue('NIK/NISN'),
        TextCellValue('Kelas'),
        TextCellValue('Password'),
      ]);
      sheet.appendRow([
        TextCellValue('1234567890'),
        TextCellValue('X-IPA-1'),
        TextCellValue('password123'),
      ]);

      final bytes = excel.encode()!;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/template_voter.xlsx');
      await file.writeAsBytes(bytes, flush: true);

      await OpenFilex.open(file.path);
    } catch (e) {
      _showSnack('Gagal membuat template: $e', false);
    }
    if (mounted) setState(() => _downloading = false);
  }

  Future<void> _importExcel() async {
    XFile? xFile;
    try {
      const typeGroup = XTypeGroup(
        label: 'Excel',
        extensions: ['xlsx', 'xls'],
      );
      xFile = await openFile(acceptedTypeGroups: [typeGroup]);
    } catch (e) {
      _showSnack('Tidak dapat membuka file picker: $e', false);
      return;
    }

    if (xFile == null) return;

    setState(() => _importing = true);
    try {
      final bytes = await xFile.readAsBytes();
      final workbook = Excel.decodeBytes(bytes);

      final List<Map<String, String>> voters = [];
      for (final tableName in workbook.tables.keys) {
        final sheet = workbook.tables[tableName]!;
        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.length < 3) continue;
          final nik = _cellStr(row[0]).trim();
          final kelas = _cellStr(row[1]).trim();
          final password = _cellStr(row[2]).trim();
          if (nik.isEmpty || kelas.isEmpty || password.isEmpty) continue;
          voters.add({'nik': nik, 'code_voter': kelas, 'password': password});
        }
        break; // only first sheet
      }

      if (voters.isEmpty) {
        _showSnack('Tidak ada data valid yang ditemukan dalam file', false);
        setState(() => _importing = false);
        return;
      }

      final confirmed = await _showPreviewDialog(voters);
      if (!confirmed || !mounted) {
        setState(() => _importing = false);
        return;
      }

      final resp = await http.post(
        Uri.parse('${UrlConst().domain}Voter/ImportBulk'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'voters': voters}),
      );

      Map<String, dynamic> body;
      try {
        body = json.decode(resp.body);
      } on FormatException {
        _showSnack(
          'Server error (HTTP ${resp.statusCode}): endpoint Voter/ImportBulk belum tersedia di backend',
          false,
        );
        setState(() => _importing = false);
        return;
      }

      _showSnack(
        body['message'] ?? (body['status'] == 'success' ? 'Berhasil diimpor' : 'Gagal mengimpor'),
        body['status'] == 'success',
      );
    } catch (e) {
      _showSnack('Gagal terhubung ke server', false);
    }
    if (mounted) setState(() => _importing = false);
  }

  String _cellStr(Data? cell) {
    if (cell == null || cell.value == null) return '';
    final v = cell.value!;
    if (v is TextCellValue) return v.value.toString();
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return v.value.toString();
    return v.toString();
  }

  Future<bool> _showPreviewDialog(List<Map<String, String>> voters) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
            title: Text(
              'Preview Data (${voters.length} voter)',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                            child: Text('NIK/NISN',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: AppTheme.textDark))),
                        Expanded(
                            child: Text('Kelas',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: AppTheme.textDark))),
                        Expanded(
                            child: Text('Password',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: AppTheme.textDark))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: voters.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(voters[i]['nik']!,
                                    style: const TextStyle(fontSize: 12))),
                            Expanded(
                                child: Text(voters[i]['code_voter']!,
                                    style: const TextStyle(fontSize: 12))),
                            Expanded(
                                child: Text(
                                    '•' * voters[i]['password']!.length.clamp(4, 8),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMid))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal',
                    style: TextStyle(color: AppTheme.textMid)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Import',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Kelola Data Voter'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Template Excel'),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.info_outline_rounded,
              text:
                  'Download template Excel, isi data voter (NIK/NISN, Kelas, Password), lalu import kembali ke aplikasi.',
            ),
            const SizedBox(height: 16),
            _actionCard(
              icon: Icons.download_rounded,
              color: AppTheme.success,
              bgColor: const Color(0xFFE0FAF3),
              title: 'Download Template',
              subtitle: 'Download file .xlsx kosong sebagai panduan pengisian',
              loading: _downloading,
              onTap: _downloading ? null : _downloadTemplate,
            ),
            const SizedBox(height: 28),
            _sectionLabel('Import Data Voter'),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.table_chart_rounded,
              text:
                  'Kolom: A = NIK/NISN, B = Kelas (code_voter), C = Password. Baris pertama adalah header dan akan dilewati.',
            ),
            const SizedBox(height: 16),
            _actionCard(
              icon: Icons.upload_file_rounded,
              color: AppTheme.primary,
              bgColor: const Color(0xFFEDE7FF),
              title: 'Import dari Excel',
              subtitle: 'Pilih file .xlsx untuk diimport ke sistem',
              loading: _importing,
              onTap: _importing ? null : _importExcel,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(children: [
      Container(
        width: 4,
        height: 18,
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

  Widget _infoCard({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Icon(icon, color: AppTheme.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textMid, height: 1.5))),
      ]),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String subtitle,
    required bool loading,
    required VoidCallback? onTap,
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
              color: bgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: loading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: color),
                  )
                : Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMid)),
                ]),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: onTap != null ? AppTheme.primary : AppTheme.textLight,
            ),
          ),
        ]),
      ),
    );
  }
}
