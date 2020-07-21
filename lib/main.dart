import 'package:flutter/material.dart';

import 'package:dash/const.dart';
import 'package:dash/login.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duta',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginScreen(title: 'Duta Chat'),
    );
  }
}