import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String _userType = 'client';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _localisationController = TextEditingController();
  String? _typeService;
  String _nomError = '';
  String _telephoneError = '';
  String _emailError = '';
  String _passwordError = '';
  String _villeError = '';
  String _localisationError = '';
  String _typeServiceError = '';
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _fullAddress = '';

  final List<String> _servicesDisponibles = [
    'Plomberie',
    'Électricité',
    'Ménage',
    'Jardinage',
    'Peinture',
    'Maçonnerie',
    'Menuiserie',
    'Climatisation',
    'Plomberie et Chauffage',
    'Nettoyage Auto',
    'Déménagement',
    'Réparation électronique',
    'Maintenance automobile',
    'Autre',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 7, 189),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 16, 7, 189),
        title: Text('Inscription'),
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: EdgeInsets.only(bottom: 10),
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
            padding: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 10),
                Text(
                  'Créez votre compte',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _nomController,
                    onChanged: (value) {
                      setState(() {
                        _nomError = '';
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Nom complet',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      errorText: _nomError.isEmpty ? null : _nomError,
                    ),
                  ),
                ),

                SizedBox(height: 12),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _telephoneController,
                    keyboardType: TextInputType.phone,
                    onChanged: (value) {
                      setState(() {
                        _telephoneError = '';
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Numéro de téléphone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: Icon(Icons.phone),
                      hintText: '+221 77 123 45 67',
                      errorText: _telephoneError.isEmpty
                          ? null
                          : _telephoneError,
                    ),
                  ),
                ),

                SizedBox(height: 12),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
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
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: Icon(Icons.email),
                      errorText: _emailError.isEmpty ? null : _emailError,
                    ),
                  ),
                ),

                SizedBox(height: 12),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
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
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: Icon(Icons.lock),
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

                SizedBox(height: 12),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    onChanged: (value) {
                      setState(() {
                        _passwordError = '';
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      errorText: _passwordError.isEmpty ? null : _passwordError,
                    ),
                  ),
                ),

                SizedBox(height: 15),

                Text(
                  'Type d\'utilisateur',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Radio(
                          value: 'client',
                          groupValue: _userType,
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _userType = value;
                              });
                            }
                          },
                        ),
                        Text('Client'),
                      ],
                    ),
                    SizedBox(width: 40),
                    Row(
                      children: [
                        Radio(
                          value: 'prestataire',
                          groupValue: _userType,
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _userType = value;
                              });
                            }
                          },
                        ),
                        Text('Prestataire'),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 15),

                if (_userType == 'prestataire') ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: DropdownButtonFormField<String>(
                      initialValue: _typeService,
                      decoration: InputDecoration(
                        labelText: 'Type de service *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        prefixIcon: Icon(Icons.build),
                        errorText: _typeServiceError.isEmpty
                            ? null
                            : _typeServiceError,
                      ),
                      items: _servicesDisponibles.map((service) {
                        return DropdownMenuItem(
                          value: service,
                          child: Text(service),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _typeService = value;
                          _typeServiceError = '';
                        });
                      },
                    ),
                  ),

                  SizedBox(height: 12),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _villeController,
                      onChanged: (value) {
                        setState(() {
                          _villeError = '';
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Ville',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        errorText: _villeError.isEmpty ? null : _villeError,
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _localisationController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Localisation',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        errorText: _localisationError.isEmpty
                            ? null
                            : _localisationError,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.map, color: const Color.fromARGB(255, 16, 7, 189)),
                          onPressed: () {
                            _getCurrentLocation();
                          },
                        ),
                        hintText:
                            'Cliquez sur la carte pour sélectionner votre position',
                      ),
                    ),
                  ),

                  SizedBox(height: 12),
                ],

                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 16, 7, 189),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: Text(
                    'S\'inscrire',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),

                SizedBox(height: 15),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Vous avez déjà un compte? ",
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: "Connectez-vous",
                          style: TextStyle(color: const Color.fromARGB(255, 16, 7, 189)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPicker(
            initialLatitude: _latitude != 0.0 ? _latitude : null,
            initialLongitude: _longitude != 0.0 ? _longitude : null,
            initialAddress: _fullAddress.isNotEmpty ? _fullAddress : null,
          ),
        ),
      );

      if (result != null && result is Map) {
        final selectedPosition = result['position'] as LatLng;
        final address = result['address'] as String;

        setState(() {
          _latitude = selectedPosition.latitude;
          _longitude = selectedPosition.longitude;
          _fullAddress = address;
          _localisationController.text = address;
          _localisationError = '';
        });
      }
    } catch (e) {
      setState(() {
        _localisationError = 'Erreur lors de la sélection de la position';
      });
    }
  }

  Future<void> _register() async {
    bool hasError = false;

    if (_nomController.text.isEmpty) {
      setState(() {
        _nomError = 'Nom complet requis';
      });
      hasError = true;
    }

    if (_telephoneController.text.isEmpty) {
      setState(() {
        _telephoneError = 'Numéro de téléphone requis';
      });
      hasError = true;
    }

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
    } else if (_passwordController.text.length < 6) {
      setState(() {
        _passwordError = 'Le mot de passe doit contenir au moins 6 caractères';
      });
      hasError = true;
    } else if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Veuillez confirmer le mot de passe';
      });
      hasError = true;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordError = 'Les mots de passe ne correspondent pas';
      });
      hasError = true;
    }

    if (_userType == 'prestataire') {
      if (_typeService == null || _typeService!.isEmpty) {
        setState(() {
          _typeServiceError = 'Type de service requis';
        });
        hasError = true;
      }

      if (_villeController.text.isEmpty) {
        setState(() {
          _villeError = 'Ville requise';
        });
        hasError = true;
      }

      if (_localisationController.text.isEmpty) {
        setState(() {
          _localisationError = 'Localisation requise';
        });
        hasError = true;
      }
    }

    if (hasError) return;

    try {
      String name = _nomController.text.trim();
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String telephone = _telephoneController.text.trim();

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'telephone': telephone,
        'role': _userType,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_userType == 'prestataire') {
        userData['typeService'] = _typeService;
        userData['ville'] = _villeController.text.trim();
        userData['latitude'] = _latitude;
        userData['longitude'] = _longitude;
        userData['location'] = _localisationController.text;
        userData['fullAddress'] = _fullAddress;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      if (_userType == 'prestataire') {
        Navigator.pushReplacementNamed(context, '/pagePrestataire');
      } else {
        Navigator.pushReplacementNamed(context, '/pageClient');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = '';
      setState(() {
        if (e.code == 'weak-password') {
          _passwordError = 'Le mot de passe est trop faible';
          errorMessage =
              'Le mot de passe est trop faible. Utilisez au moins 6 caractères.';
        } else if (e.code == 'email-already-in-use') {
          _emailError = 'Cet email est déjà utilisé';
          errorMessage =
              'L\'email ${_emailController.text} est déjà utilisé par un autre compte.\n\nSi c\'est votre compte, connectez-vous plutôt que de vous inscrire.';
        } else if (e.code == 'invalid-email') {
          _emailError = 'Email invalide';
          errorMessage = 'L\'adresse email n\'est pas valide.';
        } else {
          _emailError = 'Erreur: ${e.message}';
          errorMessage = 'Erreur d\'inscription: ${e.message}';
        }
      });

      // Afficher un dialogue d'erreur
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: const Color.fromARGB(255, 179, 20, 9), size: 30),
                SizedBox(width: 10),
                Text('Erreur d\'inscription'),
              ],
            ),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: TextStyle(color: const Color.fromARGB(255, 16, 7, 189))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _emailError = 'Erreur d\'inscription: $e';
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: const Color.fromARGB(255, 179, 20, 9), size: 30),
                SizedBox(width: 10),
                Text('Erreur'),
              ],
            ),
            content: Text(
              'Une erreur s\'est produite lors de l\'inscription:\n$e',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: TextStyle(color: const Color.fromARGB(255, 16, 7, 189))),
              ),
            ],
          ),
        );
      }
    }
  }
}
