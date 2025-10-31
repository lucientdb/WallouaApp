import 'package:flutter/material.dart';

class ChampTexte extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool cacherTexte;

  const ChampTexte({
    super.key,
    required this.controller,
    required this.label,
    this.cacherTexte = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: cacherTexte,
      decoration: InputDecoration(labelText: label),
    );
  }
}
