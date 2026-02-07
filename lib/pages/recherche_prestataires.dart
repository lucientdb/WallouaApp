import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../services/notification_handler.dart';

class RecherchePrestataires extends StatefulWidget {
  final String typeService;
  final String ville;
  final double? clientLatitude;
  final double? clientLongitude;
  final String? description;

  const RecherchePrestataires({
    super.key,
    required this.typeService,
    required this.ville,
    this.clientLatitude,
    this.clientLongitude,
    this.description,
  });

  @override
  _RecherchePrestatairesState createState() => _RecherchePrestatairesState();
}

class _RecherchePrestatairesState extends State<RecherchePrestataires> {
  List<Map<String, dynamic>> _prestataires = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _rechercherPrestataires();
  }

  double _calculerDistance(double lat1, double lon1, double lat2, double lon2) {
    // Formule de Haversine pour calculer la distance entre deux points GPS
    const double R = 6371; // Rayon de la Terre en km
    double dLat = _toRad(lat2 - lat1);
    double dLon = _toRad(lon2 - lon1);
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance en km
  }

  double _toRad(double deg) {
    return deg * (pi / 180);
  }

  Future<void> _rechercherPrestataires() async {
    try {
      // Vérifier que les coordonnées GPS du client sont disponibles
      if (widget.clientLatitude == null || widget.clientLongitude == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Position GPS non disponible'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Récupérer TOUS les prestataires avec le type de service correspondant
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'prestataire')
          .where('typeService', isEqualTo: widget.typeService)
          .get();

      print('=== RECHERCHE PRESTATAIRES ===');
      print('Service recherché: ${widget.typeService}');
      print(
        'Position client: ${widget.clientLatitude}, ${widget.clientLongitude}',
      );
      print('Nombre total trouvé: ${querySnapshot.docs.length}');

      List<Map<String, dynamic>> prestataires = [];
      const double rayonMax = 50.0; // Rayon de recherche en km

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['latitude'] == null || data['longitude'] == null) {
          print('Prestataire ${data['name']} exclu (pas de coordonnées GPS)');
          continue;
        }

        // Calculer la distance avec les coordonnées GPS
        double distance = _calculerDistance(
          widget.clientLatitude!,
          widget.clientLongitude!,
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        );

        print(
          'Prestataire ${data['name']} - Distance: ${distance.toStringAsFixed(2)}km - Ville: ${data['ville']}',
        );

        // Filtrer par rayon de distance uniquement
        if (distance <= rayonMax) {
          prestataires.add({
            'id': doc.id,
            'name': data['name'] ?? 'Prestataire',
            'telephone': data['telephone'] ?? '',
            'email': data['email'] ?? '',
            'ville': data['ville'] ?? 'Non spécifié',
            'typeService': data['typeService'] ?? '',
            'photoUrl': data['photoUrl'],
            'address': data['address'] ?? '',
            'latitude': data['latitude'],
            'longitude': data['longitude'],
            'distance': distance,
          });
          print('  ✓ Ajouté à la liste');
        } else {
          print('  ✗ Exclu (distance > ${rayonMax}km)');
        }
      }

      // Trier par distance croissante (le plus proche d'abord)
      prestataires.sort((a, b) {
        final distA = a['distance'] as double;
        final distB = b['distance'] as double;
        return distA.compareTo(distB);
      });

      print('Nombre final de prestataires: ${prestataires.length}');

      setState(() {
        _prestataires = prestataires;
        _isLoading = false;
      });
    } catch (e) {
      print('ERREUR: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de recherche: $e')));
      }
    }
  }

  Future<bool> _hasDemandeEnAttente() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    QuerySnapshot demandesQuery = await FirebaseFirestore.instance
        .collection('demandes')
        .where('clientId', isEqualTo: user.uid)
        .where('typeService', isEqualTo: widget.typeService)
        .where('status', isEqualTo: 'en_attente')
        .limit(1)
        .get();
    return demandesQuery.docs.isNotEmpty;
  }

  Future<void> _demanderDepannage(Map<String, dynamic> prestataire) async {
    if (!await _hasDemandeEnAttente()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Publiez d\'abord une demande avant de choisir un prestataire.',
            ),
          ),
        );
      }
      return;
    }
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      double distance = prestataire['distance'] as double;
      QuerySnapshot demandesQuery = await FirebaseFirestore.instance
          .collection('demandes')
          .where('clientId', isEqualTo: user.uid)
          .where('typeService', isEqualTo: widget.typeService)
          .where('status', isEqualTo: 'en_attente')
          .orderBy('dateCreation', descending: true)
          .limit(1)
          .get();
      if (demandesQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune demande à mettre à jour.')),
          );
        }
        return;
      }
      String demandeId = demandesQuery.docs.first.id;
      await FirebaseFirestore.instance
          .collection('demandes')
          .doc(demandeId)
          .update({
            'prestataireId': prestataire['id'],
            'prestataireName': prestataire['name'],
            'prestataireTelephone': prestataire['telephone'],
            'prestataireEmail': prestataire['email'],
            'distance': distance,
            'dateSelection': FieldValue.serverTimestamp(),
            'status': 'en_attente_reponse',
          });

      //notification pour prestataire
      await NotificationHandler.createNotificationForNewDemande(
        prestataireId: prestataire['id'],
        demandeId: demandeId,
        clientName: userData['name'] ?? 'Client',
        typeService: widget.typeService,
        clientId: user.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demande envoyée à ${prestataire['name']} !'),
            backgroundColor: const Color.fromARGB(255, 18, 100, 20),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/pageClient',
              (route) => false,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 7, 189),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 16, 7, 189),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résultats de recherche',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.typeService,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _prestataires.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    Text(
                      'Aucun prestataire trouvé pour "${widget.typeService}"',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Essayez de chercher un autre service',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _prestataires.length,
                itemBuilder: (context, index) {
                  final prestataire = _prestataires[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          // Photo de profil
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 16, 7, 189),
                              shape: BoxShape.circle,
                              image: prestataire['photoUrl'] != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        prestataire['photoUrl'],
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: prestataire['photoUrl'] == null
                                ? const Icon(
                                    Icons.business,
                                    size: 30,
                                    color: const Color.fromARGB(
                                      255,
                                      16,
                                      7,
                                      189,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 15),
                          // Informations
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prestataire['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(
                                      255,
                                      16,
                                      7,
                                      189,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            prestataire['ville'] ??
                                                'Ville non spécifiée',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (prestataire['distance'] != null)
                                            Text(
                                              '${(prestataire['distance'] as double).toStringAsFixed(1)} km',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color.fromARGB(
                                                  255,
                                                  16,
                                                  7,
                                                  189,
                                                ),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Boutons d'action
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: 'Demander un dépannage d\'urgence',
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.build,
                                        color: Colors.orange,
                                        size: 26,
                                      ),
                                      onPressed: () =>
                                          _demanderDepannage(prestataire),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const Text(
                                      'Dépannage',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              const SizedBox(height: 2),
                              Tooltip(
                                message: 'Afficher contact',
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.phone,
                                        color: const Color.fromARGB(
                                          255,
                                          16,
                                          7,
                                          189,
                                        ),
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(prestataire['name']),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Téléphone:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(prestataire['telephone']),
                                                const SizedBox(height: 10),
                                                const Text(
                                                  'Email:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(prestataire['email']),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Fermer'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const Text(
                                      'Contact',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: const Color.fromARGB(
                                          255,
                                          16,
                                          7,
                                          189,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
