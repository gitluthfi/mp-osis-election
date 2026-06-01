import 'dart:convert';

import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/contract/check_contract.dart';
import 'package:election_flutter_app/model/Check.dart';
import 'package:http/http.dart';

class CheckPresenter implements CheckPresenterContract {
  late CheckViewContract _checkViewContract;

  CheckPresenter(this._checkViewContract);

  @override
  Future<Check> getCheckData(String nik, String password) async {
    final url = Uri.parse("${UrlConst().domain}Check");
    Map<String, String> body = {
      "nik": nik,
      "password": password,
    };
    Client client = Client();
    final response = await client.post(url, body: body);
    if (response.statusCode != 200) {
      print("Response is not Success");
    }
    var content = json.decode(response.body);
    return Check.fromJson(content);
  }

  @override
  loadData(String nik, String password) {
    getCheckData(nik, password)
        .then((value) => _checkViewContract.onSuccessCheckData(value))
        .catchError((error) => _checkViewContract.onErrorCheckData(error));
  }
}
