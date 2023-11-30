import 'package:flutter/material.dart';
import 'package:sharedcookbook/layers/services/auth/auth_service.dart';
import 'package:sharedcookbook/layers/services/crud/cookbook_service.dart';
import 'package:sharedcookbook/utilities/generics/get_arguments.dart';

class CreateOrUpdateCookbookView extends StatefulWidget {
  const CreateOrUpdateCookbookView({Key? key}) : super(key: key);

  @override
  State<CreateOrUpdateCookbookView> createState() =>
      _CreateOrUpdateCookbookViewState();
}

class _CreateOrUpdateCookbookViewState
    extends State<CreateOrUpdateCookbookView> {
  DatabaseCookbook? _cookbook;
  late final CookbookService _cookbookService;
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    _cookbookService = CookbookService();
    _textEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _deleteCookbookIfTitleIsEmpty();
    _saveCookbookIfTextNotEmpty();
    _textEditingController.dispose();
    super.dispose();
  }

  void _textControllerListener() async {
    final cookbook = _cookbook;
    if (cookbook == null) {
      return;
    } else {
      final title = _textEditingController.text;
      await _cookbookService.updateCookbookTitle(
        cookbook: cookbook,
        title: title,
      );
    }
  }

  void _setupTextControllerListener() {
    _textEditingController.removeListener(_textControllerListener);
    _textEditingController.addListener(_textControllerListener);
  }

  Future<DatabaseCookbook> createOrGetExistingCookbook(
      BuildContext context) async {
    // If found in the widget context, update internal cookbook and return it
    final widgetCookbook = context.getArgument<DatabaseCookbook>();
    if (widgetCookbook != null) {
      _cookbook = widgetCookbook;
      _textEditingController.text = widgetCookbook.title;
      return widgetCookbook;
    }

    // If the internal cookbook exists, return it
    if (_cookbook != null) {
      return _cookbook!;
    }

    // If no cookbook exists yet, create a new one and return it
    final currentUser = AuthService.firebase().currentUser!;
    final email = currentUser.email!;
    final owner = await _cookbookService.getUserByEmail(email: email);
    final newCookbook = await _cookbookService.createCookbook(owner: owner);
    _cookbook = newCookbook;
    return newCookbook;
  }

  void _deleteCookbookIfTitleIsEmpty() async {
    final cookbook = _cookbook;
    if (_textEditingController.text.trim().isEmpty && cookbook != null) {
      await _cookbookService.deleteCookbookById(id: cookbook.id);
    }
  }

  void _saveCookbookIfTextNotEmpty() async {
    final cookbook = _cookbook;
    final title = _textEditingController.text.trim();
    if (cookbook != null && title.isNotEmpty) {
      await _cookbookService.updateCookbookTitle(
        cookbook: cookbook,
        title: title,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Cookbook'),
      ),
      body: FutureBuilder(
        future: createOrGetExistingCookbook(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _setupTextControllerListener();
              return TextField(
                controller: _textEditingController,
                decoration: const InputDecoration(
                  hintText: 'Title of your cookbook...',
                ),
              );
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
