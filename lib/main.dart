import 'package:flutter/material.dart';
import 'package:presensi/home-page.dart';
import 'package:presensi/login-page.dart';
import 'package:presensi/simpan-page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage()
      );
  }
}

