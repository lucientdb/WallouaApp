

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart'; // 🔹 On importe la page d’accueil

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _seSouvenir = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin(); // 🔹 Vérifie si on peut aller directement à l'accueil
  }

  // Vérifie si l'utilisateur est déjà connecté
  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('seSouvenir') ?? false;
    if (saved && prefs.getString('motDePasse') != null) {
      // Redirection automatique
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // Sinon, on charge les champs enregistrés (numéro, etc.)
      _loadSavedData();
    }
  }

  // Charger les données enregistrées (numéro + mot de passe si coché)
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _numeroController.text = prefs.getString('numeroClient') ?? '';
      _seSouvenir = prefs.getBool('seSouvenir') ?? false;
      if (_seSouvenir) {
        _passwordController.text = prefs.getString('motDePasse') ?? '';
      }
    });
  }

  // Sauvegarder les données
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('numeroClient', _numeroController.text);
    await prefs.setBool('seSouvenir', _seSouvenir);

    if (_seSouvenir) {
      await prefs.setString('motDePasse', _passwordController.text);
    } else {
      await prefs.remove('motDePasse');
    }
  }

  // Connexion simulée
  void _connexion() async {
    await _saveData();

    // Ici tu pourrais ajouter une vraie vérification (ex: API, base de données)
    if (_numeroController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion réussie ✅')),
      );

      // 🔹 Redirection vers la page d'accueil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs ❌')),
      );
    }
  }

  Column buildColumnForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextField(
          controller: _numeroController,
          decoration: const InputDecoration(
            labelText: "Numéro Client",
            icon: Icon(Icons.person_outline, color: Colors.blueAccent),
          ),
        ),
        TextField(
          controller: _passwordController,
          obscureText: _obscureText,
          decoration: InputDecoration(
            labelText: "Mot de passe",
            icon: const Icon(Icons.lock_open_outlined, color: Colors.blueAccent),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
        SwitchListTile(
          value: _seSouvenir,
          onChanged: (value) {
            setState(() {
              _seSouvenir = value;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text("Se souvenir de moi"),
        ),
        Container(
          width: double.infinity,
          height: 40,
          margin: const EdgeInsets.only(top: 20),
          child: ElevatedButton(
            onPressed: _connexion,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              "Connexion",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 10),
          alignment: Alignment.topRight,
          child: const Text(
            "Mot de passe oublié ?",
            style: TextStyle(color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.deepOrange, Colors.blue],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Wallou", style: TextStyle(color: Colors.white)),
          centerTitle: true,
          leading: const Icon(Icons.menu_sharp, color: Colors.white),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(10),
            ),
            child: buildColumnForm(),
          ),
        ),
      ),
    );
  }
}


