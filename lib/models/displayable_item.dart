/// An abstract class representing an item that can be displayed in a list.
///
/// This class defines a common interface for items that need to be
/// identified, named, and tracked for completion status in UI components.
abstract class DisplayableItem {
  /// A unique identifier for the item.
  /// This is typically used for widget keys in Flutter to efficiently update the UI.
  dynamic get id; // Used for widget keys

  /// The display name of the item.
  String get name;

  /// Indicates whether the item is considered completed (e.g., checked off in a list).
  bool get isCompleted;
  // Add other common fields if necessary, or keep it minimal
}
