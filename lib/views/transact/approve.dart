import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:location/location.dart';
import 'package:lottie/lottie.dart';

class ApprovalScreenData {
  final String merchantPhoto;
  final String merchantName;
  final String amount;
  final String transactionID;
  final String documentID;

  ApprovalScreenData(this.merchantPhoto, this.merchantName, this.amount,
      this.transactionID, this.documentID);
}

class ApprovalScreen extends StatefulWidget {
  final ApprovalScreenData approvalScreenData;

  const ApprovalScreen({super.key, required this.approvalScreenData});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  // <========== Variables ==========>
  Location location = Location();
  late LocationData _locationData;

  // <========== Functions ==========>
  void approveTransaction() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    _locationData = await location.getLocation();

    // Approve the transaction
    final token = await FirebaseAuth.instance.currentUser!.getIdTokenResult();

    var url = Uri.https('api.occomy.com', 'transact/approvetransaction');
    var response = await http.post(url, headers: {
      'Authorization': token.token!,
    }, body: {
      "transactionid": widget.approvalScreenData.documentID,
      "latitude": _locationData.latitude.toString(),
      "longitude": _locationData.longitude.toString(),
    });

    if (response.statusCode == 200) {
      // Show the success animation
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

      // Go back to the previous screen
      await Future.delayed(
        const Duration(seconds: 3),
        () {
          if (mounted) {
            Navigator.pop(context);
            Navigator.pop(context);
            Navigator.pop(context);
          } else {
            GoRouter.of(context).replace('/');
          }
        },
      );
    } else {
      showErrorAlert();
    }
  }

  void declineTransaction() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Decline the transaction
    final token = await FirebaseAuth.instance.currentUser!.getIdTokenResult();
    var url = Uri.https('api.occomy.com', 'transact/declinetransaction');
    var response = await http.post(url, headers: {
      'Authorization': token.token!,
    }, body: {
      "transactionid": widget.approvalScreenData.documentID,
    });
    if (response.statusCode == 200) {
      // Go back to the transact screen
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      showErrorAlert();
    }
  }

  // Alert for errors
  showErrorAlert() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: 'Something went wrong, please try again.',
      btnOkOnPress: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    ).show();
  }

  showLocationError() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Location Required',
      desc:
          'We need to know your location when you are transacting so we can keep you safe.',
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
      appBar: AppBar(
        title: const Text('Approve Transaction',
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
                            child: Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Text(
                                "Approve Transaction",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const Divider(),

                          // Profile picture
                          Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 20),
                            child: CircleAvatar(
                              radius: 80,
                              backgroundColor: Colors.transparent,
                              backgroundImage: MemoryImage(
                                base64Decode(
                                    widget.approvalScreenData.merchantPhoto),
                              ),
                            ),
                          ),

                          // Payment details
                          Text(
                            widget.approvalScreenData.merchantName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),

                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              "Has Requested",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 10),
                            child: Text(
                              "R${double.parse(widget.approvalScreenData.amount).toStringAsFixed(2)}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),

                          // Approve and decline buttons
                          const Divider(),

                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Decline button
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2 -
                                            40,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        declineTransaction();
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.red),
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.white),
                                        shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 15, bottom: 15),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.close),
                                            SizedBox(width: 5),
                                            Text(
                                              "Decline",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Approve button
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2 -
                                            40,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        approveTransaction();
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.green),
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.white),
                                        shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 15, bottom: 15),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.done),
                                            SizedBox(width: 5),
                                            Text(
                                              "Approve",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 10),
                            child: Text(
                              widget.approvalScreenData.transactionID,
                              style: const TextStyle(
                                  color: Color.fromRGBO(169, 169, 169, 1),
                                  fontSize: 16),
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
