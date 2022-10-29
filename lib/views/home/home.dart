import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:occomy/providers/requests_provider.dart';
import 'package:occomy/providers/transaction_provider.dart';
import 'package:occomy/providers/user_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // <========== Variables ==========>

// <========== Functions ==========>
  void showDepositPopup(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Heading
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Text("Deposit Funds",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 30,
                          fontWeight: FontWeight.bold)),
                ),

                // Bank
                Padding(
                  padding: const EdgeInsets.only(top: 0, bottom: 0),
                  child: Column(
                    children: [
                      Text(
                        "Bank",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 24,
                        ),
                      ),
                      const Text(
                        "Merchantile Bank",
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),

                // Branch Code
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      Text(
                        "Branch Code",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 24,
                        ),
                      ),
                      const Text("450105", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),

                // Account Number
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      Text(
                        "Account Number",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 24,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: GestureDetector(
                            onTap: () async {
                              // Set clipboard to account number
                              await Clipboard.setData(
                                  const ClipboardData(text: "1051074436"));

                              // Display toast
                              Fluttertoast.showToast(
                                  msg: "Copied to clipboard",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 4,
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  "1051074436",
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 18),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: Colors.blue,
                                )
                              ],
                            )),
                      )
                    ],
                  ),
                ),

                // Reference
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      Text(
                        "Reference",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 24,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: GestureDetector(
                          onTap: () async {
                            // Set clipboard to account number
                            await Clipboard.setData(ClipboardData(
                                text: context
                                    .read<UserProvider>()
                                    .userData
                                    .depositID));

                            // Display toast
                            Fluttertoast.showToast(
                                msg: "Copied to clipboard",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 4,
                                backgroundColor: Colors.green,
                                textColor: Colors.white,
                                fontSize: 16.0);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                context.read<UserProvider>().userData.depositID,
                                style: const TextStyle(
                                    color: Colors.blue, fontSize: 18),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              const Icon(
                                Icons.copy,
                                size: 14,
                                color: Colors.blue,
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                // Explanatory note
                const Padding(
                  padding:
                      EdgeInsets.only(top: 20, bottom: 20, left: 10, right: 10),
                  child: Text(
                    "Funds may take up to two working days to reflect",
                    style: TextStyle(color: Color.fromRGBO(169, 169, 169, 1)),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Ok button
                Padding(
                  padding:
                      const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
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
                            "Ok",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          )),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

// Make sure we have access to the user's location
  Future<bool> ensureLocationPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
    ].request();

    // Make sure we have both permissions
    if (statuses[Permission.location] == PermissionStatus.granted) {
      return true;
    } else {
      // If we don't have permissions for location
      if (statuses[Permission.location] != PermissionStatus.granted) {
        await Permission.location.request();
      }
      // Check whether we have permission again
      if (statuses[Permission.location] == PermissionStatus.granted) {
        return true;
      } else {
        permissionsAlert();
        return false;
      }
    }
  }

  // <========== Alerts ==========>
  permissionsAlert() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Permissions',
      desc: 'Please ensure that locations permissions have been granted',
      btnOkOnPress: () {
        openAppSettings();
      },
    ).show();
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
          child:
              // Main column for page
              Column(
            children: [
              // Top row with user photo and name
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.transparent,
                      backgroundImage: MemoryImage(
                        base64Decode(context
                            .watch<UserProvider>()
                            .userData
                            .profilePhoto),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Hello",
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            context.read<UserProvider>().userData.name,
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          )
                        ],
                      ),
                    ),
                    const Spacer(),
                    context.watch<RequestsProvider>().allRequests.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () async {
                                var permissionStatus =
                                    await ensureLocationPermissions();
                                if (permissionStatus == true) {
                                  if (!mounted) return;
                                  GoRouter.of(context)
                                      .push('/incomingrequestsscreen');
                                }
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                    color: Colors.red,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(100))),
                                child: Center(
                                  child: Text(
                                    context
                                        .watch<RequestsProvider>()
                                        .allRequests
                                        .length
                                        .toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () {
                                GoRouter.of(context)
                                    .push('/incomingrequestsscreen');
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                    color: Color.fromRGBO(169, 169, 169, 1),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(100))),
                                child: const Center(
                                  child: Text(
                                    "0",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),

              // Card with user balance
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Card(
                  color: Colors.transparent,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.fromRGBO(57, 110, 176, 1),
                          Color.fromRGBO(46, 76, 109, 1),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(left: 15.0, top: 10.0),
                              child: Text(
                                "Balance",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            ),
                            Spacer(),
                            Padding(
                              padding: EdgeInsets.only(right: 15, top: 10),
                              child: Text(
                                "ZAR",
                                style: TextStyle(
                                    color: Color.fromRGBO(121, 121, 121, 1),
                                    fontSize: 18),
                              ),
                            )
                          ],
                        ),
                        Padding(
                            padding: const EdgeInsets.only(top: 25, bottom: 40),
                            child: Text(
                              'R ${context.read<UserProvider>().userData.balance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold),
                            )),
                      ],
                    ),
                  ),
                ),
              ),

              // Deposit and withdrawal buttons
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Deposit button
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width / 2 - 25,
                        child: ElevatedButton(
                          onPressed: () {
                            showDepositPopup(context);
                          },
                          style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ))),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 15, bottom: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.arrow_upward_rounded),
                                SizedBox(width: 5),
                                Text(
                                  "Deposit",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Withdrawal button
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width / 2 - 25,
                        child: ElevatedButton(
                          onPressed: () async {
                            final userBank =
                                context.read<UserProvider>().userData.bankName;
                            final userBankAccountNumber = context
                                .read<UserProvider>()
                                .userData
                                .bankAccountNumber;

                            if (userBank == "" || userBankAccountNumber == "") {
                              // Display toast
                              Fluttertoast.showToast(
                                  msg: "Please provide banking details",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIosWeb: 4,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0);

                              GoRouter.of(context)
                                  .push('/financialdetailsscreen');
                            } else {
                              GoRouter.of(context).push('/withdrawalscreen');
                            }
                          },
                          style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ))),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 15, bottom: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.arrow_downward_rounded),
                                SizedBox(width: 5),
                                Text(
                                  "Withdraw",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Recent transactions section
              const Padding(
                padding: EdgeInsets.only(left: 10, top: 15, bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    "Recent Transactions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Recent transactions
              Expanded(
                child: context
                        .read<TransactionsProvider>()
                        .recentTransactions
                        .isNotEmpty
                    ? ListView.separated(
                        itemCount: context
                            .read<TransactionsProvider>()
                            .recentTransactions
                            .length,
                        itemBuilder: (context, index) {
                          // Tile for deposit
                          if (context
                                  .read<TransactionsProvider>()
                                  .recentTransactions[index]
                                  .type ==
                              "deposit") {
                            return ListTile(
                              leading: const SizedBox(
                                height: double.infinity,
                                child: Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 40.0,
                                ),
                              ),
                              title: const Text(
                                "Deposit",
                                style: TextStyle(fontSize: 20),
                              ),
                              subtitle: Text(
                                  DateFormat('yyyy-MM-dd').format(context
                                      .read<TransactionsProvider>()
                                      .recentTransactions[index]
                                      .date),
                                  style: const TextStyle(fontSize: 16)),
                              trailing: Text(
                                  "R ${(context.read<TransactionsProvider>().recentTransactions[index].amount).toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            );
                          }
                          // Tile for withdrawal
                          else if (context
                                  .read<TransactionsProvider>()
                                  .recentTransactions[index]
                                  .type ==
                              "withdrawal") {
                            return ListTile(
                              leading: const SizedBox(
                                height: double.infinity,
                                child: Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 40.0,
                                ),
                              ),
                              title: const Text(
                                "Withdrawal",
                                style: TextStyle(fontSize: 20),
                              ),
                              subtitle: Text(
                                  DateFormat('yyyy-MM-dd').format(context
                                      .read<TransactionsProvider>()
                                      .recentTransactions[index]
                                      .date),
                                  style: const TextStyle(fontSize: 16)),
                              trailing: Text(
                                  "R ${((context.read<TransactionsProvider>().recentTransactions[index].amount) * -1).toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            );
                          }
                          // Tile for withdrawal fees
                          else if (context
                                  .read<TransactionsProvider>()
                                  .recentTransactions[index]
                                  .type ==
                              "withdrawal_fees") {
                            return ListTile(
                              leading: const SizedBox(
                                height: double.infinity,
                                child: Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 40.0,
                                ),
                              ),
                              title: const Text(
                                "Withdrawal Fees",
                                style: TextStyle(fontSize: 20),
                              ),
                              subtitle: Text(
                                  DateFormat('yyyy-MM-dd').format(context
                                      .read<TransactionsProvider>()
                                      .recentTransactions[index]
                                      .date),
                                  style: const TextStyle(fontSize: 16)),
                              trailing: Text(
                                  "R ${((context.read<TransactionsProvider>().recentTransactions[index].amount) * -1).toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            );
                          }
                          // Tile for transactions where I was the customer
                          else if (context
                                  .read<TransactionsProvider>()
                                  .recentTransactions[index]
                                  .type ==
                              "customer") {
                            return ListTile(
                              leading: SizedBox(
                                height: double.infinity,
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: MemoryImage(
                                    base64Decode(context
                                        .read<TransactionsProvider>()
                                        .recentTransactions[index]
                                        .profilePhoto),
                                  ),
                                ),
                              ),
                              title: Text(
                                context
                                    .read<TransactionsProvider>()
                                    .recentTransactions[index]
                                    .name,
                                style: const TextStyle(fontSize: 20),
                              ),
                              subtitle: Text(
                                DateFormat('yyyy-MM-dd').format(context
                                    .read<TransactionsProvider>()
                                    .recentTransactions[index]
                                    .date),
                                style: const TextStyle(fontSize: 16),
                              ),
                              trailing: Text(
                                "R ${((context.read<TransactionsProvider>().recentTransactions[index].amount) * -1).toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          // Tile for transactions where I was the merchant
                          else if (context
                                  .read<TransactionsProvider>()
                                  .recentTransactions[index]
                                  .type ==
                              "merchant") {
                            return ListTile(
                              leading: SizedBox(
                                height: double.infinity,
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: MemoryImage(
                                    base64Decode(context
                                        .read<TransactionsProvider>()
                                        .recentTransactions[index]
                                        .profilePhoto),
                                  ),
                                ),
                              ),
                              title: Text(
                                context
                                    .read<TransactionsProvider>()
                                    .recentTransactions[index]
                                    .name,
                                style: const TextStyle(fontSize: 20),
                              ),
                              subtitle: Text(
                                DateFormat('yyyy-MM-dd').format(context
                                    .read<TransactionsProvider>()
                                    .recentTransactions[index]
                                    .date),
                                style: const TextStyle(fontSize: 16),
                              ),
                              trailing: Text(
                                "R ${(context.read<TransactionsProvider>().recentTransactions[index].amount).toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            );
                          } else {
                            return const ListTile(
                              title: Text("Loading ..."),
                            );
                          }
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return const Divider(
                            color: Color.fromRGBO(169, 169, 169, 1),
                          );
                        },
                      )
                    : const Center(
                        child: Text(
                          "No recent transactions",
                          style: TextStyle(
                            color: Color.fromRGBO(169, 169, 169, 1),
                          ),
                        ),
                      ),
              ),

              // Show more transactions button
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  GoRouter.of(context).push('/transactionhistoryscreen');
                },
                child: const Text('Show More'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // <========== Components ==========>
}
