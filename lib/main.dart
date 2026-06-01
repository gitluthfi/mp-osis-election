import 'package:election_flutter_app/launcher.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  var nik = preferences.get("nik");
  var pw  = preferences.get("password");
  runApp(MyApp(
    nik:      nik?.toString(),
    password: pw?.toString(),
  ));
}

class MyApp extends StatelessWidget {
  final String? nik;
  final String? password;

  const MyApp({this.nik, this.password});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Election Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Launcher(nik: nik, password: password),
    );
  }
}
