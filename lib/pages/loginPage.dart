import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notifications_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _emailError = '';
  String _passwordError = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 7, 189),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 16, 7, 189),
        title: Text('Page de Login'),
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
      ),

      body: Container(
        margin: EdgeInsets.only(bottom: 60),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 237, 241, 243),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Image.asset(
                          'lib/assets/logo.png',
                          fit: BoxFit.contain,
                          width: 130,
                          height: 130,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 15),
                Text(
                  'Login',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Vous n'avez pas de compte? ",
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: "Inscrivez-vous",
                          style: TextStyle(color: const Color.fromARGB(255, 16, 7, 189)),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      setState(() {
                        _emailError = '';
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      prefixIcon: Icon(Icons.email),
                      errorText: _emailError.isEmpty ? null : _emailError,
                    ),
                  ),
                ),

                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onChanged: (value) {
                      setState(() {
                        _passwordError = '';
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      prefixIcon: Icon(Icons.lock),
                      errorText: _passwordError.isEmpty ? null : _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 5),
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: const Color.fromARGB(255, 16, 7, 189),
                        ),
                        Text('Se rappeler de moi'),
                      ],
                    ),
                    SizedBox(width: 15),
                    ElevatedButton(
                      onPressed: () => _login(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 16, 7, 189),
                      ),
                      child: Text(
                        'Se connecter',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login(BuildContext context) async {
    bool hasError = false;

    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Email requis';
      });
      hasError = true;
    } else if (!_emailController.text.contains('@')) {
      setState(() {
        _emailError = 'Email invalide';
      });
      hasError = true;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Mot de passe requis';
      });
      hasError = true;
    }

    if (hasError) return;

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      // Créer le document utilisateur s'il n'existe pas
      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'email': email,
              'role': 'client',
              'createdAt': FieldValue.serverTimestamp(),
            });
        userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
      } else {
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null && !userData.containsKey('role')) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({'role': 'client'});
          userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();
        }
      }

      String userType = userDoc['role'] ?? 'client';

      await NotificationsService.saveTokenToFirestore(userCredential.user);

      if (userType == 'prestataire') {
        Navigator.pushReplacementNamed(context, '/pagePrestataire');
      } else {
        Navigator.pushReplacementNamed(context, '/pageClient');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _emailError = 'Aucun utilisateur trouvé';
        } else if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          _passwordError = 'Email ou mot de passe incorrect';
        } else if (e.code == 'invalid-email') {
          _emailError = 'Format d\'email invalide';
        } else if (e.code == 'too-many-requests') {
          _passwordError = 'Trop de tentatives. Réessayez plus tard';
        } else {
          _passwordError = 'Erreur: ${e.message}';
        }
      });
    } catch (e) {
      print('Erreur de connexion: $e');
      setState(() {
        if (e.toString().contains('field \'role\'')) {
          _passwordError =
              'Erreur de profil utilisateur. Contactez le support.';
        } else {
          _passwordError = 'Erreur de connexion: $e';
        }
      });
    }
  }
}
