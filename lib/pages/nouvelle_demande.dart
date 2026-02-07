import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'recherche_prestataires.dart';

class NouvelleDemande extends StatefulWidget {
  const NouvelleDemande({super.key});

  @override
  _NouvelleDemandeState createState() => _NouvelleDemandeState();
}

class _NouvelleDemandeState extends State<NouvelleDemande> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  String? _typeService;
  bool _isSaving = false;
  bool _isLoadingLocation = false;
  bool _estUrgence = false;
  double? _latitude;
  double? _longitude;

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
  void dispose() {
    _descriptionController.dispose();
    _villeController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez activer les services de localisation'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission de localisation refusée'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permission refusée définitivement. Activez-la dans les paramètres.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Faire le reverse geocoding pour obtenir l'adresse
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];

          // Extraire la ville
          String ville =
              place.locality ??
              place.administrativeArea ??
              place.subAdministrativeArea ??
              '';

          // Construire l'adresse
          List<String> addressParts = [];
          if (place.street != null && place.street!.isNotEmpty) {
            addressParts.add(place.street!);
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }

          String adresse = addressParts.join(', ');

          setState(() {
            _latitude = position.latitude;
            _longitude = position.longitude;
            _villeController.text = ville;
            _adresseController.text = adresse;
            _isLoadingLocation = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Position obtenue: $ville${adresse.isNotEmpty ? ", $adresse" : ""}',
                ),
                backgroundColor: const Color.fromARGB(255, 18, 100, 20),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // si aucune adresse trouvee alors juste les coordonnées
          setState(() {
            _latitude = position.latitude;
            _longitude = position.longitude;
            _isLoadingLocation = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Position GPS obtenue (adresse non disponible)'),
                backgroundColor: Color.fromARGB(255, 222, 133, 0),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (geocodingError) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isLoadingLocation = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Position GPS obtenue (impossible de trouver l\'adresse)',
              ),
              backgroundColor: Color.fromARGB(255, 203, 122, 0),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'obtention de la position: $e'),
            backgroundColor: const Color.fromARGB(255, 170, 25, 14),
          ),
        );
      }
    }
  }

  Future<void> _publierDemande() async {
    if (_typeService == null ||
        _descriptionController.text.isEmpty ||
        _villeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs requis'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Récupérer les infos du client
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        String fullAddress = _adresseController.text.trim().isNotEmpty
            ? '${_adresseController.text.trim()}, ${_villeController.text.trim()}'
            : _villeController.text.trim();

        // Créer la demande
        await FirebaseFirestore.instance.collection('demandes').add({
          'clientId': user.uid,
          'clientName': userData['name'] ?? 'Client',
          'clientTelephone': userData['telephone'] ?? '',
          'typeService': _typeService,
          'description': _descriptionController.text.trim(),
          'ville': _villeController.text.trim(),
          'adresse': _adresseController.text.trim(),
          'fullAddress': fullAddress,
          'latitude': _latitude,
          'longitude': _longitude,
          'estUrgence': _estUrgence,
          'status': 'en_attente',
          'dateCreation': FieldValue.serverTimestamp(),
          'dateReponse': null,
          'prestataireId': null,
          'prestataireName': null,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demande publiée avec succès'),
              backgroundColor: Color.fromARGB(255, 18, 100, 20),
            ),
          );

          // Lancer automatiquement la recherche de prestataires
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RecherchePrestataires(
                typeService: _typeService!,
                ville: _villeController.text.trim(),
                clientLatitude: _latitude,
                clientLongitude: _longitude,
                description: _descriptionController.text.trim(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de publication: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 7, 189),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 16, 7, 189),
        elevation: 0,
        title: const Text(
          'Publier une demande',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
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
              const Text(
                'Quel service recherchez-vous ?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 16, 7, 189),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: _typeService,
                decoration: InputDecoration(
                  labelText: 'Type de service',
                  prefixIcon: const Icon(Icons.build_outlined),
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
              const Text(
                'Décrivez votre besoin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 16, 7, 189),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Description détaillée',
                  hintText: 'Décrivez le service dont vous avez besoin...',
                  prefixIcon: const Icon(Icons.description_outlined),
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
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              // Urgence/Panne
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _estUrgence
                        ? const Color.fromARGB(255, 179, 28, 17)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  color: _estUrgence
                      ? const Color.fromARGB(255, 196, 42, 31).withOpacity(0.05)
                      : Colors.transparent,
                ),
                child: CheckboxListTile(
                  value: _estUrgence,
                  onChanged: (value) {
                    setState(() {
                      _estUrgence = value ?? false;
                    });
                  },
                  title: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: _estUrgence
                            ? const Color.fromARGB(255, 154, 21, 12)
                            : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Panne / Urgence',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _estUrgence
                                    ? const Color.fromARGB(255, 165, 20, 10)
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              'Cochez si c\'est une intervention urgente',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  activeColor: const Color.fromARGB(255, 147, 20, 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Où se trouve le lieu d\'intervention ?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 16, 7, 189),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _villeController,
                decoration: InputDecoration(
                  labelText: 'Ville *',
                  hintText: 'Ex: Dakar, Thiès, Saint-Louis...',
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
              const SizedBox(height: 15),
              TextField(
                controller: _adresseController,
                decoration: InputDecoration(
                  labelText: 'Adresse (optionnel)',
                  hintText: 'Ex: Rue, quartier...',
                  prefixIcon: const Icon(Icons.location_on),
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
              // Bouton pour obtenir la localisation actuelle
              OutlinedButton.icon(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: const Color.fromARGB(255, 16, 7, 189),
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _latitude != null
                            ? Icons.check_circle
                            : Icons.my_location,
                        color: _latitude != null
                            ? const Color.fromARGB(255, 18, 100, 20)
                            : const Color.fromARGB(255, 16, 7, 189),
                      ),
                label: Text(
                  _isLoadingLocation
                      ? 'Obtention de la position...'
                      : _latitude != null
                      ? 'Position GPS obtenue ✓'
                      : 'Utiliser ma position actuelle',
                  style: TextStyle(
                    fontSize: 15,
                    color: _latitude != null
                        ? const Color.fromARGB(255, 18, 100, 20)
                        : const Color.fromARGB(255, 16, 7, 189),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(
                    color: _latitude != null
                        ? const Color.fromARGB(255, 18, 100, 20)
                        : const Color.fromARGB(255, 16, 7, 189),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _publierDemande,
                icon: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isSaving ? 'Publication...' : 'Publier la demande',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 16, 7, 189),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
