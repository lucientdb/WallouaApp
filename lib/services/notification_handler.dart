import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationHandler {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Crée une notification pour une nouvelle demande assignée au prestataire
  static Future<void> createNotificationForNewDemande({
    required String prestataireId,
    required String demandeId,
    required String clientName,
    required String typeService,
    required String clientId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(prestataireId)
          .collection('notifications')
          .add({
            'title': 'Nouvelle demande de dépannage',
            'body': '$clientName demande $typeService',
            'type': 'newDemande',
            'demandeId': demandeId,
            'clientId': clientId,
            'clientName': clientName,
            'typeService': typeService,
            'isRead': false,
            'dateCreated': FieldValue.serverTimestamp(),
          });
      print('Notification créée pour prestataire $prestataireId');
    } catch (e) {
      print('Erreur createNotificationForNewDemande: $e');
    }
  }

  /// Crée une notification quand une demande est acceptée ou refusée
  static Future<void> createNotificationForStatusUpdate({
    required String clientId,
    required String demandeId,
    required String status, 
    required String prestataireName,
    required String typeService,
  }) async {
    try {
      String title, body;
      if (status == 'acceptee') {
        title = 'Demande acceptée !';
        body = '$prestataireName a accepté votre demande de $typeService';
      } else if (status == 'refusee') {
        title = 'Demande refusée';
        body = '$prestataireName a refusé votre demande de $typeService';
      } else {
        return;
      }

      await _firestore
          .collection('users')
          .doc(clientId)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'type': 'demandeStatusUpdate',
            'demandeId': demandeId,
            'status': status,
            'prestataireName': prestataireName,
            'typeService': typeService,
            'isRead': false,
            'dateCreated': FieldValue.serverTimestamp(),
          });
      print('Notification créée pour client $clientId');
    } catch (e) {
      print('Erreur createNotificationForStatusUpdate: $e');
    }
  }

  static Future<int> getUnreadNotificationCount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return 0;

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Erreur getUnreadNotificationCount: $e');
      return 0;
    }
  }

  static Stream<int> getUnreadNotificationCountStream() {
    try {
      User? user = _auth.currentUser;
      if (user == null) return Stream.value(0);

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('Erreur getUnreadNotificationCountStream: $e');
      return Stream.value(0);
    }
  }

  /// Récupère toutes les notifications
  static Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    try {
      User? user = _auth.currentUser;
      if (user == null) return Stream.value([]);

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('dateCreated', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return {'id': doc.id, ...doc.data()};
            }).toList();
          });
    } catch (e) {
      print('Erreur getNotificationsStream: $e');
      return Stream.value([]);
    }
  }

  /// Marque une notification comme lue
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Erreur markNotificationAsRead: $e');
    }
  }

  /// Marque toutes les notifications comme lues
  static Future<void> markAllNotificationsAsRead() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Erreur markAllNotificationsAsRead: $e');
    }
  }

  /// Supprime une notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Erreur deleteNotification: $e');
    }
  }
}
