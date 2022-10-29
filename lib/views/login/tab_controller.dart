import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:occomy/providers/requests_provider.dart';
import 'package:occomy/views/send/send.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:occomy/providers/transaction_provider.dart';
import 'package:occomy/providers/user_provider.dart';
import 'package:occomy/views/home/home.dart';
import 'package:occomy/views/settings/settings.dart';
import 'package:occomy/views/transact/transact.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OccomyTabController extends StatefulWidget {
  const OccomyTabController({super.key});

  @override
  State<OccomyTabController> createState() => _OccomyTabControllerState();
}

class _OccomyTabControllerState extends State<OccomyTabController>
    with WidgetsBindingObserver {
  // <========== Variables ==========>
  int _selectedIndex = 0;
  bool loadApp = false;

  // <========== Functions ==========>
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Save fcm token to Firestore
  void saveFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? fcmToken = prefs.getString('fcmToken');
    if (fcmToken != null) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .update({
        "fcmTokens": FieldValue.arrayUnion([fcmToken]),
      });
    }
  }

// <========== Page Loads ==========>
  @override
  void initState() {
    // Start streaming data
    if (FirebaseAuth.instance.currentUser != null) {
      context.read<UserProvider>().startStreaming(completion: () {
        context.read<TransactionsProvider>().startStreaming();
        context.read<RequestsProvider>().startStreaming();
        // Show the screen
        setState(() {
          loadApp = true;
        });

        // Save the notification token to firestore
        saveFCMToken();
      });
    }

    super.initState();
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loadApp == true
          ? Center(
              child: LayoutBuilder(builder: (context, constaraints) {
                if (_selectedIndex == 0) {
                  return const HomeScreen();
                } else if (_selectedIndex == 1) {
                  return const TransactScreen();
                } else if (_selectedIndex == 2) {
                  return const SendScreen();
                } else {
                  return const SettingsScreen();
                }
              }),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
      bottomNavigationBar: BottomNavigationBar(
        // Navigation settings
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromRGBO(57, 110, 176, 1),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Theme.of(context).colorScheme.secondary,

        // List of navigation items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Home",
            backgroundColor: Colors.transparent,
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.credit_card), label: "Transact"),
          BottomNavigationBarItem(icon: Icon(Icons.send), label: "Send"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings")
        ],
      ),
    );
  }
}
