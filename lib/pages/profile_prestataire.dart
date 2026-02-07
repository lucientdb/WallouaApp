import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'map_picker.dart';

class ProfilePrestataire extends StatefulWidget {
  const ProfilePrestataire({super.key});

  @override
  _ProfilePrestataireState createState() => _ProfilePrestataireState();
}

class _ProfilePrestataireState extends State<ProfilePrestataire> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _localisationController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _fullAddress = '';
  String? _photoUrl;
  String? _typeService;
  bool _isLoading = true;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

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
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _nomController.text = data['name'] ?? '';
            _telephoneController.text = data['telephone'] ?? '';
            _emailController.text = data['email'] ?? '';
            _villeController.text = data['ville'] ?? '';
            _localisationController.text = data['location'] ?? '';
            _latitude = data['latitude'] ?? 0.0;
            _longitude = data['longitude'] ?? 0.0;
            _fullAddress = data['fullAddress'] ?? '';
            _photoUrl = data['photoUrl'];
            _typeService = data['typeService'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de chargement: $e')));
    }
  }

  Future<void> _updateLocation() async {
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
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _saveProfile() async {
    if (_nomController.text.isEmpty ||
        _telephoneController.text.isEmpty ||
        _villeController.text.isEmpty ||
        _localisationController.text.isEmpty ||
        _typeService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'name': _nomController.text.trim(),
              'telephone': _telephoneController.text.trim(),
              'ville': _villeController.text.trim(),
              'location': _localisationController.text,
              'latitude': _latitude,
              'longitude': _longitude,
              'fullAddress': _fullAddress,
              'typeService': _typeService,
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès'),
              backgroundColor: const Color.fromARGB(255, 18, 100, 20),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de sauvegarde: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isSaving = true);

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('${user.uid}.jpg');

        await storageRef.putFile(File(image.path));
        final photoUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'photoUrl': photoUrl});

        setState(() {
          _photoUrl = photoUrl;
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo de profil mise à jour'),
              backgroundColor: const Color.fromARGB(255, 18, 100, 20),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur upload photo: $e')));
      }
    }
  }

  Future<void> _changeEmail() async {
    showDialog(
      context: context,
      builder: (context) {
        final emailController = TextEditingController();
        final passwordController = TextEditingController();
        return AlertDialog(
          title: const Text('Modifier l\'email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Nouvel email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe actuel',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null && user.email != null) {
                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: passwordController.text,
                    );
                    await user.reauthenticateWithCredential(credential);
                    await user.verifyBeforeUpdateEmail(emailController.text);

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'email': emailController.text});

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Email mis à jour. Vérifiez votre boîte mail.',
                          ),
                          backgroundColor: const Color.fromARGB(255, 18, 100, 20),
                        ),
                      );
                      _loadUserData();
                    }
                  }
                } on FirebaseAuthException catch (e) {
                  if (mounted) {
                    String message = 'Erreur: ${e.message}';
                    if (e.code == 'wrong-password') {
                      message = 'Mot de passe incorrect';
                    } else if (e.code == 'invalid-email') {
                      message = 'Email invalide';
                    } else if (e.code == 'email-already-in-use') {
                      message = 'Cet email est déjà utilisé';
                    }
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
                  }
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword() async {
    showDialog(
      context: context,
      builder: (context) {
        final oldPasswordController = TextEditingController();
        final newPasswordController = TextEditingController();
        return AlertDialog(
          title: const Text('Modifier le mot de passe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe actuel',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null && user.email != null) {
                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: oldPasswordController.text,
                    );
                    await user.reauthenticateWithCredential(credential);
                    await user.updatePassword(newPasswordController.text);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mot de passe modifié avec succès'),
                          backgroundColor: const Color.fromARGB(255, 18, 100, 20),
                        ),
                      );
                    }
                  }
                } on FirebaseAuthException catch (e) {
                  if (mounted) {
                    String message = 'Erreur: ${e.message}';
                    if (e.code == 'wrong-password') {
                      message = 'Mot de passe actuel incorrect';
                    } else if (e.code == 'weak-password') {
                      message =
                          'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
                  }
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Color.fromARGB(255, 181, 26, 15)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 7, 189),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 16, 7, 189),
        elevation: 0,
        title: const Text(
          'Mon Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Container(
              margin: const EdgeInsets.only(top: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 16, 7, 189),
                              shape: BoxShape.circle,
                              image: _photoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_photoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _photoUrl == null
                                ? const Icon(
                                    Icons.business,
                                    size: 50,
                                    color: const Color.fromARGB(255, 16, 7, 189),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _uploadPhoto,
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 16, 7, 189),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _nomController,
                      decoration: InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 16, 7, 189),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _telephoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 16, 7, 189),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Color.fromARGB(255, 16, 7, 189),
                          ),
                          onPressed: _changeEmail,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _typeService,
                      decoration: InputDecoration(
                        labelText: 'Type de service',
                        prefixIcon: const Icon(Icons.work_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 16, 7, 189),
                            width: 2,
                          ),
                        ),
                      ),
                      items: _servicesDisponibles
                          .map(
                            (service) => DropdownMenuItem(
                              value: service,
                              child: Text(service),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _typeService = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _villeController,
                      decoration: InputDecoration(
                        labelText: 'Ville',
                        prefixIcon: const Icon(Icons.location_city),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 16, 7, 189),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _localisationController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Localisation',
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.map, color: Color.fromARGB(255, 16, 7, 189)),
                          onPressed: _updateLocation,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 16, 7, 189),
                            width: 2,
                          ),
                        ),
                        hintText: 'Cliquez sur la carte',
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _changePassword,
                      icon: const Icon(
                        Icons.lock_outline,
                        color: Color.fromARGB(255, 16, 7, 189),
                      ),
                      label: const Text(
                        'Modifier le mot de passe',
                        style: TextStyle(color: Color.fromARGB(255, 16, 7, 189)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        side: const BorderSide(color: Color.fromARGB(255, 16, 7, 189)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 16, 7, 189),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Enregistrer les modifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 15),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Se déconnecter',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _villeController.dispose();
    _localisationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
