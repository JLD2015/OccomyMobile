import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:occomy/views/login/login.dart';
import 'package:occomy/views/login/tab_controller.dart';
import 'package:occomy/views/login/verify_email.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/requests_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';

class AutoLogin extends StatefulWidget {
  const AutoLogin({super.key});

  @override
  State<AutoLogin> createState() => _AutoLoginState();
}

class _AutoLoginState extends State<AutoLogin> with WidgetsBindingObserver {
  // <========== Variables ==========>
  final LocalAuthentication localAuth = LocalAuthentication();
  bool shouldBlur = false;

  // <========== Functions ==========>
  // Used for performing biometric authentication when user logs in
  void appEntersForeground() async {
    final prefs = await SharedPreferences.getInstance();
    final secureLoginState = prefs.getBool('secureLogin') ?? false;
    final loginState = prefs.getBool('isLoggedIn') ?? false;

    // If we are not logged in then we run biometrics
    if (!loginState) {
      if (secureLoginState == true) {
        bool didAuthenticate = await localAuth.authenticate(
            localizedReason: "You have selected to use secure login.");

        if (didAuthenticate) {
          // Set the login state
          await prefs.setBool('isLoggedIn', true);
        } else {
          // If the user is not authenticated then we need to sign them out
          // Stop all of the listeners
          if (!mounted) return;
          context.read<UserProvider>().stopStreaming(completion: () {
            context.read<TransactionsProvider>().stopStreaming(
                completion: () async {
              context.read<RequestsProvider>().stopStreaming(
                  completion: () async {
                // Logout the user
                FirebaseAuth.instance.signOut();

                // Disable secure login
                await prefs.setBool('secureLogin', false);
              });
            });
          });
        }
      }
    }
  }

  // Used for setting login state when user closes app
  void appEntersBackground() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }

  // <========== Page Loads ==========>
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  // <========== Page Dissapears ==========>
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

// <========== Monitor Lifecycle ==========>
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Control app switcher cover
    setState(() {
      shouldBlur = state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused;
    });

    // Control biometrics
    switch (state) {
      case AppLifecycleState.paused:
        appEntersBackground();
        break;
      case AppLifecycleState.resumed:
        appEntersForeground();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If we are waiting due to slow network connection
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        // If an error occurs
        else if (snapshot.hasError) {
          return const Center(
            child: Text("An error occurred"),
          );
        }
        // If the user is logged in
        else if (snapshot.hasData) {
          // Check whether the user's email has been verified
          if (FirebaseAuth.instance.currentUser!.emailVerified) {
            return !shouldBlur
                ? const OccomyTabController()
                : Container(
                    height: double.infinity,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/blur_background.jpg"),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 1.0,
                        sigmaY: 1.0,
                      ),
                      child: Container(
                        height: double.infinity,
                        width: double.infinity,
                        color: Colors.grey.withOpacity(0.2),
                        child: Center(
                          child: Image.asset(
                            "assets/images/logo.png",
                            height: 250,
                            width: 250,
                          ),
                        ),
                      ),
                    ),
                  );
          } else {
            return const VerifyEmailScreen();
          }
        }
        // If the user is not logged in
        else {
          return const LoginScreen();
        }
      },
    ));
  }
}
