import 'package:flutter/material.dart';

class CompletableItemName extends StatelessWidget {
  final String name;
  final bool isCompleted;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const CompletableItemName({
    super.key,
    required this.name,
    required this.isCompleted,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Determine a base style if none is provided, falling back to bodyLarge
    final TextStyle defaultStyle = theme.textTheme.bodyLarge ?? const TextStyle();
    
    // Use the provided style or the default style
    final TextStyle effectiveStyle = style ?? defaultStyle;

    return Text(
      name,
      style: effectiveStyle.copyWith(
        decoration: isCompleted ? TextDecoration.lineThrough : null,
        color: isCompleted ? Colors.grey.shade600 : effectiveStyle.color,
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
