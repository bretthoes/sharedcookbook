import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sharedcookbook/constants/app_theme.dart';
import 'package:sharedcookbook/features/auth/screens/login_view.dart';
import 'package:sharedcookbook/features/auth/screens/register_view.dart';
import 'package:sharedcookbook/features/auth/screens/verify_email_view.dart';
import 'package:sharedcookbook/layers/services/auth/auth_service.dart';
import 'package:sharedcookbook/layers/screens/cookbooks/create_update_cookbook_view.dart';
import 'package:sharedcookbook/layers/screens/cookbooks/cookbooks_view.dart';
import 'constants/routes.dart';

Future<void> main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Shared Cookbook',
      theme: AppThemeData.lightThemeData,
      home: const HomePage(),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        cookbooksRoute: (context) => const CookbooksView(),
        verifyEmailRoute: (context) => const VerifyEmailView(),
        createOrUpdateCookbookRoute: (context) =>
            const CreateOrUpdateCookbookView(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.firebase().initialize(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = AuthService.firebase().currentUser;
            if (user != null) {
              if (user.isEmailVerified) {
                return const CookbooksView();
              } else {
                return const VerifyEmailView();
              }
            } else {
              return const LoginView();
            }
          default:
            return const CircularProgressIndicator();
        }
      },
    );
  }
}
