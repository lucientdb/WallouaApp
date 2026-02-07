import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsService {
  // Sauvegarde le token FCM dans Firestore
  static Future<void> saveTokenToFirestore(User? user) async {
    if (user == null) return;
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': fcmToken},
      );
    } catch (e) {
      // Si le doc n'existe pas encore, on le crée avec le token
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken == null) return;
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': fcmToken,
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // Initialise la gestion des messages Firebase
  static Future<void> initializeMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Demander la permission de notifier (iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Permissions notifications: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message reçu en foreground: ${message.notification?.title}');

      if (message.notification != null) {
        _showNotificationDialog(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          data: message.data,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification cliquée: ${message.notification?.title}');
      _handleNotificationClick(message.data);
    });
  }

  static void _showNotificationDialog({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    print('Notification Dialog: $title - $body');
    print('Data: $data');
  }

  static void _handleNotificationClick(Map<String, dynamic> data) {
    print('Handling notification click: $data');
  }
}
