import 'package:election_flutter_app/model/DataCandidate.dart';

abstract class InfoCandidateContractPresenter {
  getInfoCandidate() {}
  loadData() {}
}

abstract class InfoCandidateContractView {
  setInfoCandidate(List<DataCandidate> value) {}
  setOnErrorInfoCandidate(String error) {}
}
