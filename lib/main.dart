import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:labours/auth/forgot-password.dart';
import 'package:labours/screens/history.dart';
import 'package:labours/screens/home.dart';
import 'package:labours/screens/location.dart';
import 'package:labours/screens/location_filtter.dart';
import 'package:labours/screens/notification_service.dart';
import 'package:labours/screens/notifications.dart';
import 'package:labours/screens/setting.dart';

import 'auth/login.dart';
import 'auth/signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  requestNotificationPermission();
  runApp(MyApp());
}

void requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("✅ User granted notification permission");
  } else {
    print("❌ User denied notification permission");
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Labours Junction',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthCheck(),
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
        '/location': (context) => LocationSelectionPage(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/setting': (context) => SettingsPage(),
        '/messages': (context) => NotificationsScreen(),
        '/history': (context) => History(),
        '/profile': (context) => EditProfilePage(),
        '/filter': (context) => LocationFilterPage(),
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    NotificationService().initialize();
    checkUserStatus();
  }

  void checkUserStatus() async {
    print("Checking user status...");

    User? user = FirebaseAuth.instance.currentUser;
    await Future.delayed(Duration(milliseconds: 500));

    if (!mounted) return;

    if (user == null) {
      print("No user found. Navigating to Login Page...");
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
      return;
    }

    print("User found: ${user.uid}");
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (!mounted) return;

    if (userDoc.exists && userDoc.data() != null) {
      var data = userDoc.data() as Map<String, dynamic>;
      print("User data: $data");

      if (data.containsKey('city') && data.containsKey('state')) {
        print("User location exists. Navigating to Home Page...");
        Future.microtask(
          () => Navigator.pushReplacementNamed(context, '/home'),
        );
      } else {
        print("Location missing. Navigating to Location Selection...");
        Future.microtask(
          () => Navigator.pushReplacementNamed(context, '/location'),
        );
      }
    } else {
      print(
        "User document does not exist. Navigating to Location Selection...",
      );
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, '/location'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.teal,
          ), // ✅ Teal color
        ),
      ),
    );
  }
}
