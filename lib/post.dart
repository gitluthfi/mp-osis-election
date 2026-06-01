import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/contract/logout_contract.dart';
import 'package:election_flutter_app/login.dart';
import 'package:election_flutter_app/model/Logout.dart';
import 'package:election_flutter_app/presenter/logout_presenter.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Post extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PostScreen();
  }
}

class PostScreen extends State<Post> implements LogoutContractView {
  late LogoutPresenter logoutPresenter;
  SharedPreferences? preferences;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    logoutPresenter = LogoutPresenter(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor().blueColor,
      body: Center(
        child: isLoading
            ? CircularProgressIndicator(backgroundColor: Colors.white)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/check_success.png",
                    alignment: Alignment.center,
                    width: 150,
                    height: 150,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 10),
                    child: Text(
                      "Congratulations",
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    "Thank you for voting and not abstaining\nYour Vote Matters",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          width: 2,
                          color: AppColor().whiteColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        padding: EdgeInsets.all(15),
                        foregroundColor: AppColor().whiteColor,
                      ),
                      child: Text(
                        "Logout",
                        style: TextStyle(
                          color: AppColor().whiteColor,
                          fontSize: 20,
                        ),
                      ),
                      onPressed: () {
                        Alert(
                          context: context,
                          title: "Logout",
                          desc: "Are you sure to logout?",
                          type: AlertType.info,
                          buttons: [
                            DialogButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Cancel",
                                style:
                                    TextStyle(color: Colors.white, fontSize: 20),
                              ),
                              color: Colors.grey,
                            ),
                            DialogButton(
                              onPressed: () async {
                                setState(() {
                                  isLoading = true;
                                });
                                preferences =
                                    await SharedPreferences.getInstance();
                                logoutPresenter.loadLogoutData(
                                    preferences!.get("nik").toString(),
                                    preferences!.get("password").toString());
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Confirm",
                                style:
                                    TextStyle(color: Colors.white, fontSize: 20),
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
                              color: AppColor().blueColor,
                            ),
                            alertAlignment: Alignment.center,
                          ),
                        ).show();
                      },
                    ),
                  )
                ],
              ),
      ),
    );
  }

  @override
  setLogoutData(Logout logout) async {
    if (logout.status == "success") {
      await preferences?.clear();
      setState(() {
        isLoading = false;
      });
      return Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => Login()));
    } else {
      setState(() {
        isLoading = false;
      });
      errorAlert("Failed", "Check your connection");
    }
  }

  @override
  setOnErrorLogout(error) {
    print(error.toString());
    setState(() {
      isLoading = false;
    });
    errorAlert("Failed", "Check your connection");
  }

  errorAlert(title, subtitle) {
    return Alert(
      context: context,
      title: title.toString(),
      desc: subtitle.toString(),
      type: AlertType.warning,
      buttons: [
        DialogButton(
          onPressed: () {
            Navigator.pop(context);
          },
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
