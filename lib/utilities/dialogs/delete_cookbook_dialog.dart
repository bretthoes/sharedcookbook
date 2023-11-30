import 'package:flutter/material.dart';
import 'package:sharedcookbook/utilities/dialogs/generic_dialog.dart';

Future<bool> showDeleteCookbookDialog(BuildContext context) async {
  return showGenericDialog<bool>(
    context: context,
    title: 'Delete cookbook',
    content: 'Are you sure you want to delete this cookbook?',
    dialogOptionBuilder: () => {
      'Yes': true,
      'Cancel': false,
    },
  ).then(
    (value) => value ?? false,
  );
}
