import 'package:flutter/material.dart';
import 'profile_page.dart';

class PageAccueil extends StatelessWidget {
  const PageAccueil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accueil Wallou"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PageProfil()));
            },
          )
        ],
      ),
      body: const Center(
        child: Text("Bienvenue sur Wallou !", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
