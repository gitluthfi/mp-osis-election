import 'dart:convert';

import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/contract/login_contract.dart';
import 'package:election_flutter_app/model/Login.dart';
import 'package:http/http.dart';

class LoginPresenter implements LoginContractPresenter {
  late LoginContractView _loginContractView;

  LoginPresenter(this._loginContractView);

  @override
  loadLoginData(String email, String password) {
    getLoginData(email, password)
        .then((value) => _loginContractView.setLoginData(value))
        .catchError((err) => _loginContractView.onErrorLogin(err));
  }

  @override
  Future<Login> getLoginData(String email, String password) async {
    final url = Uri.parse("${UrlConst().domain}Login");
    Map<String, String> body = {
      "nik": email,
      "password": password,
    };
    Client client = Client();
    final response = await client.post(url, body: body);
    if (response.statusCode != 200) {
      print("Response is not Success");
    }
    var content = json.decode(response.body);
    return Login.fromJson(content);
  }
}
