import 'package:flutter/material.dart';

class BoutonPrincipal extends StatelessWidget {
  final String texte;
  final VoidCallback onPressed;

  const BoutonPrincipal({super.key, required this.texte, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          texte,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
