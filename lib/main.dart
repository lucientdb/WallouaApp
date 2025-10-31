import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'utils/theme.dart';

void main() {
  runApp(const WallouApp());
}

class WallouApp extends StatelessWidget {
  const WallouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallou',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const PageConnexion(),
    );
  }
}
