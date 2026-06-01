import 'dart:typed_data';

/// Represents a node in a parsed BER-TLV (Tag-Length-Value) tree structure.
class TlvNode {
  /// The integer representation of the EMV Tag (e.g. 0x5A, 0x9F36).
  final int tag;

  /// The length of the value field in bytes.
  final int length;

  /// The raw value payload of this TLV tag.
  final Uint8List value;

  /// List of nested TLV nodes if this tag is constructed (e.g. templates like 0x61, 0x77).
  final List<TlvNode> children;

  /// Whether this node represents a constructed tag containing children.
  final bool isConstructed;

  /// Creates a [TlvNode] representing a parsed BER-TLV tag structure.
  const TlvNode({
    required this.tag,
    required this.length,
    required this.value,
    this.children = const [],
    required this.isConstructed,
  });

  /// Recursively searches the tree to find the first tag matching [targetTag].
  TlvNode? find(int targetTag) {
    if (tag == targetTag) return this;
    for (final child in children) {
      final found = child.find(targetTag);
      if (found != null) return found;
    }
    return null;
  }

  /// Recursively searches the tree to find all tags matching [targetTag].
  List<TlvNode> findAll(int targetTag) {
    final results = <TlvNode>[];
    if (tag == targetTag) results.add(this);
    for (final child in children) {
      results.addAll(child.findAll(targetTag));
    }
    return results;
  }
}
