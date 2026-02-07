import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_handler.dart';

class DemandesPrestataire extends StatefulWidget {
  const DemandesPrestataire({super.key});

  @override
  _DemandesPrestataireState createState() => _DemandesPrestataireState();
}

class _DemandesPrestataireState extends State<DemandesPrestataire> {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 7, 189),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 16, 7, 189),
        elevation: 0,
        title: const Text(
          'Demandes reçues',
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
        child: user == null
            ? const Center(child: Text('Utilisateur non connecté'))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('demandes')
                    .where('prestataireId', isEqualTo: user.uid)
                    .where('status', isEqualTo: 'en_attente_reponse')
                    .orderBy('dateSelection', descending: true)
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
                          Icon(Icons.inbox, size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            'Aucune demande en attente',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Trier les demandes : urgences en premier
                  List<DocumentSnapshot> demandes = snapshot.data!.docs
                      .toList();
                  demandes.sort((a, b) {
                    Map<String, dynamic> dataA =
                        a.data() as Map<String, dynamic>;
                    Map<String, dynamic> dataB =
                        b.data() as Map<String, dynamic>;

                    bool urgenceA = dataA['estUrgence'] ?? false;
                    bool urgenceB = dataB['estUrgence'] ?? false;

                    // Urgences en premier
                    if (urgenceA && !urgenceB) return -1;
                    if (!urgenceA && urgenceB) return 1;

                    // Sinon tri par date
                    return 0;
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: demandes.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = demandes[index];
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;
                      bool estUrgence = data['estUrgence'] ?? false;
                      double? distance = (data['distance'] as num?)?.toDouble();

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: estUrgence
                              ? const BorderSide(color: Colors.red, width: 2)
                              : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge URGENCE si yen a
                              if (estUrgence) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'URGENCE - PANNE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        16,
                                        7,
                                        189,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.build,
                                      color: Color.fromARGB(255, 12, 4, 174),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['typeService'] ?? 'Service',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                              255,
                                              16,
                                              7,
                                              189,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Par ${data['clientName'] ?? 'Client'}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              // Description
                              const Text(
                                'Description:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                data['description'] ?? 'Non spécifiée',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Ville
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_city,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              data['ville'] ??
                                                  'Ville non spécifiée',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Adresse
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                data['fullAddress'] ??
                                                    data['adresse'] ??
                                                    'Adresse non spécifiée',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Distance
                                        if (distance != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.directions,
                                                size: 16,
                                                color: Color.fromARGB(
                                                  255,
                                                  16,
                                                  7,
                                                  189,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(
                                                    255,
                                                    16,
                                                    7,
                                                    189,
                                                  ).withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'Distance: ${distance.toStringAsFixed(1)} km',
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
                                              ),
                                            ],
                                          )
                                        else
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_off,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 5),
                                              const Text(
                                                'Position non disponible',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 5),
                                        // Téléphone
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.phone,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              data['clientTelephone'] ??
                                                  'Non spécifié',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        // Date de création
                                        if (data['dateCreation'] != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Créée le ' +
                                                    _formatDate(
                                                      data['dateCreation'],
                                                    ),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Boutons verticaux
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () => _lancerAppel(
                                          data['clientTelephone'],
                                        ),
                                        icon: const Icon(Icons.phone),
                                        color: const Color.fromARGB(
                                          255,
                                          16,
                                          7,
                                          189,
                                        ),
                                        tooltip: 'Appeler',
                                      ),
                                      IconButton(
                                        onPressed: () => _envoyerMessage(
                                          data['clientTelephone'],
                                        ),
                                        icon: const Icon(Icons.message),
                                        color: const Color.fromARGB(
                                          255,
                                          16,
                                          7,
                                          189,
                                        ),
                                        tooltip: 'Message',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Boutons accepter refuser
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _accepterDemande(doc.id, data),
                                            icon: const Icon(Icons.check),
                                            label: const Text('Accepter'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                    255,
                                                    18,
                                                    100,
                                                    20,
                                                  ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _refuserDemande(doc.id, data),
                                            icon: const Icon(Icons.close),
                                            label: const Text('Refuser'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
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
                  );
                },
              ),
      ),
    );
  }

  Future<void> _accepterDemande(
    String demandeId,
    Map<String, dynamic> data,
  ) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter la demande'),
        content: Text(
          'Voulez-vous accepter cette demande de ${data['clientName']} ?\n\n'
          'Le client sera notifié de votre acceptation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 18, 100, 20),
            ),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('demandes')
          .doc(demandeId)
          .update({
            'status': 'acceptee',
            'dateReponse': FieldValue.serverTimestamp(),
          });

      // notification client
      if (currentUser != null) {
        await NotificationHandler.createNotificationForStatusUpdate(
          clientId: data['clientId'],
          demandeId: demandeId,
          status: 'acceptee',
          prestataireName: currentUser.email?.split('@')[0] ?? 'Prestataire',
          typeService: data['typeService'] ?? 'Service',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande acceptée !'),
            backgroundColor: Color.fromARGB(255, 18, 100, 20),
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Date inconnue';
    try {
      if (timestamp is DateTime) {
        final date = timestamp;
        return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {}
    return 'Date inconnue';
  }

  Future<void> _refuserDemande(
    String demandeId,
    Map<String, dynamic> data,
  ) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la demande'),
        content: Text(
          'Voulez-vous refuser cette demande de ${data['clientName']} ?\n\n'
          'Le client sera notifié de votre refus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('demandes')
          .doc(demandeId)
          .update({
            'status': 'refusee',
            'dateReponse': FieldValue.serverTimestamp(),
            'prestataireId': null,
            'prestataireName': null,
            'prestataireTelephone': null,
          });

      // notification client
      if (currentUser != null) {
        await NotificationHandler.createNotificationForStatusUpdate(
          clientId: data['clientId'],
          demandeId: demandeId,
          status: 'refusee',
          prestataireName: currentUser.email?.split('@')[0] ?? 'Prestataire',
          typeService: data['typeService'] ?? 'Service',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande refusée'),
            backgroundColor: Colors.red,
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

  // Lancer l'appli d'appel 
  Future<void> _lancerAppel(String? telephone) async {
    if (telephone == null || telephone.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Numéro non disponible')));
      }
      return;
    }

    final Uri telUri = Uri(scheme: 'tel', path: telephone);
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir l\'application d\'appel'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  // Lancer l'appli SMS
  Future<void> _envoyerMessage(String? telephone) async {
    if (telephone == null || telephone.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Numéro non disponible')));
      }
      return;
    }

    final Uri smsUri = Uri(scheme: 'sms', path: telephone);
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir l\'application de SMS'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}
