import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ContacterReparateur extends StatefulWidget {
  const ContacterReparateur({super.key});

  @override
  _ContacterReparateurState createState() => _ContacterReparateurState();
}

class _ContacterReparateurState extends State<ContacterReparateur> {
  String? _selectedService;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _servicesDisponibles = [
    'Tous les services',
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 7, 189),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 16, 7, 189),
        elevation: 0,
        title: const Text(
          'Contacter un réparateur',
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
        child: Column(
          children: [
            // Barre de recherche et filtre
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Champ de recherche
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom, ville...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: const Color.fromARGB(255, 16, 7, 189),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color.fromARGB(255, 16, 7, 189)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: const Color.fromARGB(255, 16, 7, 189),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Filtre par service
                  DropdownButtonFormField<String>(
                    initialValue: _selectedService,
                    decoration: InputDecoration(
                      labelText: 'Filtrer par service',
                      prefixIcon: const Icon(
                        Icons.filter_list,
                        color: Color.fromARGB(255, 16, 7, 189),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 16, 7, 189),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: _servicesDisponibles.map((service) {
                      return DropdownMenuItem(
                        value: service == 'Tous les services' ? null : service,
                        child: Text(service),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedService = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Liste des prestataires
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'prestataire')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 16, 7, 189),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.person_search,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Aucun réparateur disponible',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filtrage des prestataires
                  var prestataires = snapshot.data!.docs.where((doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;

                    // Filtre par service
                    if (_selectedService != null &&
                        data['typeService'] != _selectedService) {
                      return false;
                    }

                    // Filtre par recherche textuelle
                    if (_searchQuery.isNotEmpty) {
                      String name = (data['name'] ?? '').toLowerCase();
                      String ville = (data['ville'] ?? '').toLowerCase();
                      String service = (data['typeService'] ?? '')
                          .toLowerCase();

                      return name.contains(_searchQuery) ||
                          ville.contains(_searchQuery) ||
                          service.contains(_searchQuery);
                    }

                    return true;
                  }).toList();

                  if (prestataires.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Aucun résultat pour "$_searchQuery"'
                                : 'Aucun réparateur disponible pour ce service',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: prestataires.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = prestataires[index];
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Photo de profil
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: const Color.fromARGB(255, 16, 7, 189).withOpacity(0.1),
                                    backgroundImage: data['photoUrl'] != null
                                        ? NetworkImage(data['photoUrl'])
                                        : null,
                                    child: data['photoUrl'] == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 35,
                                            color: const Color.fromARGB(255, 16, 7, 189),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 15),
                                  // Informations
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'] ?? 'Nom inconnu',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(255, 16, 7, 189),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.build,
                                              size: 14,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              data['typeService'] ??
                                                  'Non spécifié',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              data['ville'] ?? 'Non spécifié',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              // Boutons de contact
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _appelerPrestataire(
                                        data['telephone'] ?? '',
                                      ),
                                      icon: const Icon(Icons.phone, size: 18),
                                      label: const Text('Appeler'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(255, 16, 7, 189),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _envoyerSMS(data['telephone'] ?? ''),
                                      icon: const Icon(Icons.sms, size: 18),
                                      label: const Text('SMS'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color.fromARGB(255, 16, 7, 189),
                                        side: const BorderSide(
                                          color: Color.fromARGB(255, 16, 7, 189),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (data['email'] != null &&
                                  data['email'].isNotEmpty) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _envoyerEmail(data['email'] ?? ''),
                                    icon: const Icon(Icons.email, size: 18),
                                    label: const Text('Envoyer un email'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color.fromARGB(255, 16, 7, 189),
                                      side: const BorderSide(
                                        color: const Color.fromARGB(255, 16, 7, 189),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _appelerPrestataire(String telephone) async {
    if (telephone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone non disponible')),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: telephone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application téléphone'),
          ),
        );
      }
    }
  }

  Future<void> _envoyerSMS(String telephone) async {
    if (telephone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone non disponible')),
      );
      return;
    }

    final Uri smsUri = Uri(scheme: 'sms', path: telephone);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application SMS'),
          ),
        );
      }
    }
  }

  Future<void> _envoyerEmail(String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email non disponible')));
      return;
    }

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Demande de service',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application email'),
          ),
        );
      }
    }
  }
}
