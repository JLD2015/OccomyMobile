import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:occomy/providers/requests_provider.dart';
import 'package:occomy/providers/transaction_provider.dart';
import 'package:occomy/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // <========== Variables ==========>
  final LocalAuthentication localAuth = LocalAuthentication();
  bool secureLoginState = false;

  // <========== Functions ==========>
  void showLogoutDialogue() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: 'Logout',
      desc: 'Are you sure you want to logout?',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        // Stop all of the listeners
        context.read<UserProvider>().stopStreaming(completion: () {
          context.read<TransactionsProvider>().stopStreaming(completion: () {
            context.read<RequestsProvider>().stopStreaming(completion: () {
              FirebaseAuth.instance.signOut();
            });
          });
        });
      },
    ).show();
  }

  void showSecureLoginError() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Secure Login',
      desc: 'Your device does not support secure login.',
      btnOkOnPress: () async {},
    ).show();
  }

  void toggleSecureLogin(state) async {
    // If the state is being toggled to on we need to make sure biometrics are available
    if (state == true) {
      if (await localAuth.canCheckBiometrics) {
        // Set the shared preferences to true if biometrics are available
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('secureLogin', true);
      } else {
        // Notify user that they can't use secure login
        showSecureLoginError();
      }
    } else {
      // If the toggle is turned off
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('secureLogin', false);
    }

    // Update the toggle on the screen
    setState(() {
      secureLoginState = state;
    });
  }

  // Page appears
  void loadSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      secureLoginState = prefs.getBool('secureLogin') ?? false;
    });
  }

  @override
  void initState() {
    loadSharedPreferences();
    super.initState();
  }

  // <========== Body ===========>
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: SafeArea(
        child: ListView(
          children: [
            // Edit profile section
            Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 15.0, right: 15.0, top: 10.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        child: CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.transparent,
                            backgroundImage: MemoryImage(base64Decode(context
                                .watch<UserProvider>()
                                .userData
                                .profilePhoto))),
                      ),
                      Text(
                        context.watch<UserProvider>().userData.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 3, bottom: 6),
                        child: Text(
                            context.watch<UserProvider>().userData.email,
                            style: const TextStyle(fontSize: 14)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          GoRouter.of(context).push('/editprofilescreen');
                        },
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text(
                                "Edit Profile",
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Icon(Icons.chevron_right)
                          ],
                        ),
                      ),
                    ],
                  ),
                )),

            // Preferences section
            Padding(
                padding:
                    const EdgeInsets.only(left: 15.0, right: 15.0, top: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 5.0),
                      child: Text(
                        "Preferences",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [
                          // Financial details button
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10.0,
                                right: 10.0,
                                top: 20.0,
                                bottom: 10.0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                GoRouter.of(context)
                                    .push('/financialdetailsscreen');
                              },
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.account_balance,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text("Financial Details",
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

                          // Secure login toggle
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10.0, right: 10.0, top: 1.0, bottom: 5.0),
                            child: GestureDetector(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lock,
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  const Text("Secure Login",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Switch(
                                      value: secureLoginState,
                                      onChanged: (value) {
                                        toggleSecureLogin(value);
                                      })
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                )),

            // Other section
            Padding(
                padding:
                    const EdgeInsets.only(left: 15.0, right: 15.0, top: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 5.0),
                      child: Text(
                        "Other",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [
                          // Help & Legal Button
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10.0,
                                right: 10.0,
                                top: 18.0,
                                bottom: 10.0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                GoRouter.of(context)
                                    .push('/helpandlegalscreen');
                              },
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.question_mark_outlined,
                                    color: Colors.red,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text("Help & Legal",
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold)),
                                  Spacer(),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.red,
                                  )
                                ],
                              ),
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.only(left: 12.0, right: 12.0),
                            child: Divider(),
                          ),

                          // Logout button
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10.0, right: 10.0, top: 10, bottom: 18.0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                showLogoutDialogue();
                              },
                              child: Row(
                                children: const [
                                  Icon(Icons.logout),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                    "Logout",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
