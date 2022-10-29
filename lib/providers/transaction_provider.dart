import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final double amount;
  final DateTime date;
  final String name;
  final String profilePhoto;
  final String type;

  Transaction(this.amount, this.date, this.name, this.profilePhoto, this.type);
}

class TransactionsProvider extends ChangeNotifier {
  // <========== Attributes ==========>
  final List<Transaction> _allTransactions = [];
  final List<Transaction> _recentTransactions = [];
  QuerySnapshot? _depositsSnapshot;
  StreamSubscription? _depositsListener;
  QuerySnapshot? _withdrawalsSnapshot;
  StreamSubscription? _withdrawalsListener;
  QuerySnapshot? _customerSnapshot;
  StreamSubscription? _customerListener;
  QuerySnapshot? _merchantSnapshot;
  StreamSubscription? _merchantListener;

  // <========== Getters ==========>
  List<Transaction> get allTransactions => _allTransactions;
  List<Transaction> get recentTransactions => _recentTransactions;
  QuerySnapshot? get depositsSnapshot => _depositsSnapshot;
  QuerySnapshot? get withdrawalsSnapshot => _withdrawalsSnapshot;
  QuerySnapshot? get customerSnapshot => _customerSnapshot;
  QuerySnapshot? get merchantSnapshot => _merchantSnapshot;

  // <========== Methods ==========>

  // Start streaming deposits
  void startStreamingDeposits() {
    _depositsListener = FirebaseFirestore.instance
        .collection('deposits')
        .where("userID", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .listen((event) {
      _depositsSnapshot = event;
      updateTransactions();
    });
  }

  // Start streaming withdrawals
  void startStreamingWithdrawals() {
    _withdrawalsListener = FirebaseFirestore.instance
        .collection('withdrawals')
        .where("userID", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .listen((event) {
      _withdrawalsSnapshot = event;
      updateTransactions();
    });
  }

  // Start streaming transactions where I was the customer
  void startStreamingCustomerTransactions() {
    _customerListener = FirebaseFirestore.instance
        .collection('transactions')
        .where("customerID", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where("status", isEqualTo: "approved")
        .snapshots()
        .listen((event) {
      _customerSnapshot = event;
      updateTransactions();
    });
  }

  // Start streaming transactions where I was the merchant
  void startStreamingMerchantTransactions() {
    _merchantListener = FirebaseFirestore.instance
        .collection('transactions')
        .where('merchantID', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .listen((event) {
      _merchantSnapshot = event;
      updateTransactions();
    });
  }

  // Update transactions
  void updateTransactions() {
    // Clear the transactions lists
    _allTransactions.clear();
    _recentTransactions.clear();

    // Map deposits
    if (_depositsSnapshot != null) {
      for (var doc in depositsSnapshot!.docs) {
        // Add deposit
        double amount = doc.get('amount').toDouble();
        DateTime date = DateTime.parse(doc.get('date').toDate().toString());
        String type = "deposit";
        _allTransactions.add(Transaction(amount, date, "Deposit", "", type));

        // Check whether the transaction is recent
        if (date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
          _recentTransactions
              .add(Transaction(amount, date, "Deposit", "", type));
        }
      }
    }

    // Map withdrawals
    if (_withdrawalsSnapshot != null) {
      for (var doc in withdrawalsSnapshot!.docs) {
        // Add withdrawal
        double amount = doc.get('amount').toDouble();
        DateTime date = DateTime.parse(doc.get('date').toDate().toString());
        String type = "withdrawal";
        _allTransactions.add(Transaction(amount, date, "Withdrawal", "", type));

        // Add withdrawal fees
        double amount2 = 5.0;
        String type2 = "withdrawal_fees";
        _allTransactions
            .add(Transaction(amount2, date, "Withdrawal Fees", "", type2));

        // Check whether the transaction is recent
        if (date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
          _recentTransactions
              .add(Transaction(amount, date, "Withdrawal", "", type));
          _recentTransactions
              .add(Transaction(amount2, date, "Withdrawal Fees", "", type2));
        }
      }
    }

    // Map transactions where I was the customer
    if (_customerSnapshot != null) {
      for (var doc in customerSnapshot!.docs) {
        // Add customer transaction
        double amount = doc.get('amount').toDouble();
        DateTime date = DateTime.parse(doc.get('date').toDate().toString());
        String name = doc.get('merchantName');
        String profilePhoto = doc.get('merchantProfilePhoto');
        String type = "customer";
        _allTransactions
            .add(Transaction(amount, date, name, profilePhoto, type));

        // Check whether the transaction is recent
        if (date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
          _recentTransactions
              .add(Transaction(amount, date, name, profilePhoto, type));
        }
      }
    }

    // Map transactions where I was the merchant
    if (_merchantSnapshot != null) {
      for (var doc in merchantSnapshot!.docs) {
        // Add merchant transaction
        double amount = doc.get('amount').toDouble();
        DateTime date = DateTime.parse(doc.get('date').toDate().toString());
        String name = doc.get('customerName');
        String profilePhoto = doc.get('customerProfilePhoto');
        String type = "merchant";
        _allTransactions
            .add(Transaction(amount, date, name, profilePhoto, type));

        // Check whether the transaction is recent
        if (date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
          _recentTransactions
              .add(Transaction(amount, date, name, profilePhoto, type));
        }
      }
    }

    // Sort the lists
    _allTransactions.sort((a, b) => a.date.compareTo(b.date));

    // Insert dummy rows on end of every month
    for (int i = 0; i < _allTransactions.length; i++) {
      if (i == 0) {
        int lastDay = DateTime(_allTransactions[i].date.year,
                _allTransactions[i].date.month + 1, 0)
            .day;
        _allTransactions.insert(
            0,
            Transaction(
                0.0,
                DateTime(_allTransactions[i].date.year,
                    _allTransactions[i].date.month, lastDay),
                "",
                "",
                "divider"));
      } else if (_allTransactions[i].date.month !=
          _allTransactions[i - 1].date.month) {
        int lastDay = DateTime(_allTransactions[i].date.year,
                _allTransactions[i].date.month + 1, 0)
            .day;
        _allTransactions.insert(
            i,
            Transaction(
                0.0,
                DateTime(_allTransactions[i].date.year,
                    _allTransactions[i].date.month, lastDay),
                "",
                "",
                "divider"));
      }
    }

    // Sort the lists
    _allTransactions.sort((a, b) => b.date.compareTo(a.date));
    _recentTransactions.sort((a, b) => b.date.compareTo(a.date));

    notifyListeners();
  }

  // Start streaming transactions
  void startStreaming() {
    startStreamingDeposits();
    startStreamingWithdrawals();
    startStreamingCustomerTransactions();
    startStreamingMerchantTransactions();
  }

  // Stop streaming transactions
  void stopStreaming({required Function() completion}) async {
    _depositsListener!.cancel();
    _withdrawalsListener!.cancel();
    _customerListener!.cancel();
    _merchantListener!.cancel();
    completion();
  }
}
