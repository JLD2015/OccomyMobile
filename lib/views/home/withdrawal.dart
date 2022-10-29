import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:occomy/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
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

  void withdrawFunds() async {
    // Make sure the user has enough funds
    if (context.read<UserProvider>().userData.balance >
        double.parse(amount) + 5) {
      //Show loading indicator to user
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Attempt to make the withdrawal

      final token = await FirebaseAuth.instance.currentUser!.getIdTokenResult();
      var url = Uri.https('api.occomy.com', 'transact/withdrawal');
      var response = await http.post(url, headers: {
        'Authorization': token.token!,
      }, body: {
        "amount": amount
      });
      if (response.statusCode == 200) {
        // Show the success animation
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: Lottie.asset('assets/lottie/success.json', repeat: false),
            ),
          ),
        );

        // Go back to the home screen

        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
            Navigator.pop(context);
            Navigator.pop(context);
          } else {
            GoRouter.of(context).replace('/');
          }
        });
      } else {
        // Show the failed animation
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: Lottie.asset('assets/lottie/failed.json', repeat: false),
            ),
          ),
        );

        // Go back to the home screen
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
        } else {
          GoRouter.of(context).replace('/');
        }
      }
    } else {
      // User has insufficient funds
      setState(() {
        amount = "0.00";
      });

      // Show error dialogue
      showInsufficientFundsAlert();
    }
  }

  // Show insufficient funds alert
  showInsufficientFundsAlert() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Insufficient Funds',
      desc: 'You do not have enough funds for this withdrawal.',
      btnOkOnPress: () {},
    ).show();
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
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
                  const Text(
                    "A R5 fee is applicable to withdrawals",
                    style: TextStyle(
                      color: Color.fromRGBO(169, 169, 169, 1),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  // Keypad section
                  keypad(),

                  // Submit button
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 15, left: 15, right: 15, bottom: 15),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          withdrawFunds();
                        },
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ))),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.arrow_downward_rounded),
                              SizedBox(width: 5),
                              Text(
                                "Withdraw",
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
            ),
          ],
        )
      ],
    );
  }
}
