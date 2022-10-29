import 'package:occomy/views/home/incoming_requests.dart';
import 'package:occomy/views/send/send_payment.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:occomy/views/home/home.dart';
import 'package:occomy/views/home/transaction_history.dart';
import 'package:occomy/views/home/withdrawal.dart';
import 'package:occomy/views/login/auto_login.dart';
import 'package:occomy/views/login/login.dart';
import 'package:occomy/views/login/register.dart';
import 'package:occomy/views/login/verify_email.dart';
import 'package:occomy/views/send/send_request.dart';
import 'package:occomy/views/settings/editprofile.dart';
import 'package:occomy/views/settings/financialdetails.dart';
import 'package:occomy/views/settings/helpandlegal.dart';
import 'package:occomy/views/transact/approve.dart';
import 'package:occomy/views/transact/payment_tag.dart';
import 'package:occomy/views/transact/qr_scanner.dart';
import 'package:occomy/views/transact/request_payment.dart';

class OccomyRouter {
  late final router = GoRouter(
    routes: [
      // Login screen
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const AutoLogin(),
      ),
      GoRoute(
        path: '/approvalscreen',
        builder: (BuildContext context, GoRouterState state) => ApprovalScreen(
          approvalScreenData: state.extra as ApprovalScreenData,
        ),
      ),
      GoRoute(
        path: '/editprofilescreen',
        builder: (BuildContext context, GoRouterState state) =>
            const EditProfileScreen(),
      ),
      GoRoute(
        path: '/financialdetailsscreen',
        builder: (BuildContext context, GoRouterState state) =>
            const FinancialDetailsScreen(),
      ),
      GoRoute(
        path: '/helpandlegalscreen',
        builder: (BuildContext context, GoRouterState state) =>
            const HelpAndLegalScreen(),
      ),
      GoRoute(
        path: '/homescreen',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ),
      GoRoute(
        path: '/incomingrequestsscreen',
        builder: (BuildContext context, GoRouterState state) =>
            const IncomingRequestsScreen(),
      ),
      GoRoute(
        path: '/loginscreen',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: '/paymenttagscreen/:amount/:documentID/:transactionID',
        builder: (BuildContext context, GoRouterState state) =>
            PaymentTagScreen(
                amount: state.params["amount"]!,
                documentID: state.params["documentID"]!,
                transactionID: state.params["transactionID"]!),
      ),
      GoRoute(
        path: '/qrscannerscreen',
        builder: (BuildContext context, GoRouterState state) =>
            const QRScannerScreen(),
      ),
      GoRoute(
        path: '/recipientscreen/:amount',
        builder: (BuildContext context, GoRouterState state) =>
            SendPaymentScreen(amount: state.params["amount"]!),
      ),
      GoRoute(
        path: '/registerscreen',
        builder: (BuildContext context, GoRouterState state) =>
            const RegisterScreen(),
      ),
      GoRoute(
        path: '/requestpaymentscreen',
        builder: (BuildContext context, GoRouterState state) =>
            const RequestPaymentScreen(),
      ),
      GoRoute(
        path: '/sendrequestscreen/:amount',
        builder: (BuildContext context, GoRouterState state) =>
            SendRequestScreen(amount: state.params["amount"]!),
      ),
      GoRoute(
        path: '/transactionhistoryscreen',
        builder: (BuildContext context, GoRouterState state) =>
            const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: '/verifyemailscreen',
        builder: (BuildContext context, GoRouterState state) =>
            const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/withdrawalscreen',
        builder: (BuildContext context, GoRouterState state) =>
            const WithdrawalScreen(),
      ),
    ],
  );
}
