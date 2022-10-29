import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Variables
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  late FocusNode emailFocusNode;
  final passwordController = TextEditingController();
  var errorPrompt = "";

  // Functions
  String? validateEmail(String? value) {
    String pattern =
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
        r"{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]"
        r"{0,253}[a-zA-Z0-9])?)*$";
    RegExp regex = RegExp(pattern);
    if (value == null || value.isEmpty || !regex.hasMatch(value)) {
      return 'Enter a valid email address';
    } else {
      return null;
    }
  }

  Future signIn() async {
    // Show loading indicator to user
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());
    } on FirebaseAuthException catch (e) {
      // If an incorrect email address is enetered
      if (e.message ==
          "There is no user record corresponding to this identifier. The user may have been deleted.") {
        emailController.clear();
        emailFocusNode.requestFocus();
        passwordController.clear();

        // Show the alert
        setState(() {
          errorPrompt = "User does not exist";
        });
      }

      // If an incorrect password is entered
      if (e.message ==
          "The password is invalid or the user does not have a password.") {
        passwordController.clear();

        // Show the alert
        setState(() {
          errorPrompt = "Incorrect password";
        });
      }

      // If the user has tried too many incorrect passwords
      if (e.message ==
          "Access to this account has been temporarily disabled due to many failed login attempts. You can immediately restore it by resetting your password or you can try again later.") {
        emailController.clear();
        passwordController.clear();

        // Show the alert
        setState(() {
          errorPrompt =
              "Too many failed login attempts, please reset your password";
        });
      }
    }

    // Need to hide the loading indicator
    if (!mounted) return;
    Navigator.pop(context);
  }

  // Forgot password functionality
  Future forgotPassword() async {
    // First we need to make sure we have an email address
    if (emailController.text.trim().isEmpty) {
      setState(() {
        errorPrompt = "Please enter your email address";
      });
    } else {
      // Show loading indicator to user
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()));

      // Make sure this is an actual email address
      var result = validateEmail(emailController.text.trim());
      if (result == null) {
        // Send the email
        var url = Uri.https('api.occomy.com', 'email/resetpassword');
        var response = await http.post(url, body: {
          'email': emailController.text.trim(),
        });
        if (response.statusCode == 200) {
          emailController.clear();
          passwordController.clear();
          emailFocusNode.requestFocus();

          // Need to hide the loading indicator
          if (!mounted) return;
          Navigator.pop(context);

          showForgotPasswordAlert();
        } else {
          emailController.clear();
          passwordController.clear();
          emailFocusNode.requestFocus();

          setState(() {
            errorPrompt = "User doesn't exist";
          });

          // Need to hide the loading indicator
          if (!mounted) return;
          Navigator.pop(context);
        }
      } else {
        setState(() {
          errorPrompt = "Invalid email address";
        });

        // Need to hide the loading indicator
        Navigator.pop(context);
      }
    }
  }

  // Show alert on forgot email success
  showForgotPasswordAlert() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: 'Email Sent',
      desc: 'Please check your email for a link to reset your password',
      btnOkOnPress: () {},
    ).show();
  }

  // Page appears
  @override
  void initState() {
    emailFocusNode = FocusNode();
    super.initState();
  }

  // Page dissapears
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    emailController.dispose();
    passwordController.dispose();

    // Clean the focus nodes when the widget is disposed
    emailFocusNode.dispose();

    super.dispose();
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(body: SafeArea(
        child: StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top spacer
                const SizedBox(
                  height: 50,
                ),
                // Login section
                Column(
                  children: [
                    //Logo and heading
                    Row(
                      children: [
                        Image.asset(
                          Theme.of(context).brightness == Brightness.dark
                              ? 'assets/images/logowhite.png'
                              : 'assets/images/logo.png',
                          width: 70,
                          height: 70,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Login",
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            SizedBox(height: 2),
                            Text("Please sign in to continue")
                          ],
                        )
                      ],
                    ),
                    Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            children: [
                              // Email textfield
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 10, bottom: 10),
                                child: TextFormField(
                                  controller: emailController,
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      labelText: 'Email',
                                      prefixIcon: const Icon(Icons.email)),
                                  focusNode: emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  validator: (value) => validateEmail(value),
                                ),
                              ),

                              // Password textfield
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TextFormField(
                                  controller: passwordController,
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock),
                                      suffixIcon: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: GestureDetector(
                                          onTap: () {
                                            forgotPassword();
                                          },
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "FORGOT",
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      )),
                                  keyboardType: TextInputType.visiblePassword,
                                  autofillHints: const [AutofillHints.password],
                                  onEditingComplete: () =>
                                      TextInput.finishAutofillContext(),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter password';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              // Submit button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      // Validate the input fields
                                      if (_formKey.currentState!.validate()) {
                                        signIn();
                                      }
                                    },
                                    style: ButtonStyle(
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ))),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        children: const [
                                          Text(
                                            "Login",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          SizedBox(width: 5),
                                          Icon(Icons.arrow_forward)
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )),

                    // Error prompt
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(errorPrompt,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Divider(
                          color: Color.fromRGBO(169, 169, 169, 1),
                          thickness: 1,
                        ),
                      ),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: "Don't have an account?",
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color,
                                fontSize: 16),
                          ),
                          TextSpan(
                              text: ' Sign Up',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 16),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  GoRouter.of(context).push('/registerscreen');
                                }),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      )),
    );
  }
}
