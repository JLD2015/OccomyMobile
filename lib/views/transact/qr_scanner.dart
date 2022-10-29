import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:occomy/views/transact/approve.dart';
import 'package:go_router/go_router.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  // <========== Variables ==========>

  // <========== Functions ==========>
  void qrCodeFound(String qrCode) {
    // Confirms QR code was found
    HapticFeedback.vibrate();

    // Show loading screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Retrieve transaction
    var transactionID = json.decode(qrCode)["transactionID"];

    FirebaseFirestore.instance
        .collection("transactions")
        .doc(transactionID)
        .get()
        .then(
      (DocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Make sure the user isn't transacting with themselves
        if (data["merchantID"] == FirebaseAuth.instance.currentUser!.uid) {
          showSelfTransactionDialogue();
        } else {
          var merchantPhoto = data["merchantProfilePhoto"];
          var merchantName = data["merchantName"];
          var amount = data["amount"].toString();
          var transactionID = data["transactionID"];
          var documentID = doc.id;

          var approvalScreenData = ApprovalScreenData(
              merchantPhoto, merchantName, amount, transactionID, documentID);

          Navigator.pop(context);
          Navigator.pop(context);
          GoRouter.of(context)
              .push('/approvalscreen', extra: approvalScreenData);
        }
      },
    );
    () => showErrorDialogue();
  }

  // Show alert if firestore document cant be found
  showErrorDialogue() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: 'Please try again.',
      btnOkOnPress: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    ).show();
  }

  // Show alert if user tries transacting with themselves
  showSelfTransactionDialogue() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: 'You cannot transact with yourself.',
      btnOkOnPress: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    ).show();
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Code')),
      body: Stack(
        children: [
          MobileScanner(
              allowDuplicates: false,
              onDetect: (barcode, args) {
                if (barcode.rawValue == null) {
                  debugPrint('Failed to scan Barcode');
                } else {
                  qrCodeFound(barcode.rawValue!);
                }
              }),
          Center(
            child: SizedBox(
              width: 300,
              child: Image.asset("assets/images/qr_viewfinder.png"),
            ),
          ),
        ],
      ),
    );
  }
}
