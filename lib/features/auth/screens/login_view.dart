import 'package:flutter/material.dart';
import 'package:sharedcookbook/constants/routes.dart';
import 'package:sharedcookbook/layers/services/auth/auth_exceptions.dart';
import 'package:sharedcookbook/layers/services/auth/auth_service.dart';
import 'package:sharedcookbook/utilities/dialogs/error_dialog.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Column(
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'Enter your email here',
            ),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'Enter your password here',
            ),
          ),
          TextButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;
              try {
                if (email.isEmpty || password.isEmpty) {
                  if (context.mounted) {
                    await showErrorDialog(
                      context,
                      'Fields cannot be empty',
                    );
                    return;
                  }
                }
                await AuthService.firebase().login(
                  email: email,
                  password: password,
                );
                final user = AuthService.firebase().currentUser;
                if (user?.isEmailVerified ?? false) {
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      cookbooksRoute,
                      (route) => false,
                    );
                  }
                } else {
                  // user's email is not verified
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      verifyEmailRoute,
                      (route) => false,
                    );
                  }
                }
              } on UserNotFoundAuthException {
                if (context.mounted) {
                  await showErrorDialog(
                    context,
                    'User not found',
                  );
                }
              } on WrongPasswordAuthException {
                if (context.mounted) {
                  await showErrorDialog(
                    context,
                    'Wrong password',
                  );
                }
              } on InvalidEmailAuthException {
                if (context.mounted) {
                  await showErrorDialog(
                    context,
                    'Email is invalid',
                  );
                }
              } on InvalidLoginCredentialsAuthException {
                if (context.mounted) {
                  await showErrorDialog(
                    context,
                    'Invalid credentials',
                  );
                }
              } on GenericAuthException {
                if (context.mounted) {
                  await showErrorDialog(
                    context,
                    'Authentication error occurred',
                  );
                }
              }
            },
            child: const Text('Login'),
          ),
          TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  registerRoute,
                  (route) => false,
                );
              },
              child: const Text('Register here'))
        ],
      ),
    );
  }
}
