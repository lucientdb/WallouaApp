import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/notifications_service.dart';
import 'pages/loginPage.dart';
import 'pages/registerPage.dart';
import 'pages/pageClient.dart';
import 'pages/pagePrestataire.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Initialiser les notifications Firebase Messaging
  await NotificationsService.initializeMessaging();

  runApp(WallouApp());
}

class WallouApp extends StatelessWidget {
  const WallouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Application Wallou',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 16, 7, 189),
        ),
      ),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/register': (context) => RegisterPage(),
        '/pageClient': (context) => PageClient(),
        '/pagePrestataire': (context) => PagePrestataire(),
      },
    );
  }
}
