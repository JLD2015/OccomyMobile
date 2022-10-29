import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  // <========== Variables ==========>
  String amount = '0.00';

  // <========== Functions ==========>
  void updateAmount(String input) {
    // Make sure the input is a valid number
    if (amount.contains(".") && input == ".") {
      // Display toast
      Fluttertoast.showToast(
          msg: "Please enter a valid amount",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      setState(() {
        amount = "0.00";
      });
      return;
    }
    if (amount == "0.00") {
      setState(() {
        amount = input;
      });
    } else {
      if (amount.contains(".")) {
        if (amount.substring(amount.indexOf('.')).length < 3) {
          setState(() {
            amount = amount + input;
          });
        }
      } else {
        setState(() {
          amount = amount + input;
        });
      }
    }
  }

  void sendFunds() async {
    // Check whether we have location and contacts permissions
    var permissionStatus = await ensureContactsAndLocationPermissions();
    if (permissionStatus == true) {
      if (!mounted) return;
      GoRouter.of(context).push('/recipientscreen/$amount');
      setState(() {
        amount = '0.00';
      });
    }
  }

  void requestFunds() async {
    // Check whether we have location and contacts permissions
    var permissionStatus = await ensureContactsAndLocationPermissions();
    if (permissionStatus == true) {
      if (!mounted) return;
      GoRouter.of(context).push('/sendrequestscreen/$amount');
      setState(() {
        amount = '0.00';
      });
    }
  }

  Future<bool> ensureContactsAndLocationPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.contacts,
      Permission.location,
    ].request();

    // Make sure we have both permissions
    if (statuses[Permission.contacts] == PermissionStatus.granted &&
        statuses[Permission.location] == PermissionStatus.granted) {
      return true;
    } else {
      // If we don't have permissions for contacts
      if (statuses[Permission.contacts] != PermissionStatus.granted) {
        await Permission.contacts.request();
      }
      // If we don't have permissions for location
      if (statuses[Permission.location] != PermissionStatus.granted) {
        await Permission.location.request();
      }
      // Check whether we have both permission again
      if (statuses[Permission.contacts] == PermissionStatus.granted &&
          statuses[Permission.location] == PermissionStatus.granted) {
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
      desc:
          'Please ensure that both contacts and locations permissions have been granted',
      btnOkOnPress: () {
        openAppSettings();
      },
    ).show();
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(),
              Column(
                children: [
                  Text(
                    "R $amount",
                    style: const TextStyle(
                        fontSize: 50, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    // Keypad section
                    keypad(),

                    // Buttons
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 40, bottom: 10, left: 10, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Request button
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width / 2 - 25,
                              child: ElevatedButton(
                                onPressed: () {
                                  requestFunds();
                                },
                                style: ButtonStyle(
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ))),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 15, bottom: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.attach_money),
                                      SizedBox(width: 5),
                                      Text(
                                        "Request",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Send button
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width / 2 - 25,
                              child: ElevatedButton(
                                onPressed: () {
                                  sendFunds();
                                },
                                style: ButtonStyle(
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ))),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 15, bottom: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.send),
                                      SizedBox(width: 5),
                                      Text(
                                        "Send",
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
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

// <========== Components ==========>

  // Calculator button
  TextButton calculatorButton(String number) {
    return TextButton(
      onPressed: () {
        updateAmount(number);
      },
      child: Text(
        number,
        style: TextStyle(
            color: Theme.of(context).textTheme.bodyText1!.color,
            fontSize: 40,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Column keypad() {
    return Column(
      children: [
        // 1,2,3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            calculatorButton("1"),
            calculatorButton("2"),
            calculatorButton("3"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            calculatorButton("4"),
            calculatorButton("5"),
            calculatorButton("6"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            calculatorButton("7"),
            calculatorButton("8"),
            calculatorButton("9"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            calculatorButton("."),
            calculatorButton("0"),
            IconButton(
              onPressed: () {
                if (amount.isNotEmpty) {
                  amount = amount.substring(0, amount.length - 1);
                  setState(() {
                    amount = amount;
                  });
                } else {
                  setState(() {
                    amount = "0.00";
                  });
                }
              },
              icon: Icon(Icons.arrow_left,
                  size: 40,
                  color: Theme.of(context).textTheme.bodyText1!.color),
            )
          ],
        )
      ],
    );
  }
}
