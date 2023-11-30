import 'package:flutter/material.dart';
import 'package:sharedcookbook/constants/routes.dart';
import 'package:sharedcookbook/layers/services/auth/auth_service.dart';

class VerifyEmailView extends StatelessWidget {
  const VerifyEmailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: Column(
        children: [
          const Text(
              'We\'ve sent you an email verification.\nIf you didn\'t receive an email, please click the link below to send another.'),
          TextButton(
            onPressed: () async {
              await AuthService.firebase().sendEmailVerification();
            },
            child: const Text('Send email verification.'),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.firebase().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  registerRoute,
                  (route) => false,
                );
              }
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }
}
