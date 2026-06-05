import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();
    print('🔹 Permission granted: ${settings.authorizationStatus}');

    // Get the FCM token
    String? token = await _firebaseMessaging.getToken();
    print("🔹 FCM Token Retrieved: $token");

    if (token != null) {
      await saveDeviceToken(token);
    }

    // Listen for token updates
    listenForTokenRefresh();
    listenForMessages();
  }

  // Retrieve and save FCM token
  Future<void> getDeviceToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print("🔹 FCM Token: $token");
      await saveDeviceToken(token);
    }
  }

  // Save the FCM token to Firestore
  Future<void> saveDeviceToken(String token) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'deviceToken': token,
      }, SetOptions(merge: true));
      print('✅ FCM Token saved to Firestore: $token');
    } else {
      print('❌ No logged-in user found.');
    }
  }

  // Listen for FCM token refresh
  void listenForTokenRefresh() {
    _firebaseMessaging.onTokenRefresh
        .listen((newToken) {
          print("🔹 New FCM Token received: $newToken");
          saveDeviceToken(newToken); // Save the new token
        })
        .onError((err) {
          print("❌ Token Refresh Error: $err");
        });
  }

  // Listen for foreground and background notifications
  void listenForMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('🔔 Notification Received: ${message.notification!.title}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 User tapped on the notification');
    });
  }
}
