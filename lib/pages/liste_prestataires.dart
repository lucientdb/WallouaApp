import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ListePrestataires extends StatefulWidget {
  const ListePrestataires({super.key});

  @override
  _ListePrestatairesState createState() => _ListePrestatairesState();
}

class _ListePrestatairesState extends State<ListePrestataires> {
  String? _filtreService;
  final TextEditingController _searchController = TextEditingController();

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 7, 189),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 16, 7, 189),
        elevation: 0,
        title: const Text(
          'Réparateurs disponibles',
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
            // Filtres
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Barre de recherche
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un réparateur...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
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
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 15),
                  // Filtre par service
                  DropdownButtonFormField<String>(
                    initialValue: _filtreService,
                    decoration: InputDecoration(
                      labelText: 'Filtrer par service',
                      prefixIcon: const Icon(Icons.filter_list),
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
                            value: service == 'Tous les services'
                                ? null
                                : service,
                            child: Text(service),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _filtreService = value;
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
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.person_off, size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            'Aucun réparateur disponible',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filtrage
                  var prestataires = snapshot.data!.docs.where((doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;

                    // Filtre par service
                    if (_filtreService != null &&
                        data['typeService'] != _filtreService) {
                      return false;
                    }

                    // Filtre par recherche (nom ou ville)
                    if (_searchController.text.isNotEmpty) {
                      String searchLower = _searchController.text.toLowerCase();
                      String name = (data['name'] ?? '').toLowerCase();
                      String ville = (data['ville'] ?? '').toLowerCase();
                      String service = (data['typeService'] ?? '')
                          .toLowerCase();

                      if (!name.contains(searchLower) &&
                          !ville.contains(searchLower) &&
                          !service.contains(searchLower)) {
                        return false;
                      }
                    }

                    return true;
                  }).toList();

                  if (prestataires.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search_off, size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            'Aucun résultat',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () => _afficherDetailPrestataire(data),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                // Photo de profil
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 16, 7, 189).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    image: data['photoUrl'] != null
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              data['photoUrl'],
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: data['photoUrl'] == null
                                      ? const Icon(
                                          Icons.business,
                                          size: 35,
                                          color: Color.fromARGB(255, 16, 7, 189),
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
                                        data['name'] ?? 'Prestataire',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 16, 7, 189),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.work,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              data['typeService'] ??
                                                  'Service non spécifié',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_city,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              data['ville'] ??
                                                  'Ville non spécifiée',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Bouton contact
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Color.fromARGB(255, 16, 7, 189),
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _afficherDetailPrestataire(data),
                                ),
                              ],
                            ),
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

  void _afficherDetailPrestataire(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // Barre de titre
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 16, 7, 189).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 16, 7, 189).withOpacity(0.1),
                      shape: BoxShape.circle,
                      image: data['photoUrl'] != null
                          ? DecorationImage(
                              image: NetworkImage(data['photoUrl']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: data['photoUrl'] == null
                        ? const Icon(
                            Icons.business,
                            size: 40,
                            color: Color.fromARGB(255, 16, 7, 189),
                          )
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Prestataire',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 16, 7, 189),
                          ),
                        ),
                        Text(
                          data['typeService'] ?? 'Service',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      Icons.phone,
                      'Téléphone',
                      data['telephone'] ?? 'Non spécifié',
                    ),
                    const Divider(height: 30),
                    _buildInfoRow(
                      Icons.email,
                      'Email',
                      data['email'] ?? 'Non spécifié',
                    ),
                    const Divider(height: 30),
                    _buildInfoRow(
                      Icons.location_city,
                      'Ville',
                      data['ville'] ?? 'Non spécifiée',
                    ),
                    if (data['fullAddress'] != null) ...[
                      const Divider(height: 30),
                      _buildInfoRow(
                        Icons.location_on,
                        'Adresse',
                        data['fullAddress'],
                      ),
                    ],
                    const SizedBox(height: 30),
                    // Boutons de contact
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _appelerPrestataire(data['telephone'] ?? '');
                            },
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Appeler'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 16, 7, 189),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _envoyerSMS(data['telephone'] ?? '');
                            },
                            icon: const Icon(Icons.sms, size: 18),
                            label: const Text('SMS'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color.fromARGB(255, 16, 7, 189),
                              side: const BorderSide(color: Color.fromARGB(255, 16, 7, 189)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (data['email'] != null && data['email'].isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _envoyerEmail(data['email'] ?? '');
                          },
                          icon: const Icon(Icons.email, size: 18),
                          label: const Text('Envoyer un email'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color.fromARGB(255, 16, 7, 189),
                            side: const BorderSide(color: Color.fromARGB(255, 16, 7, 189)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 16, 7, 189).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color.fromARGB(255, 16, 7, 189), size: 24),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
    try {
      final bool launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application téléphone'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
    try {
      final bool launched = await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application SMS'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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

    try {
      final bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application email'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
