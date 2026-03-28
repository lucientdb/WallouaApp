import 'package:flutter/material.dart';

class PageProfil extends StatelessWidget {
  const PageProfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: const [
            CircleAvatar(radius: 50, backgroundColor: Color(0xFF1E88E5)),
            SizedBox(height: 20),
            Text("Nom de l'utilisateur", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("email@example.com", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
