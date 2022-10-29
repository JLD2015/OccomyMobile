import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:occomy/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentTagScreen extends StatefulWidget {
  final String amount;
  final String documentID;
  final String transactionID;
  const PaymentTagScreen(
      {super.key,
      required this.amount,
      required this.documentID,
      required this.transactionID});

  @override
  State<PaymentTagScreen> createState() => _PaymentTagScreenState();
}

class _PaymentTagScreenState extends State<PaymentTagScreen> {
  // <========== Variables ==========>
  late StreamSubscription<DocumentSnapshot> transactionListener;

  // <========== Page appears ==========>
  @override
  void initState() {
    // We need to monitor the transaction
    transactionListener = FirebaseFirestore.instance
        .collection("transactions")
        .doc(widget.documentID)
        .snapshots()
        .listen((event) async {
      // Check if the transaction was declined
      if (event.data()!["status"] == "declined") {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: SizedBox(
              height: 300,
              width: 300,
              child: Lottie.asset('assets/lottie/failed.json', repeat: false),
            ),
          ),
        );

        await Future.delayed(
          const Duration(seconds: 4),
          () {
            if (mounted) {
              Navigator.pop(context);
              Navigator.pop(context);
            } else {
              GoRouter.of(context).replace('/');
            }
          },
        );
      }

      // Check if the transaction was approved
      if (event.data()!["status"] == "approved") {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: SizedBox(
              height: 300,
              width: 300,
              child: Lottie.asset('assets/lottie/success.json', repeat: false),
            ),
          ),
        );

        await Future.delayed(
          const Duration(seconds: 4),
          () {
            if (mounted) {
              Navigator.pop(context);
              Navigator.pop(context);
            } else {
              GoRouter.of(context).replace('/');
            }
          },
        );
      }
    });

    super.initState();
  }

  // <========== Page dissapears ==========>
  @override
  void dispose() {
    transactionListener.cancel();

    super.dispose();
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Request',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Card(
                  color: Colors.transparent,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.fromRGBO(57, 110, 176, 1),
                          Color.fromRGBO(46, 76, 109, 1),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          // Heading
                          const SizedBox(
                            width: double.infinity,
                            child: Text(
                              "Once-Off Payment",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Divider(),

                          // Profile picture
                          Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 20),
                            child: CircleAvatar(
                                radius: 80,
                                backgroundColor: Colors.transparent,
                                backgroundImage: MemoryImage(base64Decode(
                                    context
                                        .watch<UserProvider>()
                                        .userData
                                        .profilePhoto))),
                          ),

                          // QR Code section
                          Text(
                            context.read<UserProvider>().userData.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                RotatedBox(
                                  quarterTurns: 3,
                                  child: Text(
                                    widget.transactionID,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(15)),
                                    color: Colors.white,
                                  ),
                                  child: QrImage(
                                    data:
                                        "{\"transactionID\": \"${widget.documentID}\"}",
                                    version: QrVersions.auto,
                                    size: 200.0,
                                    foregroundColor: Colors.black,
                                    embeddedImage: const AssetImage(
                                        "assets/images/logo_qr.png"),
                                    embeddedImageStyle: QrEmbeddedImageStyle(
                                      size: const Size(30, 33),
                                    ),
                                  ),
                                ),
                                RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(
                                    widget.transactionID,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "R ${double.parse(widget.amount).toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold),
                          ),

                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.only(top: 10, bottom: 10),
                            child: Text(
                              "Scan Tag To Pay",
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
