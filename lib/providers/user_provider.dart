import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:occomy/models/user_data.dart';

class UserProvider extends ChangeNotifier {
// <========== Attributes ==========>
  StreamSubscription? _userListener;
  UserData _userData = UserData(); // Initialise the variable here

  // <========== Getters ==========>
  UserData get userData => _userData;

  // <========== Methods ==========>

  // Start streaming user data
  void startStreaming({required Function() completion}) {
    _userListener = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .listen((event) {
      // Map the user data
      _userData = UserData(
          uid: event.id,
          apiKey: event["apiKey"],
          balance: double.parse(event["balance"].toString()),
          bankAccountNumber: event["bankAccountNumber"],
          bankName: event["bankName"],
          compliant: event["compliant"],
          depositID: event["depositID"],
          email: event["email"],
          fcmTokens: List.from(event["fcmTokens"]),
          name: event["name"],
          phoneNumber: event["phoneNumber"],
          profilePhoto: event["profilePhoto"]);
      notifyListeners();
      completion();
    });
  }

  // Stop streaming user data
  void stopStreaming({required Function() completion}) async {
    _userListener!.cancel();
    completion();
  }
}
