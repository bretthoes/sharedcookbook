import 'package:flutter/material.dart';
import 'package:sharedcookbook/utilities/dialogs/generic_dialog.dart';

Future<bool> showLogoutDialog(BuildContext context) async {
  return showGenericDialog<bool>(
    context: context,
    title: 'Log out',
    content: 'Are you sure you want to log out?',
    dialogOptionBuilder: () => {
      'Yes': true,
      'Cancel': false,
    },
  ).then(
    (value) => value ?? false,
  );
}
