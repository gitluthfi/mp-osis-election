import 'dart:convert';
import 'dart:io';

import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/model/DataCandidate.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Candidate Management List
// ══════════════════════════════════════════════════════════════════════════════

class CandidateManagement extends StatefulWidget {
  const CandidateManagement({Key? key}) : super(key: key);

  @override
  State<CandidateManagement> createState() => _CandidateManagementState();
}

class _CandidateManagementState extends State<CandidateManagement> {
  List<DataCandidate> _candidates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await http.get(Uri.parse('${UrlConst().domain}Candidate'));
      final body = json.decode(resp.body);
      if (body['status'] == 'success') {
        setState(() {
          _candidates = (body['data'] as List)
              .map((e) => DataCandidate.fromJson(e))
              .toList();
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(DataCandidate c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Hapus Kandidat',
        message: 'Hapus ${c.candidateName}? Tindakan ini tidak bisa dibatalkan.',
        confirmLabel: 'Hapus',
        confirmColor: AppTheme.error,
      ),
    );
    if (ok != true) return;

    try {
      final resp = await http.delete(
          Uri.parse('${UrlConst().domain}Candidate/Delete/${c.idCandidate}'));
      final body = json.decode(resp.body);
      _showSnack(
        body['status'] == 'success' ? 'Kandidat berhasil dihapus' : (body['message'] ?? 'Gagal'),
        body['status'] == 'success',
      );
      if (body['status'] == 'success') _load();
    } catch (_) {
      _showSnack('Tidak dapat terhubung ke server', false);
    }
  }

  void _showSnack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        title: const Text('Kelola Kandidat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 6,
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const _CandidateForm()));
          _load();
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _load,
              child: _candidates.isEmpty ? _emptyState() : _list(),
            ),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 2),
            ),
            child: Icon(Icons.people_outline_rounded,
                size: 48, color: AppTheme.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          const Text('Belum ada kandidat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          const SizedBox(height: 6),
          const Text('Tap tombol + untuk menambahkan',
              style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
        ]),
      ],
    );
  }

  Widget _list() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _candidates.length,
      itemBuilder: (_, i) => _candidateCard(_candidates[i], i),
    );
  }

  Widget _candidateCard(DataCandidate c, int i) {
    final accentColors = [AppTheme.primary, AppTheme.accent, AppTheme.success, AppTheme.warning];
    final color = accentColors[i % accentColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(children: [
        // Photo
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusLarge),
            bottomLeft: Radius.circular(AppTheme.radiusLarge),
          ),
          child: SizedBox(
            width: 90, height: 110,
            child: c.candidatePhoto != null
                ? Image.network(c.candidatePhoto!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(color))
                : _placeholder(color),
          ),
        ),
        // Info
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'No. ${c.candidateId}',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: color),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                c.candidateName ?? '-',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              if (c.description != null && c.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  c.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMid, height: 1.4),
                ),
              ],
            ]),
          ),
        ),
        // Actions
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _actionBtn(Icons.edit_rounded, AppTheme.primary, () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => _CandidateForm(candidate: c)));
              _load();
            }),
            const SizedBox(height: 4),
            _actionBtn(Icons.delete_rounded, AppTheme.error, () => _delete(c)),
          ]),
        ),
      ]),
    );
  }

  Widget _placeholder(Color color) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Center(child: Icon(Icons.person_rounded, color: color.withValues(alpha: 0.4), size: 40)),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Add / Edit Form
// ══════════════════════════════════════════════════════════════════════════════

class _CandidateForm extends StatefulWidget {
  final DataCandidate? candidate;
  const _CandidateForm({this.candidate});

  @override
  State<_CandidateForm> createState() => _CandidateFormState();
}

class _CandidateFormState extends State<_CandidateForm> {
  final _formKey  = GlobalKey<FormState>();
  late TextEditingController _idCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;

  XFile? _pickedXFile;
  File?  _pickedImage;
  bool   _saving = false;

  bool get _isEdit => widget.candidate != null;

  @override
  void initState() {
    super.initState();
    final c = widget.candidate;
    _idCtrl   = TextEditingController(text: c?.candidateId   ?? '');
    _nameCtrl = TextEditingController(text: c?.candidateName ?? '');
    _descCtrl = TextEditingController(text: c?.description   ?? '');
  }

  @override
  void dispose() {
    _idCtrl.dispose(); _nameCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked != null) {
      setState(() { _pickedXFile = picked; _pickedImage = File(picked.path); });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final uri = _isEdit
          ? Uri.parse('${UrlConst().domain}Candidate/Update/${widget.candidate!.idCandidate}')
          : Uri.parse('${UrlConst().domain}Candidate/Add');

      final req = http.MultipartRequest('POST', uri)
        ..fields['candidate_id']   = _idCtrl.text.trim()
        ..fields['candidate_name'] = _nameCtrl.text.trim()
        ..fields['description']    = _descCtrl.text.trim();

      if (_pickedXFile != null) {
        final bytes    = await _pickedXFile!.readAsBytes();
        final mime     = _pickedXFile!.mimeType ?? 'image/jpeg';
        final parts    = mime.split('/');
        final subtype  = parts.length > 1 ? parts[1] : 'jpeg';
        req.files.add(http.MultipartFile.fromBytes(
          'photo', bytes,
          filename: 'photo_${DateTime.now().millisecondsSinceEpoch}.$subtype',
          contentType: MediaType(parts[0], subtype),
        ));
      }

      final streamed = await req.send();
      final resp     = await http.Response.fromStream(streamed);

      Map<String, dynamic> body;
      try {
        body = json.decode(resp.body);
      } catch (_) {
        throw Exception('Response tidak valid (${resp.statusCode})');
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (body['status'] == 'success') {
        Navigator.of(context).pop(true);
        messenger.showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Kandidat berhasil diperbarui' : 'Kandidat berhasil ditambahkan'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(body['message'] ?? 'Gagal menyimpan'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_isEdit ? 'Edit Kandidat' : 'Tambah Kandidat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _photoPicker(),
            const SizedBox(height: 24),
            _card(children: [
              _label('Nomor Urut Kandidat'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _idCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.tag_rounded, color: AppTheme.primary, size: 20),
                  hintText: 'Contoh: 1',
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Nomor urut wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _label('Nama Lengkap Kandidat'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_rounded, color: AppTheme.primary, size: 20),
                  hintText: 'Masukkan nama lengkap',
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _label('Visi & Misi / Deskripsi'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 64),
                    child: Icon(Icons.description_rounded, color: AppTheme.primary, size: 20),
                  ),
                  hintText: 'Tuliskan visi, misi, atau deskripsi singkat…',
                  alignLabelWithHint: true,
                ),
              ),
            ]),
            const SizedBox(height: 24),
            GradientButton(
              label: _isEdit ? 'Simpan Perubahan' : 'Tambah Kandidat',
              icon: _isEdit ? Icons.save_rounded : Icons.add_rounded,
              onPressed: _saving ? null : _save,
              loading: _saving,
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _photoPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(
            color: _pickedImage != null
                ? AppTheme.primary.withValues(alpha: 0.4)
                : AppTheme.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Stack(fit: StackFit.expand, children: [
            // Preview
            if (_pickedImage != null)
              Image.file(_pickedImage!, fit: BoxFit.cover)
            else if (widget.candidate?.candidatePhoto != null)
              Image.network(widget.candidate!.candidatePhoto!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _photoEmptyState())
            else
              _photoEmptyState(),
            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12, left: 0, right: 0,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.camera_alt_rounded, color: AppTheme.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _pickedImage != null ? 'Ganti Foto' : 'Pilih Foto',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                    ),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _photoEmptyState() {
    return Container(
      color: AppTheme.bgLight,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_rounded,
            size: 48, color: AppTheme.primary.withValues(alpha: 0.4)),
        const SizedBox(height: 8),
        Text(
          'Ketuk untuk memilih foto kandidat',
          style: TextStyle(
              fontSize: 13, color: AppTheme.textMid.withValues(alpha: 0.8)),
        ),
      ]),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// Reusable confirm dialog
// ══════════════════════════════════════════════════════════════════════════════

class _ConfirmDialog extends StatelessWidget {
  final String title, message, confirmLabel;
  final Color confirmColor;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      title: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
              color: AppTheme.textDark)),
      content: Text(message,
          style: const TextStyle(fontSize: 14, color: AppTheme.textMid, height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal',
              style: TextStyle(color: AppTheme.textMid, fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
