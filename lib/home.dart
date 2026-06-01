import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/contract/info_candidate_contract.dart';
import 'package:election_flutter_app/contract/vote_contract.dart';
import 'package:election_flutter_app/model/DataCandidate.dart';
import 'package:election_flutter_app/model/Vote.dart';
import 'package:election_flutter_app/post.dart';
import 'package:election_flutter_app/presenter/info_candidate_presenter.dart';
import 'package:election_flutter_app/presenter/vote_presenter.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomeScreen();
}

class HomeScreen extends State<Home>
    with TickerProviderStateMixin
    implements InfoCandidateContractView, VoteContractView {
  late InfoCandidatePresenter infoCandidatePresenter;
  late VotePresenter votePresenter;

  List<DataCandidate> candidates = [];
  int index = 0;
  String chosenId = "1";
  bool showDesc = false;
  bool isPostVote = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    infoCandidatePresenter = InfoCandidatePresenter(this);
    votePresenter = VotePresenter(this);
    infoCandidatePresenter.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColor().blueColor,
        child: isPostVote
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _body(),
      ),
    );
  }

  Widget _body() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColor().blueColor,
      child: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _cardArea()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: RotatedBox(
            quarterTurns: -1,
            child: Text("VOTE",
                style: TextStyle(
                    color: AppColor().whiteColor,
                    fontSize: 38,
                    fontWeight: FontWeight.w900)),
          ),
        ),
        Expanded(
          child: Text(
            "Your choices determine\nthe future of your school",
            style: TextStyle(color: AppColor().whiteColor, fontSize: 24),
          ),
        ),
      ]),
    );
  }

  Widget _cardArea() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor().whiteColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(children: [
        Expanded(
          child: PageView.builder(
            itemCount: candidates.length,
            controller: PageController(viewportFraction: 0.8),
            onPageChanged: _onPageChanged,
            itemBuilder: _cardBuilder,
          ),
        ),
        _voteButton(),
      ]),
    );
  }

  Widget _cardBuilder(BuildContext context, int i) {
    final c = candidates[i];
    return Transform.scale(
      scale: i == index ? 1 : 0.9,
      child: Card(
        shadowColor: Colors.black54,
        elevation: 10,
        color: AppColor().blueColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(children: [
          // ── foto ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox.expand(
              child: c.candidatePhoto != null
                  ? Image.network(
                      c.candidatePhoto!,
                      fit: BoxFit.cover,
                      loadingBuilder: _loadingBuilder,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(),
                    )
                  : _photoPlaceholder(),
            ),
          ),
          // ── info bawah ────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColor().blueColor.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, -10),
                  )
                ],
              ),
              child: TextButton(
                onPressed: () => setState(() => showDesc = !showDesc),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "No. ${c.candidateId} — ${c.candidateName ?? ''}",
                        style: TextStyle(
                            color: AppColor().whiteColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      if (showDesc && c.description != null && c.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(c.description!,
                              style: TextStyle(
                                  color: AppColor().whiteColor, fontSize: 14)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: AppColor().blueColor.withOpacity(0.3),
      child: Center(
        child: Icon(Icons.person, size: 100, color: Colors.white54),
      ),
    );
  }

  Widget _loadingBuilder(BuildContext ctx, Widget child, ImageChunkEvent? progress) {
    if (progress == null) return child;
    return Center(
      child: CircularProgressIndicator(
        value: progress.expectedTotalBytes != null
            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
            : null,
        color: Colors.white,
        strokeWidth: 1,
      ),
    );
  }

  Widget _voteButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor().blueColor,
          foregroundColor: AppColor().whiteColor,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _showVoteConfirm,
        child: Text("Vote kandidat nomor $chosenId",
            style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  void _showVoteConfirm() {
    Alert(
      context: context,
      title: "Vote",
      desc: "Yakin memilih kandidat nomor $chosenId?",
      type: AlertType.info,
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          color: Colors.grey,
          child: const Text("Batal", style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
        DialogButton(
          onPressed: () {
            setState(() => isPostVote = true);
            votePresenter.loadVoteData(chosenId);
            Navigator.pop(context);
          },
          child: const Text("Konfirmasi", style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ],
      style: _alertStyle(AppColor().blueColor),
    ).show();
  }

  void _onPageChanged(int value) {
    setState(() {
      index = value;
      chosenId = candidates[value].candidateId ?? "1";
      showDesc = false;
    });
  }

  // ── Contract implementations ──────────────────────────────────────────────

  @override
  setInfoCandidate(List<DataCandidate> value) {
    setState(() {
      candidates = value;
      if (value.isNotEmpty) chosenId = value[0].candidateId ?? "1";
      isLoading = false;
    });
  }

  @override
  setOnErrorInfoCandidate(String error) {
    setState(() => isLoading = false);
    print("Candidate load error: $error");
  }

  @override
  onErrorVote(error) {
    setState(() => isPostVote = false);
    _errorAlert("Gagal", "Akses ditolak");
  }

  @override
  setVoteData(Vote vote) {
    if (vote.status == "success") {
      setState(() => isPostVote = false);
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Post()));
    } else {
      setState(() => isPostVote = false);
      final msg = vote.status == "failed" && vote.message == "User already choosing"
          ? "Anda sudah pernah memilih"
          : "Periksa koneksi internet Anda";
      _errorAlert("Gagal", msg);
    }
  }

  void _errorAlert(String title, String subtitle) {
    Alert(
      context: context,
      title: title,
      desc: subtitle,
      type: AlertType.warning,
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK", style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ],
      style: _alertStyle(Colors.red),
    ).show();
  }

  AlertStyle _alertStyle(Color titleColor) => AlertStyle(
        animationType: AnimationType.grow,
        isCloseButton: false,
        isOverlayTapDismiss: false,
        descStyle: const TextStyle(fontWeight: FontWeight.bold),
        animationDuration: const Duration(milliseconds: 400),
        alertBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.grey)),
        titleStyle: TextStyle(color: titleColor),
        alertAlignment: Alignment.center,
      );
}
