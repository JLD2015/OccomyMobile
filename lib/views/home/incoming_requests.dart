import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:occomy/providers/requests_provider.dart';
import 'package:provider/provider.dart';

import '../transact/approve.dart';

class IncomingRequestsScreen extends StatefulWidget {
  const IncomingRequestsScreen({super.key});

  @override
  State<IncomingRequestsScreen> createState() => _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState extends State<IncomingRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Requests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Recent transactions
            Expanded(
              child: context.watch<RequestsProvider>().allRequests.isNotEmpty
                  ? ListView.separated(
                      itemCount:
                          context.watch<RequestsProvider>().allRequests.length,
                      itemBuilder: (context, index) {
                        final paymentRequest = context
                            .watch<RequestsProvider>()
                            .allRequests[index];
                        return ListTile(
                          leading: SizedBox(
                            height: double.infinity,
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.transparent,
                              backgroundImage: MemoryImage(
                                base64Decode(paymentRequest.profilePhoto),
                              ),
                            ),
                          ),
                          title: Text(paymentRequest.merchantName,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            paymentRequest.description,
                            style: const TextStyle(fontSize: 16),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              // Move over to the approval screen
                              var merchantPhoto = paymentRequest.profilePhoto;
                              var merchantName = paymentRequest.merchantName;
                              var amount = paymentRequest.amount.toString();
                              var transactionID = paymentRequest.transactionID;
                              var documentID = paymentRequest.documentID;

                              var approvalScreenData = ApprovalScreenData(
                                  merchantPhoto,
                                  merchantName,
                                  amount,
                                  transactionID,
                                  documentID);

                              GoRouter.of(context).push('/approvalscreen',
                                  extra: approvalScreenData);
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(
                                  top: 10, left: 20, right: 20, bottom: 10),
                              child: Text(
                                'Pay',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          isThreeLine: true,
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const Divider(
                          color: Color.fromRGBO(169, 169, 169, 1),
                        );
                      },
                    )
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 300,
                              width: 300,
                              child: Lottie.asset(
                                  'assets/lottie/no_requests.json',
                                  repeat: true),
                            ),
                            const Text(
                              "You don't have any payment requests",
                              style: TextStyle(
                                fontSize: 18,
                                color: Color.fromRGBO(169, 169, 169, 1),
                              ),
                            ),
                          ],
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
