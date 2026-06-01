import 'dart:convert';
import 'dart:io';

import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/model/DataCandidate.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

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
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
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
    } catch (e) {
      _showSnack('Gagal memuat kandidat: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteCandidate(DataCandidate c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kandidat'),
        content: Text('Hapus ${c.candidateName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final resp = await http.delete(
          Uri.parse('${UrlConst().domain}Candidate/Delete/${c.idCandidate}'));
      final body = json.decode(resp.body);
      _showSnack(body['status'] == 'success' ? 'Kandidat dihapus' : body['message']);
      if (body['status'] == 'success') _loadCandidates();
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: AppColor().blueColor,
        foregroundColor: Colors.white,
        title: const Text('Kelola Kandidat'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColor().blueColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const _AddEditCandidateScreen()),
          );
          _loadCandidates();
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCandidates,
              child: _candidates.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _candidates.length,
                      itemBuilder: (_, i) => _candidateCard(_candidates[i]),
                    ),
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        const Text('Belum ada kandidat',
            style: TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Tap tombol + untuk menambahkan kandidat',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    );
  }

  Widget _candidateCard(DataCandidate c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          // ── foto ────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 70,
              height: 70,
              child: c.candidatePhoto != null
                  ? Image.network(c.candidatePhoto!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder())
                  : _photoPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          // ── info ─────────────────────────────────────────────────
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColor().blueColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('No. ${c.candidateId}',
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(c.candidateName ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              if (c.description != null && c.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(c.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ),
            ]),
          ),
          // ── actions ──────────────────────────────────────────────
          Column(children: [
            IconButton(
              icon: Icon(Icons.edit, color: AppColor().blueColor),
              tooltip: 'Edit',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => _AddEditCandidateScreen(candidate: c)),
                );
                _loadCandidates();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Hapus',
              onPressed: () => _deleteCandidate(c),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, color: Colors.grey, size: 36),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Add / Edit form
// ══════════════════════════════════════════════════════════════════════════════

class _AddEditCandidateScreen extends StatefulWidget {
  final DataCandidate? candidate;
  const _AddEditCandidateScreen({this.candidate});

  @override
  State<_AddEditCandidateScreen> createState() => _AddEditCandidateScreenState();
}

class _AddEditCandidateScreenState extends State<_AddEditCandidateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;

  // Simpan XFile agar bisa baca bytes + mimeType secara eksplisit
  XFile? _pickedXFile;
  File?  _pickedImage;   // hanya untuk preview Image.file()
  bool _saving = false;
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
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked != null) {
      setState(() {
        _pickedXFile  = picked;
        _pickedImage  = File(picked.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final uri = _isEdit
          ? Uri.parse('${UrlConst().domain}Candidate/Update/${widget.candidate!.idCandidate}')
          : Uri.parse('${UrlConst().domain}Candidate/Add');

      final request = http.MultipartRequest('POST', uri)
        ..fields['candidate_id']   = _idCtrl.text.trim()
        ..fields['candidate_name'] = _nameCtrl.text.trim()
        ..fields['description']    = _descCtrl.text.trim();

      if (_pickedXFile != null) {
        // Baca bytes agar tidak bergantung pada filesystem path Android
        final bytes    = await _pickedXFile!.readAsBytes();
        final mimeType = _pickedXFile!.mimeType ?? 'image/jpeg';
        final mimeParts = mimeType.split('/');
        final subtype   = mimeParts.length > 1 ? mimeParts[1] : 'jpeg';

        // Tentukan nama file berdasarkan subtype agar ekstensi selalu ada
        final filename = 'photo_${DateTime.now().millisecondsSinceEpoch}.$subtype';

        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename:    filename,
          contentType: MediaType(mimeParts[0], subtype),
        ));
        debugPrint('[Upload] Sending photo: $filename, mime: $mimeType, ${bytes.length} bytes');
      }

      final streamed = await request.send();
      final resp     = await http.Response.fromStream(streamed);
      debugPrint('[Upload] Response ${resp.statusCode}: ${resp.body}');

      Map<String, dynamic> body;
      try {
        body = json.decode(resp.body);
      } catch (_) {
        throw Exception('Response tidak valid (${resp.statusCode}): ${resp.body}');
      }

      if (!mounted) return;
      // Capture messenger SEBELUM pop agar context tidak invalid
      final messenger = ScaffoldMessenger.of(context);
      if (body['status'] == 'success') {
        Navigator.of(context).pop(true);
        messenger.showSnackBar(SnackBar(
            content: Text(_isEdit ? 'Kandidat diperbarui' : 'Kandidat ditambahkan')));
      } else {
        messenger.showSnackBar(
            SnackBar(content: Text(body['message'] ?? 'Gagal menyimpan')));
      }
    } catch (e) {
      debugPrint('[Upload] Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: AppColor().blueColor,
        foregroundColor: Colors.white,
        title: Text(_isEdit ? 'Edit Kandidat' : 'Tambah Kandidat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── foto picker ───────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(alignment: Alignment.bottomRight, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: _pickedImage != null
                          ? Image.file(_pickedImage!, fit: BoxFit.cover)
                          : (widget.candidate?.candidatePhoto != null
                              ? Image.network(widget.candidate!.candidatePhoto!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _placeholder())
                              : _placeholder()),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: AppColor().blueColor,
                        shape: BoxShape.circle),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text('Tap foto untuk ganti gambar',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            const SizedBox(height: 24),
            // ── form fields ──────────────────────────────────────────
            _label('Nomor Urut Kandidat'),
            _field(
              controller: _idCtrl,
              hint: 'Contoh: 1',
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Nomor urut tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            _label('Nama Kandidat'),
            _field(
              controller: _nameCtrl,
              hint: 'Nama lengkap kandidat',
              validator: (v) =>
                  v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            _label('Deskripsi / Visi Misi'),
            _field(
              controller: _descCtrl,
              hint: 'Deskripsi singkat kandidat...',
              maxLines: 4,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_saving
                    ? 'Menyimpan...'
                    : (_isEdit ? 'Simpan Perubahan' : 'Tambah Kandidat')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor().blueColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.person, color: Colors.grey, size: 60),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      );

  Widget _field({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColor().blueColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
