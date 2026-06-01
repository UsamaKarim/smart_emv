import 'dart:typed_data';
import '../models/tlv_node.dart';

/// BER-TLV (Basic Encoding Rules - Tag Length Value) parser implemented in pure Dart.
/// Decodes binary byte packets recursively according to the ISO/IEC 7816-4 specification.
class TlvParser {
  /// Parses a complete raw byte payload into a root [TlvNode] or null if
  /// parsing fails. The caller is responsible for stripping the trailing
  /// status bytes (SW1/SW2) before passing the data; use [ApduResponse.payload]
  /// for convenience.
  static TlvNode? parse(Uint8List data) {
    if (data.length < 2) return null;
    try {
      final nodes = parseRecursive(data, 0, data.length);
      return nodes.isNotEmpty ? nodes.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Parses bytes recursively within a given byte range [start] and [end].
  static List<TlvNode> parseRecursive(Uint8List data, int start, int end) {
    final nodes = <TlvNode>[];
    var i = start;

    while (i < end) {
      final tagFirstByte = data[i] & 0xFF;

      // Skip padding bytes (0x00 and 0xFF are padding in BER-TLV)
      if (tagFirstByte == 0x00 || tagFirstByte == 0xFF) {
        i++;
        continue;
      }

      var tag = tagFirstByte;
      i++;

      // Determine if multi-byte tag (subsequent bytes indicated by bottom 5 bits all set: XX111111 = 0x1F)
      if ((tagFirstByte & 0x1F) == 0x1F) {
        if (i >= end) break;

        tag = (tag << 8) | (data[i] & 0xFF);

        // If MSB of the subsequent byte is set, another tag byte follows (up to 3 bytes total supported)
        if ((data[i] & 0x80) != 0) {
          i++;
          if (i >= end) break;
          tag = (tag << 8) | (data[i] & 0xFF);
        }
        i++;
      }

      if (i >= end) break;

      // Parse Length
      var len = data[i] & 0xFF;
      i++;

      // If MSB of length byte is set, it represents a long-form length encoding
      if (len > 0x80) {
        final lenBytes = len & 0x7F;
        len = 0;
        for (var j = 0; j < lenBytes; j++) {
          if (i >= end) break;
          len = (len << 8) | (data[i] & 0xFF);
          i++;
        }
      }

      if (i + len > end) break;

      final value = Uint8List.sublistView(data, i, i + len);

      // Tag bit 6 (0x20) indicates whether it is constructed (contains child nodes)
      final isConstructed = (tagFirstByte & 0x20) != 0;
      final children = isConstructed
          ? parseRecursive(data, i, i + len)
          : const <TlvNode>[];

      nodes.add(
        TlvNode(
          tag: tag,
          length: len,
          value: value,
          children: children,
          isConstructed: isConstructed,
        ),
      );

      i += len;
    }

    return nodes;
  }
}
