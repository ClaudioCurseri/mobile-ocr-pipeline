import 'package:flutter/material.dart';

class Buttons {
  static Widget buildConfigBtn({
    required IconData icon,
    required String text,
    required bool config,
    required VoidCallback onPressed,
    required BuildContext context
  }) {
    return OutlinedButton.icon(
      style: TextButton.styleFrom(
        iconSize: 20,
        side: BorderSide(
          width: 1,
          color: config
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: config
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      label: Text(
        text,
        style: TextStyle(
          color: config
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static Widget buildReviewBtn({
    required Icon icon,
    required VoidCallback onPressed,
    required String text,
    required BuildContext context
  }) {
    return OutlinedButton.icon(
      style: TextButton.styleFrom(
        iconSize: 30,
        side: BorderSide(
          width: 1,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      onPressed: onPressed,
      icon: icon,
      label: Text(text),
    );
  }
}