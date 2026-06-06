import 'dart:io';

import 'package:election_flutter_app/constants.dart';
import 'package:election_flutter_app/launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TrustAllCerts extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

Future<void> main() async {
  HttpOverrides.global = _TrustAllCerts();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  SharedPreferences preferences = await SharedPreferences.getInstance();
  runApp(MyApp(
    nik:      preferences.get("nik")?.toString(),
    password: preferences.get("password")?.toString(),
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
      title: 'STARBHAK Election',
      theme: AppTheme.theme,
      home: Launcher(nik: nik, password: password),
    );
  }
}
