import 'package:confetti/confetti.dart';
import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';

class Countdown extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => CountdownScreen();
}

class CountdownScreen extends State<Countdown> {
  final int estimateTs = DateTime(2020, 10, 20, 20, 50, 00).millisecondsSinceEpoch;
  bool isDone = false;
  late ConfettiController _controllerCenter;

  @override
  void initState() {
    super.initState();
    _controllerCenter = ConfettiController(duration: const Duration(seconds: 10));

    // Jika waktu sudah lewat, langsung set done setelah frame pertama selesai
    if (DateTime.now().millisecondsSinceEpoch >= estimateTs) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => isDone = true);
          _controllerCenter.play();
        }
      });
    }
  }

  @override
  void dispose() {
    _controllerCenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColor().blueColor, const Color(0xff524CFF)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: isDone ? _endWidget() : _countdownWidget(),
      ),
    );
  }

  Widget _countdownWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Icon(Icons.how_to_vote, color: AppColor().whiteColor, size: 60),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Text(
            "Countdown to Election Day",
            style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        CountdownTimer(
          endTime: estimateTs,
          onEnd: () {
            // Gunakan addPostFrameCallback agar setState tidak dipanggil saat build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => isDone = true);
                _controllerCenter.play();
              }
            });
          },
          widgetBuilder: (context, remainingTime) {
            if (remainingTime == null) return _tapToStartButton();
            final parts = <Widget>[];
            if (remainingTime.days  != null) parts.add(Text("${remainingTime.days}d",  style: const TextStyle(fontSize: 35, color: Colors.white54)));
            if (remainingTime.hours != null) parts.add(Text("${remainingTime.hours}h", style: const TextStyle(fontSize: 40, color: Colors.white60)));
            if (remainingTime.min   != null) parts.add(Text("${remainingTime.min}m",   style: const TextStyle(fontSize: 45, color: Colors.white70)));
            if (remainingTime.sec   != null) parts.add(Text("${remainingTime.sec}s",   style: const TextStyle(fontSize: 50, color: Colors.white)));
            return Row(mainAxisAlignment: MainAxisAlignment.center, children: parts);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 30, left: 30, right: 30),
          child: Text(
            "Election day will be held on Thursday, 28th October 2020 at 8 am",
            style: const TextStyle(fontSize: 20, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // _endWidget tidak memanggil play() — sudah dipanggil dari initState / onEnd
  Widget _endWidget() {
    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _controllerCenter,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: true,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Icon(Icons.how_to_vote, color: AppColor().whiteColor, size: 60),
            ),
            Text(
              "Countdown Finished",
              style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w700),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 30, right: 30),
              child: Text(
                "Today is the day to choose the leader of your choice",
                style: const TextStyle(fontSize: 20, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColor().whiteColor,
                  foregroundColor: AppColor().blueColor,
                  padding: const EdgeInsets.all(15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => Home())),
                child: Text(
                  "Vote Now!",
                  style: TextStyle(color: AppColor().blueColor, fontSize: 24),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tapToStartButton() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(width: 2, color: AppColor().whiteColor),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
        padding: const EdgeInsets.all(15),
        foregroundColor: AppColor().whiteColor,
      ),
      onPressed: () {
        setState(() => isDone = true);
        _controllerCenter.play();
      },
      child: Text("Tap to Start", style: TextStyle(color: AppColor().whiteColor, fontSize: 20)),
    );
  }
}
