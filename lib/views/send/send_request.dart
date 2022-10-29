import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:occomy/models/valid_contact.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';

class SendRequestScreen extends StatefulWidget {
  final String amount;
  const SendRequestScreen({super.key, required this.amount});

  @override
  State<SendRequestScreen> createState() => _SendRequestScreen();
}

class _SendRequestScreen extends State<SendRequestScreen> {
  // <========== Variables ==========>
  // Contatcs
  List<String> contactEmailAddresses = [];
  List<String> contactPhoneNumbers = [];
  List<ValidContact> firebaseContacts = [];
  List<ValidContact> validContacts = [];
  List<ValidContact> suggestedContacts = [];

  // Textfields
  final messageController = TextEditingController();
  final recipientController = TextEditingController();
  int _selectedIndex = -1;

  // Location
  Location location = Location();

  bool loadingContacts = true;

  // <========== Functions ==========>

  // Used to filter the list of recipeints
  void searchForRecipient(String query) {
    final suggestions = validContacts.where((contact) {
      final name = contact.name.toLowerCase();
      final input = query.toLowerCase();
      return name.contains(input);
    }).toList();

    setState(() {
      suggestedContacts = suggestions;
    });
  }

  // Used to make sure we have access to the user's contacts and to retrieve valid contacts
  void retrieveContacts() async {
    var contacts =
        (await ContactsService.getContacts(withThumbnails: false)).toList();
    // Get all of the contact details
    for (var contact in contacts) {
      var emails = contact.emails;
      var phones = contact.phones;
      for (var email in emails!) {
        contactEmailAddresses.add(email.value!);
      }
      for (var phone in phones!) {
        contactPhoneNumbers.add(phone.value!);
      }
    }

    // Clean email addresses
    contactEmailAddresses = contactEmailAddresses
        .where((element) => element.contains("@"))
        .toList();

    // Clean the phone numbers
    contactPhoneNumbers = contactPhoneNumbers
        .map((e) => e.replaceAll(RegExp(r'[^0-9]'), ''))
        .toList();

    // Get all Firebase contacts
    FirebaseFirestore.instance.collection('contacts').get().then((value) {
      for (var doc in value.docs) {
        // We don't want to add our own contact
        if (doc.id != FirebaseAuth.instance.currentUser!.uid) {
          final id = doc.id;
          final email = doc.get("email");
          final name = doc.get("name");
          final phoneNumber = doc.get("phoneNumber");
          final profilePhoto = doc.get("profilePhoto");
          ValidContact contactToAdd = ValidContact(
              id: id,
              email: email,
              name: name,
              phoneNumber: phoneNumber,
              profilePhoto: profilePhoto);
          firebaseContacts.add(contactToAdd);
        }
      }

      // Get firebase contacts that match the device contacts
      for (var contact in firebaseContacts) {
        if (contactEmailAddresses.contains(contact.email)) {
          validContacts.add(contact);
        }
        if (contactPhoneNumbers.contains(contact.phoneNumber)) {
          validContacts.add(contact);
        }
      }

      // Remove duplicates from the list
      validContacts = validContacts.toSet().toList();

      setState(() {
        loadingContacts = false;
        suggestedContacts = validContacts;
      });
    });
  }

  void requestPayment() async {
    // Get the details for the contact we are paying
    if (_selectedIndex != -1) {
      final contactToPay = suggestedContacts[_selectedIndex];

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      if (messageController.text.trim().isEmpty) {
        messageController.text = "No message";
      }

      // Approve the transaction
      final token = await FirebaseAuth.instance.currentUser!.getIdTokenResult();
      var url = Uri.https('api.occomy.com', 'transact/requestpayment');
      var response = await http.post(url, headers: {
        'Authorization': token.token!,
      }, body: {
        "amount": widget.amount,
        "description": messageController.text.trim(),
        "customerid": contactToPay.id,
      });

      if (response.statusCode == 200) {
        // Hide the loading animation
        if (!mounted) return;
        Navigator.pop(context);

        // Show the success animation
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: SizedBox(
              height: 300,
              width: 300,
              child: Lottie.asset('assets/lottie/success.json', repeat: false),
            ),
          ),
        );

        // Go back to the send screen
        await Future.delayed(
          const Duration(seconds: 3),
          () {
            if (mounted) {
              Navigator.pop(context);
              Navigator.pop(context);
            } else {
              GoRouter.of(context).replace('/');
            }
          },
        );
      } else {
        showErrorAlert();
      }
    } else {
      selectContactAlert();
    }
  }

  // <========== Alerts ==========>

  showErrorAlert() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: 'Something went wrong, please try again.',
      btnOkOnPress: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    ).show();
  }

  selectContactAlert() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: 'Select a Contact',
      desc:
          'Please select somebody to pay from the list of suggested contacts.',
      btnOkOnPress: () {},
    ).show();
  }

  // <========== Page appears ==========>
  @override
  void initState() {
    retrieveContacts();
    super.initState();
  }

  // <========== Page Dissapears ==========>
  @override
  void dispose() {
    recipientController.dispose();
    messageController.dispose();
    super.dispose();
  }

  // <========== Components ==========>
  Widget getWidget() {
    if (loadingContacts == true && suggestedContacts.isEmpty) {
      return Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      );
    } else if (loadingContacts == false && suggestedContacts.isNotEmpty) {
      return Expanded(
        child: ListView.separated(
          itemCount: suggestedContacts.length,
          itemBuilder: (context, index) {
            final suggestedContact = suggestedContacts[index];
            return ListTile(
              leading: SizedBox(
                height: double.infinity,
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.transparent,
                  backgroundImage: MemoryImage(
                    base64Decode(suggestedContact.profilePhoto),
                  ),
                ),
              ),
              title: Text(
                suggestedContact.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(suggestedContact.email),
              selected: index == _selectedIndex,
              onTap: () => {
                setState(() {
                  _selectedIndex = index;
                  setState(() {
                    recipientController.text = suggestedContact.name;
                  });
                })
              },
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider(
              color: Color.fromRGBO(169, 169, 169, 1),
            );
          },
        ),
      );
    } else {
      // If the user does not have any friends on Occomy
      return Expanded(
        child: Column(
          children: [
            const Spacer(),

            // Animation
            SizedBox(
              height: 300,
              width: 300,
              child: Lottie.asset('assets/lottie/invite_friends.json',
                  repeat: true),
            ),

            const Spacer(),

            // Description text
            const Padding(
              padding: EdgeInsets.only(left: 15, right: 15),
              child: Text(
                "Whoops, it doesn't look like any of your friends have Occomy yet. Invite them to get started!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),

            const Spacer(),

            // Share button
            Padding(
              padding:
                  const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 15),
              child: ElevatedButton(
                onPressed: () {
                  Share.share(
                      "https://www.occomy.com \n \n Hey, I'd like to transact with you using Occomy. Check it out!");
                },
                style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.share),
                      SizedBox(width: 5),
                      Text(
                        "Invite friends",
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "R${double.parse(widget.amount).toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              requestPayment();
            },
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                "Request",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top section containing the input fields

            Column(
              children: [
                // Recipient input new
                Padding(
                  padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
                  child: Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return validContacts
                        .where((contact) => contact.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()))
                        .map((contact) => contact.name);
                  }, onSelected: (String selection) {
                    setState(() {
                      recipientController.text = selection;
                      _selectedIndex = validContacts
                          .indexWhere((contact) => contact.name == selection);
                    });
                  }, fieldViewBuilder: (context, textEditingController,
                          focusNode, onFieldSubmitted) {
                    return TextField(
                        controller: recipientController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: "To",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(15.0),
                            ),
                          ),
                        ),
                        onChanged: searchForRecipient);
                  }),
                ),
                // Message input
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: "What is the payment for?",
                      prefixIcon: Icon(Icons.chat),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(15.0),
                        ),
                      ),
                    ),
                  ),
                ),

                // Suggested contacts
                const SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.only(left: 15, bottom: 15),
                    child: Text(
                      "Suggested",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            Container(
              child: getWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
