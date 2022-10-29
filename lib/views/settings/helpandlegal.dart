import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:occomy/providers/requests_provider.dart';
import 'package:occomy/providers/transaction_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:occomy/providers/user_provider.dart';
import 'package:provider/provider.dart';

class HelpAndLegalScreen extends StatefulWidget {
  const HelpAndLegalScreen({super.key});

  @override
  State<HelpAndLegalScreen> createState() => _HelpAndLegalScreenState();
}

class _HelpAndLegalScreenState extends State<HelpAndLegalScreen> {
  // <========== Variables ==========>
  String version = "";
  String year = "";

  // <========== Functions ==========>
  Future deleteAccount() async {
    if (Provider.of<UserProvider>(context, listen: false).userData.balance !=
        0) {
      showStillHaveBalanceDialogue();
    } else {
      showDeleteAccountDialogue();
    }
  }

  void showDeleteAccountDialogue() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Delete Account',
      desc:
          'Are you sure you want to delete your Occomy account? This cannot be undone.',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        // Make request to delete the user's account
        final token =
            await FirebaseAuth.instance.currentUser!.getIdTokenResult();
        var url = Uri.https('api.occomy.com', 'auth/deleteaccount');

        // Stop all listeners
        if (!mounted) return;
        context.read<UserProvider>().stopStreaming(completion: () {
          context.read<TransactionsProvider>().stopStreaming(
              completion: () async {
            context.read<RequestsProvider>().stopStreaming(
                completion: () async {
              // Display toast
              Fluttertoast.showToast(
                  msg: "Account deleted",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 4,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0);

              // Sign out the user
              FirebaseAuth.instance.signOut();

              // Navigate back the the auto login controller
              Navigator.of(context).pop();

              // Make the deletion request
              await http.post(url, headers: {
                'Authorization': token.token!,
              });
            });
          });
        });
      },
    ).show();
  }

  void showStillHaveBalanceDialogue() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Delete Account',
      desc:
          'You cannot delete your Occomy account while you have a balance. Please withdraw funds from your Occomy account or settle your balance.',
      btnOkOnPress: () {},
    ).show();
  }

// <========== Page Appears ==========>
  @override
  void initState() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        version = packageInfo.version;
      });
      var now = DateTime.now();
      var formatter = DateFormat('yyyy');
      setState(() {
        year = formatter.format(now);
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Legal',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lottie animation
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                child: Lottie.asset('assets/lottie/help_and_legal.json',
                    repeat: true),
              ),

              // Buttons section
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Card(
                      child: Column(
                        children: [
                          // Terms of service button
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10.0,
                                right: 10.0,
                                top: 20.0,
                                bottom: 10.0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () async {
                                final Uri url = Uri.parse(
                                    'https://www.occomy.com/termsandconditions');
                                if (!await launchUrl(url)) {
                                  throw 'Could not launch $url';
                                }
                              },
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.gavel_outlined,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text("Terms of Service",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Spacer(),
                                  Icon(
                                    Icons.chevron_right,
                                  )
                                ],
                              ),
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.only(left: 12.0, right: 12.0),
                            child: Divider(),
                          ),

                          // Privacy policy button
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10.0,
                                right: 10.0,
                                top: 10.0,
                                bottom: 10.0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () async {
                                final Uri url = Uri.parse(
                                    'https://www.occomy.com/privacypolicy');
                                if (!await launchUrl(url)) {
                                  throw 'Could not launch $url';
                                }
                              },
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.policy_rounded,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text("Privacy Policy",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Spacer(),
                                  Icon(
                                    Icons.chevron_right,
                                  )
                                ],
                              ),
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.only(left: 12.0, right: 12.0),
                            child: Divider(),
                          ),

                          // Contact button
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10.0,
                                right: 10.0,
                                top: 10.0,
                                bottom: 10.0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () async {
                                final Uri url = Uri.parse(
                                    'mailto:support@occomy.com?subject=Support Request');
                                if (!await launchUrl(url)) {
                                  throw 'Could not launch $url';
                                }
                              },
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.contact_support_rounded,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text("Contact Us",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Spacer(),
                                  Icon(
                                    Icons.chevron_right,
                                  )
                                ],
                              ),
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.only(left: 12.0, right: 12.0),
                            child: Divider(),
                          ),

                          // Delete account button
                          // Clear local data button
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10.0,
                                right: 10.0,
                                top: 10.0,
                                bottom: 20.0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                deleteAccount();
                              },
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.delete_forever_rounded,
                                    color: Colors.red,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text("Delete Account",
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Version section -> Stays at the bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          "Version $version",
                          style: const TextStyle(
                              color: Color.fromRGBO(128, 128, 128, 1),
                              fontSize: 12),
                        ),
                      ),
                      Text("Copyright © $year Occomy (Pty) Ltd.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color.fromRGBO(128, 128, 128, 1),
                              fontSize: 14))
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
