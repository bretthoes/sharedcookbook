import 'package:flutter/material.dart';
import 'package:sharedcookbook/constants/routes.dart';
import 'package:sharedcookbook/enums/menu_action.dart';
import 'package:sharedcookbook/layers/services/auth/auth_service.dart';
import 'package:sharedcookbook/layers/services/crud/cookbook_service.dart';
import 'package:sharedcookbook/utilities/dialogs/logout_dialog.dart';
import 'package:sharedcookbook/layers/screens/cookbooks/cookbooks_list_view.dart';

class CookbooksView extends StatefulWidget {
  const CookbooksView({super.key});

  @override
  State<CookbooksView> createState() => _CookbooksViewState();
}

class _CookbooksViewState extends State<CookbooksView> {
  late final CookbookService _cookbookService;
  String get userEmail => AuthService.firebase().currentUser!.email!;

  @override
  void initState() {
    _cookbookService = CookbookService();
    _cookbookService.open();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cookbooks'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(createOrUpdateCookbookRoute);
            },
            icon: const Icon(Icons.add),
          ),
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogoutDialog(context);
                  if (shouldLogout) {
                    await AuthService.firebase().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        loginRoute,
                        (_) => false,
                      );
                    }
                  }
                  break;
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<MenuAction>(
                  value: MenuAction.logout,
                  child: Text('Log out'),
                )
              ];
            },
          )
        ],
      ),
      body: FutureBuilder(
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return StreamBuilder(
                stream: _cookbookService.allCookbooks,
                builder: ((context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                    case ConnectionState.active:
                      if (snapshot.hasData) {
                        final allCookbooks =
                            snapshot.data as List<DatabaseCookbook>;
                        return CookbooksListView(
                          onTap: (cookbook) {
                            Navigator.of(context).pushNamed(
                              createOrUpdateCookbookRoute,
                              arguments: cookbook,
                            );
                          },
                          cookbooks: allCookbooks,
                          onDeleteCookbook: (cookbook) async {
                            await _cookbookService.deleteCookbookById(
                              id: cookbook.id,
                            );
                          },
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    case ConnectionState.none:
                    case ConnectionState.done:
                    default:
                      return const CircularProgressIndicator();
                  }
                }),
              );
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
            default:
              return const CircularProgressIndicator();
          }
        },
        future: _cookbookService.getOrCreateUser(email: userEmail),
      ),
    );
  }
}
