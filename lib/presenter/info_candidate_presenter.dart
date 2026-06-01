import 'dart:convert';

import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/contract/info_candidate_contract.dart';
import 'package:election_flutter_app/model/Candidate.dart';
import 'package:election_flutter_app/model/DataCandidate.dart';
import 'package:http/http.dart';

class InfoCandidatePresenter implements InfoCandidateContractPresenter {
  late InfoCandidateContractView _view;

  InfoCandidatePresenter(this._view);

  @override
  Future<List<DataCandidate>> getInfoCandidate() async {
    final url = Uri.parse("${UrlConst().domain}Candidate");
    final response = await Client().get(url);
    final content = json.decode(response.body);
    return Candidate.fromJson(content).data ?? [];
  }

  @override
  loadData() {
    getInfoCandidate()
        .then((value) => _view.setInfoCandidate(value))
        .catchError((error) => _view.setOnErrorInfoCandidate(error.toString()));
  }
}
