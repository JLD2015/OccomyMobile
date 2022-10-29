import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Variables
  final _formKey = GlobalKey<FormState>();
  final ImagePicker imagePicker = ImagePicker();
  var errorPrompt = "";
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final scrollController = ScrollController();
  XFile? imgXFile;
  File? compressedImage;

  // <========== Functions ==========>
  getImageFromGallery() async {
    imgXFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (imgXFile?.path != null) {
      compressedImage = await compressImage(File(imgXFile!.path));
      setState(() {
        compressedImage;
      });
    }
  }

  Future<File?> compressImage(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
    final splitted = filePath.substring(0, (lastIndex));
    final outPath = "${splitted}_out${filePath.substring(lastIndex)}";
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: 10,
    );

    return result;
  }

  // Register user functionality
  Future register() async {
    // Show loading indicator to user
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    var url = Uri.https('api.occomy.com', 'auth/createaccount');
    var request = http.MultipartRequest("POST", url);

    if (compressedImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'profilepicture', compressedImage!.path));
    } else {
      var bytes = (await rootBundle.load('assets/images/defaultavatar.jpg'))
          .buffer
          .asUint8List();
      request.files.add(http.MultipartFile.fromBytes('profilepicture', bytes,
          filename: 'defaultavatar.jpg'));
    }

    request.fields['email'] = emailController.text.trim();
    request.fields['password'] = passwordController.text.trim();
    request.fields['displayname'] = nameController.text.trim();
    request.fields['phonenumber'] = phoneController.text.trim();

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    try {
      final responseDataJSON = jsonDecode(responseData);

      // If creating the user was successful
      if (responseDataJSON["status"] == "Success") {
        // Sign in the user so we'll have access to their email and username on the next page
        FirebaseAuth.instance.signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim());
        if (!mounted) return;
        GoRouter.of(context).go('/verifyemailscreen');
      }
      // If the user already exists
      else if (responseDataJSON["status"] ==
          "The email address is already in use by another account.") {
        // Clear focus
        if (!mounted) return;
        FocusScope.of(context).requestFocus(FocusNode());

        // Clear all the fields
        nameController.clear();
        emailController.clear();
        phoneController.clear();
        passwordController.clear();
        confirmPasswordController.clear();

        // Show the alert
        setState(() {
          errorPrompt = "User already exists";
        });

        // Need to hide the loading indicator
        if (!mounted) return;
        Navigator.pop(context);

        // Scroll to the bottom of the page
        scrollController.animateTo(scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500), curve: Curves.ease);
      }
    } on Exception catch (_) {
      // Clear focus
      if (!mounted) return;
      FocusScope.of(context).requestFocus(FocusNode());

      // Show the alert
      setState(() {
        errorPrompt = "Network error";
      });

      // Need to hide the loading indicator
      if (!mounted) return;
      Navigator.pop(context);

      // Scroll to the bottom of the page
      scrollController.animateTo(scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500), curve: Curves.ease);
    }
  }

  String? validateName(String? value) {
    String pattern =
        r"^[a-zA-ZàáâäãåąčćęèéêëėįìíîïłńòóôöõøùúûüųūÿýżźñçčšžÀÁÂÄÃÅĄĆČĖĘÈÉÊËÌÍÎÏĮŁŃÒÓÔÖÕØÙÚÛÜŲŪŸÝŻŹÑßÇŒÆČŠŽ∂ð ,.'-]+$";
    RegExp regex = RegExp(pattern);
    if (value == null || value.isEmpty || !regex.hasMatch(value)) {
      nameController.clear();
      return 'Enter a valid name';
    } else {
      return null;
    }
  }

  String? validateEmail(String? value) {
    String pattern =
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
        r"{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]"
        r"{0,253}[a-zA-Z0-9])?)*$";
    RegExp regex = RegExp(pattern);
    if (value == null || value.isEmpty || !regex.hasMatch(value)) {
      emailController.clear();
      return 'Enter a valid email address';
    } else {
      return null;
    }
  }

  String? validatePhone(String? value) {
    String pattern =
        r"^\s*(?:\+?(\d{1,3}))?[-. (]*(\d{3})[-. )]*(\d{3})[-. ]*(\d{4})(?: *x(\d+))?\s*$";
    RegExp regex = RegExp(pattern);
    if (value == null || value.isEmpty || !regex.hasMatch(value)) {
      phoneController.clear();
      return 'Enter a valid phone number';
    } else {
      return null;
    }
  }

  String? validatePassword(String? value) {
    String pattern = r"^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$";
    RegExp regex = RegExp(pattern);
    if (value == null || value.isEmpty || !regex.hasMatch(value)) {
      if (passwordController.text.trim() !=
          confirmPasswordController.text.trim()) {
        passwordController.clear();
        confirmPasswordController.clear();
        return "Passwords don't match";
      } else {
        passwordController.clear();
        confirmPasswordController.clear();
        return 'Please use a more secure password';
      }
    } else {
      return null;
    }
  }

  // <========== Page dissapears ==========>
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    // Clean up the scroll controller
    scrollController.dispose();

    super.dispose();
  }

  // Body
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Create Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        // User photo
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: GestureDetector(
                              onTap: () {
                                getImageFromGallery();
                              },
                              child: CircleAvatar(
                                  radius: 120,
                                  backgroundColor:
                                      const Color.fromRGBO(211, 211, 211, 1),
                                  backgroundImage: compressedImage == null
                                      ? null
                                      : FileImage(File(compressedImage!.path)),
                                  child: compressedImage == null
                                      ? const Icon(Icons.photo_camera,
                                          color: Colors.white, size: 100)
                                      : null)),
                        ),

                        AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Name textfield
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 10, bottom: 20),
                                  child: TextFormField(
                                    controller: nameController,
                                    decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        labelText: 'Name',
                                        prefixIcon: const Icon(Icons.person)),
                                    keyboardType: TextInputType.name,
                                    autofillHints: const [AutofillHints.name],
                                    validator: (value) => validateName(value),
                                  ),
                                ),
                                // Email textfield
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: TextFormField(
                                    controller: emailController,
                                    decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        labelText: 'Email',
                                        prefixIcon: const Icon(Icons.email)),
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    validator: (value) => validateEmail(value),
                                  ),
                                ),
                                // Phone number textfield
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: TextFormField(
                                    controller: phoneController,
                                    decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        labelText: 'Phone number',
                                        prefixIcon: const Icon(Icons.phone)),
                                    keyboardType: TextInputType.phone,
                                    autofillHints: const [
                                      AutofillHints.telephoneNumber
                                    ],
                                    validator: (value) => validatePhone(value),
                                  ),
                                ),
                                // Password textfield
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: TextFormField(
                                    controller: passwordController,
                                    decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        labelText: 'Password',
                                        prefixIcon: const Icon(Icons.lock)),
                                    keyboardType: TextInputType.visiblePassword,
                                    autofillHints: const [
                                      AutofillHints.newPassword
                                    ],
                                    obscureText: true,
                                    validator: (value) =>
                                        validatePassword(value),
                                  ),
                                ),
                                // Confirm password textfield
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: TextFormField(
                                    controller: confirmPasswordController,
                                    decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        labelText: 'Confirm password',
                                        prefixIcon: const Icon(Icons.lock)),
                                    keyboardType: TextInputType.visiblePassword,
                                    autofillHints: const [
                                      AutofillHints.newPassword
                                    ],
                                    obscureText: true,
                                    validator: (value) =>
                                        validatePassword(value),
                                  ),
                                ),
                                // Terms of service
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 10, bottom: 15),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(children: [
                                      const TextSpan(
                                        text:
                                            "By clicking sign up, you agree to our ",
                                        style: TextStyle(
                                            color: Color.fromRGBO(
                                                128, 128, 128, 1),
                                            fontSize: 16),
                                      ),
                                      TextSpan(
                                          text: ' Terms of Service',
                                          style: const TextStyle(
                                              color: Colors.blue, fontSize: 16),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () async {
                                              final Uri url = Uri.parse(
                                                  'https://www.occomy.com/termsandconditions');
                                              if (!await launchUrl(url)) {
                                                throw 'Could not launch $url';
                                              }
                                            }),
                                    ]),
                                  ),
                                ),

                                // Sign up button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Validate the input fields
                                      if (_formKey.currentState!.validate()) {
                                        register();
                                      }
                                    },
                                    style: ButtonStyle(
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ))),
                                    child: const Padding(
                                        padding: EdgeInsets.all(15),
                                        child: Text(
                                          "Sign Up",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        )),
                                  ),
                                ),
                                // Allow for visibility of sign up button
                                // Error prompt
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 20, bottom: 15),
                                  child: Text(errorPrompt,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 18)),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )),
    );
  }
}
