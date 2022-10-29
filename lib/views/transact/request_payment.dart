import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:occomy/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';

class RequestPaymentScreen extends StatefulWidget {
  const RequestPaymentScreen({super.key});

  @override
  State<RequestPaymentScreen> createState() => _RequestPaymentScreenState();
}

class _RequestPaymentScreenState extends State<RequestPaymentScreen> {
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

  void requestPayment() async {
    // Show loading indicator to user
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Generate the payment
    var url = Uri.https('api.occomy.com', 'transact/createtransaction');
    var response = await http.post(url, headers: {
      'Authorization': context.read<UserProvider>().userData.apiKey,
    }, body: {
      "amount": amount,
      "description": "In-App Payment"
    });
    if (response.statusCode == 200) {
      // Get the transaction details
      Map<String, dynamic> responseJson = json.decode(response.body);
      String documentID = responseJson["documentID"];
      String transactionID = responseJson["transactionID"];

      // Show the payment tag
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
      GoRouter.of(context)
          .push('/paymenttagscreen/$amount/$documentID/$transactionID');
    } else {
      if (!mounted) return;
      Navigator.pop(context);
      showErrorAlert();
    }
  }

  // Show alert on forgot email success
  showErrorAlert() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: 'Could not request payment, please try again.',
      btnOkOnPress: () {},
    ).show();
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Payment',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(),
            Text(
              "R $amount",
              style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
            ),
            Column(
              children: [
                // Keypad section
                keypad(),

                // Submit button
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        requestPayment();
                      },
                      style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ))),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.attach_money_rounded),
                            SizedBox(width: 5),
                            Text(
                              "Request Payment",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
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
              icon: Icon(
                Icons.arrow_left,
                size: 40,
                color: Theme.of(context).textTheme.bodyText1!.color,
              ),
            )
          ],
        )
      ],
    );
  }
}
