import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseInitialization {
  static Future<bool> requestNotificationPermissions() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // print('✅ User granted permission');
      return true;
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      // print('⚠️ User granted provisional permission');
      return true;
    } else {
      // print('❌ User declined or has not accepted permission');
      return false;
    }
  }
}

Future<void> initializeFirebaseApp() async {
  // final firebaseOptions = switch (appFlavor) {
  // 'prod' => prod.DefaultFirebaseOptions.currentPlatform,
  // 'dev' => dev.DefaultFirebaseOptions.currentPlatform,
  // _ => dev.DefaultFirebaseOptions.currentPlatform,
  // };

  // await Firebase.initializeApp(options: firebaseOptions);
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await initializeFirebaseApp();
}
