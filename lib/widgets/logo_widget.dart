import 'package:flutter/material.dart';

class LogoWallou extends StatelessWidget {
  const LogoWallou({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Icon(Icons.build, size: 70, color: Color(0xFF1E88E5)),
        SizedBox(height: 10),
        Text(
          "Wallou",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
