import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:occomy/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // <========== Variables ==========>
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final ImagePicker imagePicker = ImagePicker();
  XFile? imgXFile;
  File? compressedImage;

  // <========== Functions ==========>
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

  void showErrorMessage() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: "We couldn't update your profile details, please try again.",
      btnOkOnPress: () async {},
    ).show();
  }

  void updateProfile() async {
    // Show loading indicator to user
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    final token = await FirebaseAuth.instance.currentUser!.getIdTokenResult();

    var url = Uri.https('api.occomy.com', 'auth/updateprofiledetails');
    var request = http.MultipartRequest("POST", url);

    if (compressedImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'profilepicture', compressedImage!.path));
    } else {
      if (!mounted) return;
      var bytes =
          base64.decode(context.read<UserProvider>().userData.profilePhoto);
      request.files.add(http.MultipartFile.fromBytes('profilepicture', bytes,
          filename: 'defaultavatar.png'));
    }

    if (!mounted) return;
    request.headers.addAll({'Authorization': token.token!});
    request.fields['name'] = nameController.text.trim();
    request.fields['phone'] = phoneController.text.trim();

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    try {
      final responseDataJSON = jsonDecode(responseData);

      // If updating the user was successful
      if (responseDataJSON["status"] == "Success") {
        // Need to hide the loading indicator
        if (!mounted) return;
        Navigator.pop(context);

        // Go back one page
        Navigator.pop(context);
      }
    } on Exception catch (_) {
      // Clear focus
      if (!mounted) return;
      FocusScope.of(context).requestFocus(FocusNode());

      // Need to hide the loading indicator
      if (!mounted) return;
      Navigator.pop(context);

      // Show the alert
      showErrorMessage();
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

  void getCurrentUserDetails() {
    nameController.text = context.read<UserProvider>().userData.name;
    phoneController.text = context.read<UserProvider>().userData.phoneNumber;
  }

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

  // <========== Page Appears ==========>
  @override
  void initState() {
    getCurrentUserDetails();
    super.initState();
  }

  // <========== Page Dissapears ==========>
  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child:
                // Main column for page
                Column(
              children: [
                Form(
                    key: _formKey,
                    child: Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Profile photo
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: GestureDetector(
                                  onTap: () {
                                    getImageFromGallery();
                                  },
                                  child: CircleAvatar(
                                      radius: 120,
                                      backgroundColor: const Color.fromRGBO(
                                          211, 211, 211, 1),
                                      backgroundImage: compressedImage == null
                                          ? MemoryImage(base64Decode(context
                                              .watch<UserProvider>()
                                              .userData
                                              .profilePhoto))
                                          : FileImage(
                                                  File(compressedImage!.path))
                                              as ImageProvider,
                                      child: compressedImage == null
                                          ? const Icon(Icons.photo_camera,
                                              color: Colors.white, size: 100)
                                          : null)),
                            ),
                            // Name textfield
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, bottom: 20),
                              child: TextFormField(
                                controller: nameController,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    labelText: 'Name',
                                    prefixIcon: const Icon(Icons.person)),
                                keyboardType: TextInputType.name,
                                autofillHints: const [AutofillHints.name],
                                validator: (value) => validateName(value),
                              ),
                            ),

                            // Phone number textfield
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: TextFormField(
                                controller: phoneController,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
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
                          ],
                        ),
                      ),
                    )),
                // Update button
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate the input fields
                        if (_formKey.currentState!.validate()) {
                          updateProfile();
                        }
                      },
                      style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ))),
                      child: const Padding(
                          padding: EdgeInsets.all(15),
                          child: Text(
                            "Update",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          )),
                    ),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
