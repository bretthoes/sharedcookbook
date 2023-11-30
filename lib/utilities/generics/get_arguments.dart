import 'package:flutter/material.dart' show BuildContext, ModalRoute;

extension GetArgument on BuildContext {
  T? getArgument<T>() {
    final args = ModalRoute.of(this)?.settings.arguments;

    // Return the arguments if they exist and match
    // the desired type, otherwise return null.
    return (args != null && args is T) ? args as T : null;
  }
}
