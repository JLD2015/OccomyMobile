import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:occomy/providers/user_provider.dart';
import 'package:occomy/views/transact/approve.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class TransactScreen extends StatefulWidget {
  const TransactScreen({super.key});

  @override
  State<TransactScreen> createState() => _TransactScreenState();
}

class _TransactScreenState extends State<TransactScreen> {
  // <========== Variables ==========>
  final _formKey = GlobalKey<FormState>();
  final transactionIDController = TextEditingController();

  // <========== Functions ==========>
  String? validateTransactionID(String? value) {
    String pattern = r"^[A-Z0-9]{8,8}$";
    RegExp regex = RegExp(pattern);
    if (value == null || value.isEmpty || !regex.hasMatch(value)) {
      transactionIDController.clear();
      return 'Invalid transaction ID';
    } else {
      return null;
    }
  }

  void enterTransactionID(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text(
                      "Transaction ID",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Text(
                    "Transaction ID can be found on either side of an Occomy QR Code",
                    textAlign: TextAlign.center,
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 15),
                          child: TextFormField(
                            controller: transactionIDController,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                labelText: 'Enter ID',
                                prefixIcon: const Icon(Icons.abc_rounded)),
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              UpperCaseTextFormatter(),
                            ],
                            validator: (value) => validateTransactionID(value),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Validate the input fields
                              if (_formKey.currentState!.validate()) {
                                lookupTransaction();
                              }
                            },
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            child: const Padding(
                                padding: EdgeInsets.all(15),
                                child: Text(
                                  "Proceed",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  void lookupTransaction() {
    // Show loading animation
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        });

    // Retrieve the transaction
    FirebaseFirestore.instance
        .collection("transactions")
        .where("transactionID", isEqualTo: transactionIDController.text.trim())
        .get()
        .then(
      (res) {
        if (res.docs.isEmpty) {
          Navigator.pop(context);
          Navigator.pop(context);
          transactionIDController.clear();
          showLookupError();
        } else {
          final data = res.docs[0].data();

          // Make sure the user isn't transacting with themselves
          if (data["merchantID"] == FirebaseAuth.instance.currentUser!.uid) {
            showSelfTransactionDialogue();
          } else {
            var merchantPhoto = data["merchantProfilePhoto"];
            var merchantName = data["merchantName"];
            var amount = data["amount"].toString();
            var transactionID = data["transactionID"];
            var documentID = res.docs[0].id;

            var approvalScreenData = ApprovalScreenData(
                merchantPhoto, merchantName, amount, transactionID, documentID);

            Navigator.pop(context);
            Navigator.pop(context);
            transactionIDController.clear();
            GoRouter.of(context)
                .push('/approvalscreen', extra: approvalScreenData);
          }
        }
      },
      onError: (e) {
        Navigator.pop(context);
        Navigator.pop(context);
        transactionIDController.clear();
        showLookupError();
      },
    );
  }

  Future<bool> ensureLocationPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
    ].request();

    // Make sure we have both permissions
    if (statuses[Permission.location] == PermissionStatus.granted) {
      return true;
    } else {
      // If we don't have permissions for location
      if (statuses[Permission.location] != PermissionStatus.granted) {
        await Permission.location.request();
      }
      // Check whether we have location permission again
      if (statuses[Permission.location] == PermissionStatus.granted) {
        return true;
      } else {
        permissionsAlert();
        return false;
      }
    }
  }

  // Show alert for permissions
  permissionsAlert() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Permissions',
      desc: 'Please ensure that location permissions have been granted',
      btnOkOnPress: () {
        openAppSettings();
      },
    ).show();
  }

  showLookupError() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: 'Could not find transaction, please try again.',
      btnOkOnPress: () {},
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

  // <========== Page dissapears ==========>
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    transactionIDController.dispose();

    super.dispose();
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: Column(
            children: [
              // Card section
              AspectRatio(
                aspectRatio: 8.56 / 5.398,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                    image: DecorationImage(
                      image: AssetImage(
                          "assets/images/credit_card_background.jpg"),
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.center,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          SizedBox(
                            width: 80,
                            child: Padding(
                              padding: EdgeInsets.only(top: 15, left: 15),
                              child: Image(
                                image: AssetImage("assets/images/logo.png"),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(right: 15),
                              child: SizedBox(
                                width: 60,
                                child: Image(
                                    image: AssetImage(
                                        "assets/images/credit_card_chip.png")),
                              ),
                            )
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 25, left: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.read<UserProvider>().userData.name,
                                  style: const TextStyle(
                                      color: Color.fromRGBO(75, 75, 75, 1),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  context
                                      .read<UserProvider>()
                                      .userData
                                      .depositID,
                                  style: const TextStyle(
                                      color: Color.fromRGBO(75, 75, 75, 1),
                                      fontSize: 14),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Buttons
              Expanded(
                child: GridView.count(
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  crossAxisCount: 2,
                  children: [
                    // Request payment button
                    ElevatedButton(
                      onPressed: () {
                        GoRouter.of(context).push('/requestpaymentscreen');
                      },
                      style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.attach_money_rounded,
                            size: 60,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              "Request Payment",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),
                    // Scan QR code button
                    ElevatedButton(
                      onPressed: () async {
                        var permissionStatus =
                            await ensureLocationPermissions();
                        if (permissionStatus == true) {
                          if (!mounted) return;
                          GoRouter.of(context).push('/qrscannerscreen');
                        }
                      },
                      style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 60,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              "Scan QR Code",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),
                    // Enter code button
                    ElevatedButton(
                      onPressed: () {
                        enterTransactionID(context);
                      },
                      style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.data_object_rounded,
                            size: 60,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              "Transaction ID",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Used for making keyboard inputs uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
