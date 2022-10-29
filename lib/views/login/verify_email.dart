import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  // <========== Functions ==========>
  void sendVerificationEmail() async {
    // Show loading indicator to user
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    // Send the email
    var url = Uri.https('api.occomy.com', 'email/sendverifyemail');
    var response = await http.post(url, body: {
      'email': FirebaseAuth.instance.currentUser!.email,
      'name': FirebaseAuth.instance.currentUser!.displayName,
    });

    if (response.statusCode == 200) {
      // Need to hide the loading indicator
      if (!mounted) return;
      Navigator.pop(context);

      // Display the success notification
      showSuccessAlert();
    } else {
      // Need to hide the loading indicator
      if (!mounted) return;
      Navigator.pop(context);

      // Display the failed notification
      showFailedAlert();
    }
  }

  // Show success alert
  showSuccessAlert() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: 'Email Sent',
      desc: 'Please check your email for a link to verify your email address',
      btnOkOnPress: () {},
    ).show();
  }

  // Show failed alert
  showFailedAlert() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: 'Could not send verification email, please try again',
      btnOkOnPress: () {},
    ).show();
  }

  // <========== Page Loads ==========>
  @override
  void initState() {
    // Refresh the user
    super.initState();
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Spacer
            const SizedBox(),
            // Central section
            Column(
              children: [
                SizedBox(
                  height: 300,
                  width: 300,
                  child: Lottie.asset('assets/lottie/check_email.json',
                      repeat: true),
                ),
                const Text("Verify Email",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                      "Please verify your email address using the email we have sent you",
                      textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: 'Send email again',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              sendVerificationEmail();
                            }),
                    ]),
                  ),
                ),
              ],
            ),
            // Bottom section
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Go back to the login screen
                    FirebaseAuth.instance.signOut();
                    GoRouter.of(context).push('/');
                  },
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ))),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "Login",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ));
  }
}
