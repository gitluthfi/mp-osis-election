import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:election_flutter_app/admin/admin_dashboard.dart';
import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/contract/check_contract.dart';
import 'package:election_flutter_app/countdown.dart';
import 'package:election_flutter_app/login.dart';
import 'package:election_flutter_app/model/Check.dart';
import 'package:election_flutter_app/post.dart';
import 'package:election_flutter_app/presenter/check_presenter.dart';
import 'package:flutter/material.dart';

class Launcher extends StatefulWidget {
  const Launcher({this.nik, this.password});
  final String? nik;
  final String? password;

  @override
  State<StatefulWidget> createState() => LauncherScreen();
}

class LauncherScreen extends State<Launcher> implements CheckViewContract {
  late CheckPresenter _checkPresenter;

  @override
  void initState() {
    super.initState();
    _checkPresenter = CheckPresenter(this);
    if (widget.nik != null && widget.password != null) {
      _checkPresenter.loadData(widget.nik!, widget.password!);
    } else {
      startLaunching();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColor().blueColor, const Color(0xff524CFF)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/vote_illustration.png", width: 200, height: 200),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedTextKit(
                  animatedTexts: [
                    RotateAnimatedText('Select Your',
                        textStyle: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColor().whiteColor),
                        textAlign: TextAlign.center),
                    RotateAnimatedText('Future Leader',
                        textStyle: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColor().whiteColor),
                        textAlign: TextAlign.center),
                  ],
                  totalRepeatCount: 5,
                  pause: const Duration(seconds: 1),
                  displayFullTextOnTap: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void startLaunching() {
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Login()));
    });
  }

  @override
  onErrorCheckData(error) {
    print(error);
    startLaunching();
  }

  @override
  onSuccessCheckData(Check check) {
    if (check.status != 'success' || check.data == null || check.data!.isEmpty) {
      startLaunching();
      return;
    }

    final user = check.data![0];
    final delay = const Duration(seconds: 2);

    // ─── Admin ────────────────────────────────────────────────────────────
    if (user.role == 'admin') {
      return Timer(delay, () {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => AdminDashboard(nik: user.nik_voter ?? '')));
      });
    }

    // ─── Voter ────────────────────────────────────────────────────────────
    if (user.islogin == '1') {
      if (user.ischosen == '1') {
        return Timer(delay, () {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => Post()));
        });
      } else {
        return Timer(delay, () {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => Countdown()));
        });
      }
    }

    startLaunching();
  }
}
