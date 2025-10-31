import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../widgets/logo_widget.dart';
import 'login_page.dart';

class PageInscription extends StatefulWidget {
  const PageInscription({super.key});

  @override
  State<PageInscription> createState() => _PageInscriptionState();
}

class _PageInscriptionState extends State<PageInscription> {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController motDePasseController = TextEditingController();
  final TextEditingController confirmerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: LogoWallou()),
            const SizedBox(height: 30),
            const Text(
              "Inscription",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ChampTexte(controller: nomController, label: "Nom complet"),
            const SizedBox(height: 20),
            ChampTexte(controller: emailController, label: "Adresse e-mail"),
            const SizedBox(height: 20),
            ChampTexte(controller: motDePasseController, label: "Mot de passe", cacherTexte: true),
            const SizedBox(height: 20),
            ChampTexte(controller: confirmerController, label: "Confirmer le mot de passe", cacherTexte: true),
            const SizedBox(height: 30),
            BoutonPrincipal(
              texte: "S'inscrire",
              onPressed: () {
                // TODO: inscription Firebase
              },
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Deja un compte ? "),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PageConnexion()));
                  },
                  child: const Text(
                    "Se connecter",
                    style: TextStyle(
                      color: Color(0xFF1E88E5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
