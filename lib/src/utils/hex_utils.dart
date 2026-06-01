import 'dart:typed_data';

/// Utility class for hexadecimal string and byte conversions, as well as PAN and Expiry formatting.
class HexUtils {
  /// Converts a hexadecimal string to [Uint8List] bytes.
  /// Removes any spaces from the input string before parsing.
  static Uint8List hexToBytes(String hex) {
    final cleanHex = hex.replaceAll(' ', '');
    if (cleanHex.length % 2 != 0) {
      throw ArgumentError('Hex string must have an even length');
    }

    final bytes = Uint8List(cleanHex.length ~/ 2);
    for (var i = 0; i < cleanHex.length; i += 2) {
      final hexChar1 = cleanHex[i];
      final hexChar2 = cleanHex[i + 1];

      final val1 = int.parse(hexChar1, radix: 16);
      final val2 = int.parse(hexChar2, radix: 16);

      bytes[i ~/ 2] = (val1 << 4) + val2;
    }
    return bytes;
  }

  /// Converts [Uint8List] bytes to an uppercase hexadecimal string.
  static String bytesToHex(Uint8List bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join('');
  }

  /// Formats a card PAN (Primary Account Number) with spaces every 4 characters.
  /// Example: "1234567890123456" -> "1234 5678 9012 3456"
  static String formatPan(String pan) {
    final cleanPan = pan.replaceAll(' ', '');
    final chunks = <String>[];
    for (var i = 0; i < cleanPan.length; i += 4) {
      final end = (i + 4 < cleanPan.length) ? i + 4 : cleanPan.length;
      chunks.add(cleanPan.substring(i, end));
    }
    return chunks.join(' ');
  }

  /// Formats a hexadecimal expiry date representation.
  /// Typically, cards return YYMM (or YYMMDD, etc.) in hex tags (e.g. 5F24).
  /// Example: "2512" (Dec 2025) -> "12/25"
  static String formatExpiry(String hex) {
    final cleanHex = hex.trim();
    if (cleanHex.length >= 4) {
      final year = cleanHex.substring(0, 2);
      final month = cleanHex.substring(2, 4);
      return '$month/$year';
    }
    return hex;
  }
}
