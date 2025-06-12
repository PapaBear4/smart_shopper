import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/models.dart'; // For DisplayableItem
import '../../common_widgets/completable_item_name.dart';

// Define a callback type for toggling completion, if needed by the specific cubit
typedef ToggleItemCompletionCallback<T extends DisplayableItem> = void Function(T item);
// Define a callback for item tap, if needed
typedef OnItemTapCallback<T extends DisplayableItem> = void Function(T item);
// Define a callback for item dismiss, if needed
typedef OnItemDismissedCallback<T extends DisplayableItem> = void Function(T item);

class StandardListItem<T extends DisplayableItem> extends StatelessWidget {
  final T item;
  final String? titleText; // Added optional titleText
  final List<Widget> subtitleWidgets;
  final ToggleItemCompletionCallback<T>? onToggleCompletion; // Optional: if the list item itself handles this
  final OnItemTapCallback<T>? onItemTap; // Optional: for tap actions
  final OnItemDismissedCallback<T>? onDismissed; // Optional: for dismiss actions
  final Cubit? cubit; // Optional: if actions need to be dispatched via a provided cubit

  const StandardListItem({
    super.key,
    required this.item,
    this.titleText, // Added to constructor
    this.subtitleWidgets = const [],
    this.onToggleCompletion,
    this.onItemTap,
    this.onDismissed,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile = ListTile(
      leading: onToggleCompletion != null
          ? Checkbox(
              value: item.isCompleted,
              onChanged: (bool? value) {
                if (value != null) {
                  onToggleCompletion!(item);
                }
              },
            )
          : null,
      title: CompletableItemName(name: titleText ?? item.name, isCompleted: item.isCompleted), // Use titleText if provided
      subtitle: subtitleWidgets.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subtitleWidgets,
            )
          : null,
      onTap: onItemTap != null ? () => onItemTap!(item) : null,
    );

    if (onDismissed != null) {
      return Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) => onDismissed!(item),
        background: Container(
          color: Colors.redAccent,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerRight,
          child: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
        ),
        child: tile,
      );
    }
    return tile;
  }
}

// Helper to build detail text, can be moved to a common utility if used elsewhere
Widget buildDetailText(String text, {TextStyle? style}) {
  return Padding(
    padding: const EdgeInsets.only(top: 2.0),
    child: Text(
      text,
      style: style ?? TextStyle(fontSize: 13, color: Colors.grey.shade700),
      overflow: TextOverflow.ellipsis,
    ),
  );
}
