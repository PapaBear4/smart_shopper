import 'package:flutter/material.dart';

class EmptyListWidget extends StatelessWidget {
  final String message;
  const EmptyListWidget({super.key, this.message = 'No items found.'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
