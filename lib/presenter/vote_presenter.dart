import 'dart:convert';

import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/contract/vote_contract.dart';
import 'package:election_flutter_app/model/Vote.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VotePresenter implements VoteContractPresenter {
  late VoteContractView _voteContractView;

  VotePresenter(this._voteContractView);

  @override
  Future<Vote> getVoteData(String id) async {
    final url = Uri.parse("${UrlConst().domain}Vote");
    Client client = Client();
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String nik = preferences.get("nik").toString();
    String voterId = preferences.get("id").toString();
    var response = await client.post(
        url, body: {"nik": nik, "voter_id": voterId, "candidate_id": id});
    var jsonResponse = json.decode(response.body);
    return Vote.fromJson(jsonResponse);
  }

  @override
  loadVoteData(String id) {
    getVoteData(id)
        .then((value) => _voteContractView.setVoteData(value))
        .catchError((error) => _voteContractView.onErrorVote(error));
  }
}
