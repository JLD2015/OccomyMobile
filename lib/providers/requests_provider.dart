import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentRequest {
  final double amount;
  final String description;
  final String documentID;
  final String merchantName;
  final String profilePhoto;
  final String transactionID;

  PaymentRequest(
      {required this.amount,
      required this.description,
      required this.documentID,
      required this.merchantName,
      required this.profilePhoto,
      required this.transactionID});
}

class RequestsProvider extends ChangeNotifier {
  // <========== Attributes ==========>
  final List<PaymentRequest> _allRequests = [];
  QuerySnapshot? _requestsSnapshot;
  StreamSubscription? _requestsListener;

  // <========== Getters ==========>
  List<PaymentRequest> get allRequests => _allRequests;
  QuerySnapshot? get requestsSnapshot => _requestsSnapshot;

  // <========== Methods ==========>

  // Start streaming requests
  void startStreaming() {
    _requestsListener = FirebaseFirestore.instance
        .collection('transactions')
        .where("customerID", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where("status", isEqualTo: "requested")
        .snapshots()
        .listen((event) {
      _requestsSnapshot = event;
      updateRequests();
    });
  }

  void updateRequests() {
    // Clear the requests list
    _allRequests.clear();

    // Map requests
    if (_requestsSnapshot != null) {
      for (var doc in requestsSnapshot!.docs) {
        // Add request
        double amount = doc["amount"].toDouble();
        String description = doc.get('description');
        String documentID = doc.id;
        String merchantName = doc.get('merchantName');
        String profilePhoto = doc.get('merchantProfilePhoto');
        String transactionID = doc.get("transactionID");
        _allRequests.add(
          PaymentRequest(
              amount: amount,
              description: description,
              documentID: documentID,
              merchantName: merchantName,
              profilePhoto: profilePhoto,
              transactionID: transactionID),
        );
      }
    }

    notifyListeners();
  }

  // Stop streaming user data
  void stopStreaming({required Function() completion}) async {
    _requestsListener!.cancel();
    completion();
  }
}
