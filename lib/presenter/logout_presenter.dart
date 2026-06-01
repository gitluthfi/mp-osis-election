import 'dart:convert';

import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/contract/logout_contract.dart';
import 'package:election_flutter_app/model/Logout.dart';
import 'package:http/http.dart';

class LogoutPresenter implements LogoutContractPresenter {
  late LogoutContractView _logoutContractView;

  LogoutPresenter(this._logoutContractView);

  @override
  Future<Logout> getLogoutData(String nik, String password) async {
    final url = Uri.parse("${UrlConst().domain}Logout");
    Client client = Client();
    var response = await client.post(
      url,
      body: {
        "nik": nik,
        "password": password,
      },
    );
    var json = jsonDecode(response.body);
    return Logout.fromJson(json);
  }

  @override
  loadLogoutData(String nik, String password) {
    getLogoutData(nik, password)
        .then((value) => _logoutContractView.setLogoutData(value))
        .catchError((err) => _logoutContractView.setOnErrorLogout(err));
  }
}
