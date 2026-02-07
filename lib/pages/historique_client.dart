import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoriqueClient extends StatefulWidget {
  const HistoriqueClient({super.key});

  @override
  _HistoriqueClientState createState() => _HistoriqueClientState();
}

class _HistoriqueClientState extends State<HistoriqueClient> {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 16, 7, 189),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 16, 7, 189),
        elevation: 0,
        title: const Text(
          'Historique de mes demandes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _supprimerToutHistorique,
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.white,
                      size: 36,
                    ),
                    tooltip: 'Supprimer tout l\'historique',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
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
                            .where('clientId', isEqualTo: user.uid)
                            .orderBy('dateCreation', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Erreur: ${snapshot.error}'),
                            );
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.history,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Aucune demande pour le moment',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              DocumentSnapshot doc = snapshot.data!.docs[index];
                              Map<String, dynamic> data =
                                  doc.data() as Map<String, dynamic>;
                              String status = data['status'] ?? 'en_attente';
                              bool estUrgence = data['estUrgence'] ?? false;
                              Color statusColor = _getStatusColor(status);
                              String statusText = _getStatusText(status);
                              IconData statusIcon = _getStatusIcon(status);
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.only(bottom: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: estUrgence
                                      ? const BorderSide(
                                          color: Colors.red,
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Infos
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      statusIcon,
                                                      color: statusColor,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      statusText,
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    if (estUrgence)
                                                      Container(
                                                        margin:
                                                            const EdgeInsets.only(
                                                              left: 6,
                                                            ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 1,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          'Urgence',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                Text(
                                                  _formatDate(
                                                    data['dateCreation'],
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 7),
                                            Text(
                                              data['description'] ??
                                                  'Sans titre',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (data['adresse'] != null &&
                                                data['adresse']
                                                    .toString()
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    color: Colors.red,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Expanded(
                                                    child: Text(
                                                      data['adresse'],
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.black54,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            if (data['typeService'] != null &&
                                                data['typeService']
                                                    .toString()
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .miscellaneous_services,
                                                    color: Colors.deepPurple,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Expanded(
                                                    child: Text(
                                                      data['typeService'],
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.black54,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            if ((data['prestataireNom'] !=
                                                        null &&
                                                    data['prestataireNom']
                                                        .toString()
                                                        .isNotEmpty) ||
                                                (data['prestataireName'] !=
                                                        null &&
                                                    data['prestataireName']
                                                        .toString()
                                                        .isNotEmpty)) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.person,
                                                    color: Colors.blue,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Expanded(
                                                    child: Text(
                                                      data['prestataireNom']
                                                                  ?.toString()
                                                                  .isNotEmpty ==
                                                              true
                                                          ? data['prestataireNom']
                                                          : (data['prestataireName'] ??
                                                                ''),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.black54,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _modifierDemande(
                                                        doc.id,
                                                        data,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.orange,
                                                    size: 14,
                                                  ),
                                                  label: const Text(
                                                    'Modifier',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 4,
                                                        ),
                                                    minimumSize: const Size(
                                                      60,
                                                      28,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _supprimerDemande(doc.id),
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                    size: 14,
                                                  ),
                                                  label: const Text(
                                                    'Supprimer',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 4,
                                                        ),
                                                    minimumSize: const Size(
                                                      60,
                                                      28,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Boutons 
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 20),
                                          if (data['prestataireTel'] != null &&
                                              data['prestataireTel']
                                                  .toString()
                                                  .isNotEmpty)
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _appelerPrestataire(
                                                    data['prestataireTel'],
                                                  ),
                                              icon: const Icon(
                                                Icons.phone,
                                                color: Colors.green,
                                                size: 13,
                                              ),
                                              label: const Text(
                                                'Appeler',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 3,
                                                      vertical: 3,
                                                    ),
                                                minimumSize: const Size(55, 22),
                                              ),
                                            ),
                                          if (data['prestataireTel'] != null &&
                                              data['prestataireTel']
                                                  .toString()
                                                  .isNotEmpty)
                                            OutlinedButton.icon(
                                              onPressed: () => _envoyerSMS(
                                                data['prestataireTel'],
                                              ),
                                              icon: const Icon(
                                                Icons.message,
                                                color: Colors.blue,
                                                size: 13,
                                              ),
                                              label: const Text(
                                                'Message',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 3,
                                                      vertical: 3,
                                                    ),
                                                minimumSize: const Size(55, 22),
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _modifierDemande(
    String demandeId,
    Map<String, dynamic> data,
  ) async {
    final TextEditingController descriptionController = TextEditingController(
      text: data['description'] ?? '',
    );

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la demande'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 16, 7, 189),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('demandes')
            .doc(demandeId)
            .update({'description': descriptionController.text.trim()});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demande modifiée avec succès'),
              backgroundColor: const Color.fromARGB(255, 18, 100, 20),
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

    descriptionController.dispose();
  }

  Future<void> _supprimerDemande(String demandeId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la demande'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette demande ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('demandes')
            .doc(demandeId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demande supprimée avec succès'),
              backgroundColor: const Color.fromARGB(255, 18, 100, 20),
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
  }

  Future<void> _supprimerToutHistorique() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer tout l\'historique'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes vos demandes ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        var demandes = await FirebaseFirestore.instance
            .collection('demandes')
            .where('clientId', isEqualTo: user.uid)
            .get();
        for (var doc in demandes.docs) {
          await doc.reference.delete();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Historique supprimé avec succès'),
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
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_attente':
        return const Color.fromARGB(255, 201, 121, 2);
      case 'en_attente_reponse':
        return const Color.fromARGB(255, 16, 7, 189);
      case 'acceptee':
        return const Color.fromARGB(255, 18, 100, 20);
      case 'refusee':
        return Colors.red;
      case 'terminee':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'en_attente_reponse':
        return 'En cours';
      case 'acceptee':
        return 'Acceptée';
      case 'refusee':
        return 'Refusée';
      case 'terminee':
        return 'Terminée';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'en_attente':
        return Icons.pending;
      case 'en_attente_reponse':
        return Icons.hourglass_empty;
      case 'acceptee':
        return Icons.check_circle;
      case 'refusee':
        return Icons.cancel;
      case 'terminee':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Date inconnue';

    try {
      DateTime date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Date inconnue';
    }
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
}
