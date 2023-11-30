import 'package:flutter/material.dart';
import 'package:sharedcookbook/utilities/dialogs/generic_dialog.dart';

Future<void> showErrorDialog(
  BuildContext context,
  String text,
) async {
  return showGenericDialog(
    context: context,
    title: 'An error occurred',
    content: text,
    dialogOptionBuilder: () => {'OK': null},
  );
}
