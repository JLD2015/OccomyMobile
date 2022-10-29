import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:occomy/providers/requests_provider.dart';
import 'package:occomy/providers/transaction_provider.dart';
import 'package:occomy/providers/user_provider.dart';
import 'package:occomy/routes.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // We don't do anything in here
}

void main() async {
  // Configure firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run app
  runApp(const Occomy());
}

class Occomy extends StatefulWidget {
  const Occomy({super.key});

  @override
  State<Occomy> createState() => _OccomyState();
}

class _OccomyState extends State<Occomy> {
  // <========== Variables ==========>
  late final FirebaseMessaging _messaging;

  // <========== Functions ==========>
  // Used for getting fcm token
  void requestAndRegisterNotifications() async {
    // 1. Initiate firebase messaging
    _messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // 3. Store the fcm token
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _messaging.getToken();
      // Save the token locally on the device
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcmToken', token!);
    }
  }

  // <========== Page Loads ==========>
  @override
  void initState() {
    requestAndRegisterNotifications();
    super.initState();
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // User provider
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Transactions Provider
        ChangeNotifierProvider(create: (_) => TransactionsProvider()),
        // Requests Provider
        ChangeNotifierProvider(create: (_) => RequestsProvider()),
        // Router provider
        Provider<OccomyRouter>(
          lazy: false,
          create: (BuildContext createContext) => OccomyRouter(),
        )
      ],
      child: Builder(
        builder: (BuildContext context) {
          final router = Provider.of<OccomyRouter>(context).router;
          return MaterialApp.router(
              // Light theme
              theme: ThemeData(
                brightness: Brightness.light,
                colorSchemeSeed: Colors.blue,
                fontFamily: 'Open Sans',
                useMaterial3: true,
                textTheme: const TextTheme(
                  bodyText1: TextStyle(color: Colors.black),
                ),
              ),

              // Dark theme
              darkTheme: ThemeData(
                colorSchemeSeed: Colors.blue,
                brightness: Brightness.dark,
                useMaterial3: true,
                textTheme: const TextTheme(
                  bodyText1: TextStyle(color: Colors.white),
                ),
              ),

              // Debug marker
              debugShowCheckedModeBanner: false,

              // Router
              routerConfig: router,

              // App title
              title: "Occomy");
        },
      ),
    );
  }
}
