import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:occomy/providers/transaction_provider.dart';
import 'package:provider/provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  // <========== Variables ==========>
  List<Transaction> transactions = [];
  final searchController = TextEditingController();

  // <========== Functions ==========>
  void searchTransaction(String query) {
    final suggestions = context
        .read<TransactionsProvider>()
        .allTransactions
        .where((transaction) {
      final name = transaction.name.toLowerCase();
      final input = query.toLowerCase();
      return name.contains(input);
    }).toList();

    setState(() {
      transactions = suggestions;
    });
  }

  // <========== Page appears ==========>
  @override
  void initState() {
    setState(() {
      transactions = context.read<TransactionsProvider>().allTransactions;
    });
    super.initState();
  }

  // <========== Page dissapears ==========>
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    searchController.dispose();

    super.dispose();
  }

  // <========== Body ==========>
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // The search bar
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: "Search",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(15.0),
                    ),
                  ),
                ),
                onChanged: searchTransaction,
              ),
            ),

            // The list of transactions
            Expanded(
              child: transactions.isNotEmpty
                  ? ListView.separated(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        // Tile for deposit
                        if (transaction.type == "deposit") {
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
                                DateFormat('yyyy-MM-dd')
                                    .format(transaction.date),
                                style: const TextStyle(fontSize: 16)),
                            trailing: Text(
                                "R ${(transaction.amount).toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          );
                        }
                        // Tile for withdrawal
                        else if (transaction.type == "withdrawal") {
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
                                DateFormat('yyyy-MM-dd')
                                    .format(transaction.date),
                                style: const TextStyle(fontSize: 16)),
                            trailing: Text(
                                "R ${((transaction.amount) * -1).toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          );
                        }
                        // Tile for withdrawal fees
                        else if (transaction.type == "withdrawal_fees") {
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
                                DateFormat('yyyy-MM-dd')
                                    .format(transaction.date),
                                style: const TextStyle(fontSize: 16)),
                            trailing: Text(
                                "R ${((transaction.amount) * -1).toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          );
                        }
                        // Tile for transactions where I was the customer
                        else if (transaction.type == "customer") {
                          return ListTile(
                            leading: SizedBox(
                              height: double.infinity,
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.transparent,
                                backgroundImage: MemoryImage(
                                  base64Decode(transaction.profilePhoto),
                                ),
                              ),
                            ),
                            title: Text(
                              transaction.name,
                              style: const TextStyle(fontSize: 20),
                            ),
                            subtitle: Text(
                              DateFormat('yyyy-MM-dd').format(transaction.date),
                              style: const TextStyle(fontSize: 16),
                            ),
                            trailing: Text(
                              "R ${((transaction.amount) * -1).toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                        // Tile for transactions where I was the merchant
                        else if (transaction.type == "merchant") {
                          return ListTile(
                            leading: SizedBox(
                              height: double.infinity,
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.transparent,
                                backgroundImage: MemoryImage(
                                  base64Decode(transaction.profilePhoto),
                                ),
                              ),
                            ),
                            title: Text(
                              transaction.name,
                              style: const TextStyle(fontSize: 20),
                            ),
                            subtitle: Text(
                              DateFormat('yyyy-MM-dd').format(transaction.date),
                              style: const TextStyle(fontSize: 16),
                            ),
                            trailing: Text(
                              "R ${(transaction.amount).toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                        // Tiles for dividers
                        else if (transaction.type == "divider") {
                          return Padding(
                            padding: const EdgeInsets.only(top: 5, bottom: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('MMMM yyyy')
                                      .format(transaction.date),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
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
          ],
        ),
      ),
    );
  }
}
