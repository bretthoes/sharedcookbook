import 'package:flutter/material.dart';
import 'package:sharedcookbook/layers/services/crud/cookbook_service.dart';
import 'package:sharedcookbook/utilities/dialogs/delete_cookbook_dialog.dart';

typedef CookbookCallback = void Function(DatabaseCookbook cookbook);

class CookbooksListView extends StatelessWidget {
  final List<DatabaseCookbook> cookbooks;
  final CookbookCallback onDeleteCookbook;
  final CookbookCallback onTap;

  const CookbooksListView({
    super.key,
    required this.cookbooks,
    required this.onDeleteCookbook,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final cookbook = cookbooks[index];
        return ListTile(
          onTap: () {
            onTap(cookbook);
          },
          title: Text(
            cookbook.title,
            maxLines: 1,
            softWrap: true,
            overflow: TextOverflow.fade,
          ),
          trailing: IconButton(
            onPressed: () async {
              final shouldDelete = await showDeleteCookbookDialog(context);
              if (shouldDelete) {
                onDeleteCookbook(cookbook);
              }
            },
            icon: const Icon(Icons.delete),
          ),
        );
      },
      itemCount: cookbooks.length,
    );
  }
}
