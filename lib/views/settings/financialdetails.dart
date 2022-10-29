import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:occomy/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class FinancialDetailsScreen extends StatefulWidget {
  const FinancialDetailsScreen({super.key});

  @override
  State<FinancialDetailsScreen> createState() => _FinancialDetailsScreenState();
}

class _FinancialDetailsScreenState extends State<FinancialDetailsScreen> {
  // <========== Variables ==========>
  final _formKey = GlobalKey<FormState>();
  List<String> items = ["ABSA", "Capitec", "FNB", "Nedbank", "Standard Bank"];
  String? selectedItem = "ABSA";
  var selectedItemImage = const AssetImage("assets/images/absa_logo.png");
  final bankAccountNumberController = TextEditingController();

  // <========== Functions ==========>
  String? validateBankAccountNumber(String? value) {
    String pattern = r"^[0-9]+.{8,}$";
    RegExp regex = RegExp(pattern);
    if (value == null || value.isEmpty || !regex.hasMatch(value)) {
      bankAccountNumberController.clear();
      return 'Enter a valid bank account number';
    } else {
      return null;
    }
  }

  void bankSelectionChanged(String item) {
    switch (item) {
      case "ABSA":
        {
          setState(() {
            selectedItemImage = const AssetImage("assets/images/absa_logo.png");
          });
        }
        break;
      case "Capitec":
        {
          setState(() {
            selectedItemImage =
                const AssetImage("assets/images/capitec_logo.png");
          });
        }
        break;
      case "FNB":
        {
          setState(() {
            selectedItemImage = const AssetImage("assets/images/fnb_logo.png");
          });
        }
        break;
      case "Nedbank":
        {
          setState(() {
            selectedItemImage =
                const AssetImage("assets/images/nedbank_logo.png");
          });
        }
        break;
      case "Standard Bank":
        {
          setState(() {
            selectedItemImage =
                const AssetImage("assets/images/standard_bank_logo.png");
          });
        }
        break;
    }
    setState(() {
      selectedItem = item;
    });
  }

  void showErrorMessage() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: "We couldn't update your financiual details, please try again.",
      btnOkOnPress: () async {},
    ).show();
  }

  void updateFinancialDetails() async {
    // Show loading indicator to user
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    // Make request to update the user's financial details
    final token = await FirebaseAuth.instance.currentUser!.getIdTokenResult();
    var url = Uri.https('api.occomy.com', 'auth/updatefinancialdetails');
    var response = await http.post(url, headers: {
      'Authorization': token.token!,
    }, body: {
      "bankname": selectedItem,
      "bankaccountnumber": bankAccountNumberController.text.trim()
    });
    if (response.statusCode == 200) {
      // Need to hide the loading indicator
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      Navigator.pop(context);
      showErrorMessage();
    }
  }

  void getCurrentUserDetails() async {
    if (context.read<UserProvider>().userData.bankName != "") {
      selectedItem = context.read<UserProvider>().userData.bankName;
    }

    switch (selectedItem) {
      case "ABSA":
        {
          setState(() {
            selectedItemImage = const AssetImage("assets/images/absa_logo.png");
          });
        }
        break;
      case "Capitec":
        {
          setState(() {
            selectedItemImage =
                const AssetImage("assets/images/capitec_logo.png");
          });
        }
        break;
      case "FNB":
        {
          setState(() {
            selectedItemImage = const AssetImage("assets/images/fnb_logo.png");
          });
        }
        break;
      case "Nedbank":
        {
          setState(() {
            selectedItemImage =
                const AssetImage("assets/images/nedbank_logo.png");
          });
        }
        break;
      case "Standard Bank":
        {
          setState(() {
            selectedItemImage =
                const AssetImage("assets/images/standard_bank_logo.png");
          });
        }
        break;
    }

    // Set the bank account number
    bankAccountNumberController.text =
        context.read<UserProvider>().userData.bankAccountNumber;
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
    bankAccountNumberController.dispose();
    super.dispose();
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The top section of the page has to be scrollable in itself
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 20, bottom: 5.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                "Banking Details",
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          // Banking details section
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 80,
                                    backgroundColor: Colors.transparent,
                                    backgroundImage: selectedItemImage,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(top: 15),
                                    child: Text(
                                      "Select Bank",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),

                                  DropdownButton(
                                    value: selectedItem,
                                    items: items
                                        .map((item) => DropdownMenuItem<String>(
                                            value: item, child: Text(item)))
                                        .toList(),
                                    onChanged: (item) =>
                                        bankSelectionChanged(item!),
                                  ),

                                  // Bank account number
                                  Form(
                                    key: _formKey,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 20, bottom: 20),
                                      child: TextFormField(
                                        controller: bankAccountNumberController,
                                        decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            filled: true,
                                            labelText: 'Account Number',
                                            prefixIcon: const Icon(Icons.tag)),
                                        keyboardType: TextInputType.number,
                                        autofillHints: const [
                                          AutofillHints.email
                                        ],
                                        validator: (value) =>
                                            validateBankAccountNumber(value),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      "* We need valid banking details for withdrawals",
                                      style: TextStyle(
                                          color:
                                              Color.fromRGBO(169, 169, 169, 1)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Update button
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate the input fields
                        if (_formKey.currentState!.validate()) {
                          updateFinancialDetails();
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
