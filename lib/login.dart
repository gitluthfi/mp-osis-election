import 'package:election_flutter_app/admin/admin_dashboard.dart';
import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/countdown.dart';
import 'package:election_flutter_app/contract/login_contract.dart';
import 'package:election_flutter_app/model/Login.dart' as LoginModel;
import 'package:election_flutter_app/presenter/login_presenter.dart';
import 'package:election_flutter_app/post.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LoginScreen();
  }
}

class LoginScreen extends State<Login> implements LoginContractView {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  late LoginPresenter loginPresenter;
  bool isLoading = false;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    loginPresenter = LoginPresenter(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColor().blueColor,
              Color(0xff524CFF),
            ],
          ),
        ),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.white,
                ),
              )
            : ListView(
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          verticalTitle(),
                          textLogin(),
                        ],
                      ),
                      inputEmail(),
                      inputPassword(),
                      buttonLogin(),
                      firstTime(),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  verticalTitle() {
    return Padding(
      padding: EdgeInsets.only(top: 60, left: 10),
      child: RotatedBox(
        quarterTurns: -1,
        child: Text(
          "Sign In",
          style: TextStyle(
              color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  textLogin() {
    return Padding(
      padding: EdgeInsets.only(top: 50, left: 10),
      child: Container(
        height: 200,
        width: 200,
        child: Column(
          children: [
            Container(
              height: 60,
            ),
            Center(
              child: Text(
                "Student Council \nSTARBHAK Election",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  inputEmail() {
    return Padding(
      padding: EdgeInsets.only(top: 50, left: 50, right: 50),
      child: Container(
        height: 60,
        width: MediaQuery.of(context).size.width,
        child: TextFormField(
          controller: emailController,
          style: TextStyle(
            color: Colors.white,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            fillColor: Colors.lightBlueAccent,
            labelText: "Username",
            labelStyle: TextStyle(
              color: Colors.white70,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  inputPassword() {
    return Padding(
      padding: EdgeInsets.only(top: 20, left: 50, right: 50),
      child: Container(
        height: 60,
        width: MediaQuery.of(context).size.width,
        child: TextField(
          controller: passwordController,
          style: TextStyle(
            color: Colors.white,
          ),
          obscureText: true,
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: 'Password',
            labelStyle: TextStyle(
              color: Colors.white70,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  buttonLogin() {
    return Padding(
      padding: EdgeInsets.only(top: 50, right: 50, left: 200),
      child: Container(
        alignment: Alignment.bottomRight,
        height: 50,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColor().blueColor,
            minimumSize: Size(double.infinity, 50),
          ),
          onPressed: () {
            if (emailController.text.trim().length > 0 &&
                passwordController.text.trim().length > 0) {
              setState(() {
                isLoading = true;
                isError = false;
              });
              loginPresenter.loadLoginData(
                  emailController.text.trim(), passwordController.text.trim());
            } else if (emailController.text.trim().length == 0) {
              errorAlert("Empty Email", "Please fill email field");
            } else if (passwordController.text.trim().length == 0) {
              errorAlert("Empty Password", "Please fill password field");
            } else if (emailController.text.trim().length == 0 &&
                passwordController.text.trim().length == 0) {
              errorAlert(
                  "Empty Field", "Make sure you fill all the field required");
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Sign In",
                style: TextStyle(
                  color: AppColor().blueColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(
                width: 5,
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColor().blueColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  firstTime() {
    return Padding(
      padding: EdgeInsets.only(
        top: 30,
        left: 30,
      ),
      child: Container(
        alignment: Alignment.topRight,
        height: 20,
        child: Row(
          children: [
            Text(
              "Not have account yet?",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                "Register now.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  setLoginData(LoginModel.Login loginData) async {
    if (loginData.status == 'success') {
      final user = loginData.data![0];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("nik",      user.nik_voter      ?? '');
      await prefs.setString("password", user.password_voter ?? '');
      await prefs.setString("id",       user.id_voter       ?? '');
      await prefs.setString("role",     user.role           ?? 'voter');
      setState(() => isLoading = false);

      if (user.role == 'admin') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => AdminDashboard(nik: user.nik_voter ?? '')));
        return;
      }

      if (user.ischosen == '1') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => Post()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => Countdown()));
      }
    } else if (loginData.status == 'failed') {
      setState(() { isError = true; isLoading = false; });
      errorAlert("Login Gagal", loginData.message ?? 'Login failed');
    } else {
      setState(() { isError = true; isLoading = false; });
      errorAlert("Data tidak ditemukan", "Periksa koneksi internet Anda");
    }
  }

  @override
  onErrorLogin(error) {
    setState(() {
      isError = true;
      isLoading = false;
    });
    print(error);
    errorAlert("Data not found", "Check your connection");
  }

  errorAlert(String title, String subtitle) {
    return Alert(
      context: context,
      title: title,
      desc: subtitle,
      type: AlertType.warning,
      buttons: [
        DialogButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "OK",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ],
      style: AlertStyle(
        animationType: AnimationType.grow,
        isCloseButton: false,
        isOverlayTapDismiss: false,
        descStyle: TextStyle(fontWeight: FontWeight.bold),
        descTextAlign: TextAlign.start,
        animationDuration: Duration(milliseconds: 400),
        alertBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: Colors.grey,
          ),
        ),
        titleStyle: TextStyle(
          color: Colors.red,
        ),
        alertAlignment: Alignment.center,
      ),
    ).show();
  }
}
