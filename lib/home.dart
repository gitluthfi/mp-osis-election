import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/contract/info_candidate_contract.dart';
import 'package:election_flutter_app/contract/vote_contract.dart';
import 'package:election_flutter_app/model/DataCandidate.dart';
import 'package:election_flutter_app/model/Vote.dart';
import 'package:election_flutter_app/post.dart';
import 'package:election_flutter_app/presenter/info_candidate_presenter.dart';
import 'package:election_flutter_app/presenter/vote_presenter.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with TickerProviderStateMixin
    implements InfoCandidateContractView, VoteContractView {

  late InfoCandidatePresenter _candidatePresenter;
  late VotePresenter _votePresenter;
  late PageController _pageCtrl;

  List<DataCandidate> _candidates = [];
  int _index     = 0;
  String _chosen = '1';
  bool _loading  = true;
  bool _voting   = false;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.88);
    _candidatePresenter = InfoCandidatePresenter(this);
    _votePresenter      = VotePresenter(this);
    _candidatePresenter.loadData();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: _loading
          ? _loadingView()
          : _voting
              ? _votingProgress()
              : _mainContent(),
    );
  }

  Widget _loadingView() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.softGradient),
      child: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text('Memuat data kandidat…',
              style: TextStyle(color: Colors.white, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _votingProgress() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.softGradient),
      child: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text('Sedang mengirim suara Anda…',
              style: TextStyle(color: Colors.white, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _mainContent() {
    return Stack(
      children: [
        // Gradient header band
        Container(height: 180, decoration: const BoxDecoration(gradient: AppTheme.softGradient)),
        // Content
        SafeArea(
          child: Column(children: [
            _appBar(),
            Expanded(child: _cardArea()),
            _voteButton(),
            const SizedBox(height: 20),
          ]),
        ),
      ],
    );
  }

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Pemilihan Ketua OSIS',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Pilih Kandidat Anda',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.people_outline, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              '${_candidates.length} kandidat',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _cardArea() {
    return Column(children: [
      Expanded(
        child: PageView.builder(
          controller: _pageCtrl,
          itemCount: _candidates.length,
          onPageChanged: (i) {
            setState(() {
              _index  = i;
              _chosen = _candidates[i].candidateId ?? '1';
            });
          },
          itemBuilder: _buildCard,
        ),
      ),
      const SizedBox(height: 16),
      _pageIndicator(),
    ]);
  }

  Widget _buildCard(BuildContext ctx, int i) {
    final c     = _candidates[i];
    final scale = i == _index ? 1.0 : 0.92;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: scale, end: scale),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: _candidateCard(c, i),
    );
  }

  Widget _candidateCard(DataCandidate c, int i) {
    final active = i == _index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: active
            ? [BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              )]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Stack(fit: StackFit.expand, children: [
          // Photo
          c.candidatePhoto != null
              ? Image.network(c.candidatePhoto!, fit: BoxFit.cover,
                  loadingBuilder: _imgLoading,
                  errorBuilder: (_, __, ___) => _photoPlaceholder())
              : _photoPlaceholder(),

          // Gradient overlay — bottom
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Info overlay — bottom
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Kandidat No. ${c.candidateId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.candidateName ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                    ),
                  ),
                  if (c.description != null && c.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      c.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Swipe hint badge — top right
          Positioned(
            top: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.swipe_rounded, color: Colors.white.withValues(alpha: 0.9), size: 13),
                const SizedBox(width: 5),
                Text(
                  'Geser',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withValues(alpha: 0.4),
            AppTheme.primaryDark.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.person_rounded, size: 100, color: Colors.white54),
      ),
    );
  }

  Widget _imgLoading(BuildContext ctx, Widget child, ImageChunkEvent? progress) {
    if (progress == null) return child;
    return Container(
      color: AppTheme.primaryLight.withValues(alpha: 0.1),
      child: Center(
        child: CircularProgressIndicator(
          value: progress.expectedTotalBytes != null
              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
              : null,
          color: AppTheme.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _pageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_candidates.length, (i) {
        final active = i == _index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width:  active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _voteButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: GradientButton(
        label: 'Pilih Kandidat No. $_chosen',
        icon: Icons.how_to_vote_rounded,
        onPressed: _showConfirm,
      ),
    );
  }

  void _showConfirm() {
    final c = _candidates.isNotEmpty ? _candidates[_index] : null;
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.how_to_vote_rounded, color: AppTheme.primary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Konfirmasi Pilihan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda akan memilih kandidat nomor $_chosen\n${c?.candidateName ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppTheme.textMid, height: 1.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pilihan tidak dapat diubah setelah dikonfirmasi.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMid),
                ),
              ),
            ]),
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
                label: 'Konfirmasi',
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _voting = true);
                  _votePresenter.loadVoteData(_chosen);
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
  setInfoCandidate(List<DataCandidate> value) {
    setState(() {
      _candidates = value;
      if (value.isNotEmpty) _chosen = value[0].candidateId ?? '1';
      _loading = false;
    });
  }

  @override
  setOnErrorInfoCandidate(String error) {
    setState(() => _loading = false);
  }

  @override
  onErrorVote(error) {
    setState(() => _voting = false);
    _showError('Gagal memilih', 'Akses ditolak. Coba lagi.');
  }

  @override
  setVoteData(Vote vote) {
    if (vote.status == 'success') {
      setState(() => _voting = false);
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => Post()));
    } else {
      setState(() => _voting = false);
      final msg = vote.message == 'User already choosing'
          ? 'Anda sudah pernah menggunakan hak pilih.'
          : 'Periksa koneksi internet Anda.';
      _showError('Gagal Memilih', msg);
    }
  }

  void _showError(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: Row(children: [
          Icon(Icons.error_rounded, color: AppTheme.error, size: 24),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: Text(msg, style: const TextStyle(color: AppTheme.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(
              color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
