import 'dart:math';
import 'dart:typed_data';
import '../models/terminal_config.dart';
import '../utils/hex_utils.dart';

/// Class representing a Tag-Length pair parsed from a card's PDOL (Processing Options Data Object List).
class PdolTag {
  /// The integer value of the EMV Tag.
  final int tag;

  /// The expected byte length of this tag's value.
  final int length;

  /// Creates a new [PdolTag] instance.
  const PdolTag(this.tag, this.length);
}

/// Utility to dynamically decode a card's PDOL template and construct the matching GPO request terminal dataset.
class PdolBuilder {
  /// Parses the PDOL raw bytes into a structured list of [PdolTag] definitions.
  static List<PdolTag> parsePdolTags(Uint8List pdol) {
    final list = <PdolTag>[];
    var i = 0;

    while (i < pdol.length) {
      var tag = pdol[i] & 0xFF;
      i++;

      // Multi-byte tags (bits 1-5 set to 1)
      if ((tag & 0x1F) == 0x1F) {
        if (i >= pdol.length) break;
        tag = (tag << 8) | (pdol[i] & 0xFF);
        i++;
      }

      if (i >= pdol.length) break;
      final len = pdol[i] & 0xFF;
      i++;

      list.add(PdolTag(tag, len));
    }
    return list;
  }

  /// Iterates through [PdolTag] definitions and builds a filled byte array of terminal data.
  static Uint8List buildPdolResponse(
    Uint8List pdolBytes,
    TerminalConfig config,
  ) {
    if (pdolBytes.isEmpty) return Uint8List(0);

    final tags = parsePdolTags(pdolBytes);
    final builder = BytesBuilder();

    for (final element in tags) {
      final value = _getTerminalValueForTag(
        element.tag,
        element.length,
        config,
      );
      builder.add(value);
    }

    return builder.toBytes();
  }

  /// Generates the terminal value for a specific EMV tag, matching the requested length exactly.
  static Uint8List _getTerminalValueForTag(
    int tag,
    int length,
    TerminalConfig config,
  ) {
    Uint8List rawBytes;

    switch (tag) {
      case 0x9F66: // Terminal Transaction Qualifiers
        rawBytes = HexUtils.hexToBytes(config.transactionQualifiers);
        break;
      case 0x9F1A: // Terminal Country Code
        rawBytes = HexUtils.hexToBytes(config.countryCode);
        break;
      case 0x5F2A: // Transaction Currency Code
        rawBytes = HexUtils.hexToBytes(config.currencyCode);
        break;
      case 0x9A: // Transaction Date (YYMMDD format)
        final now = DateTime.now();
        final year = now.year.toString().substring(
          now.year.toString().length - 2,
        );
        final month = now.month.toString().padLeft(2, '0');
        final day = now.day.toString().padLeft(2, '0');
        rawBytes = HexUtils.hexToBytes('$year$month$day');
        break;
      case 0x9C: // Transaction Type (00 for Purchase)
        rawBytes = HexUtils.hexToBytes('00');
        break;
      case 0x9F37: // Unpredictable Number (Random bytes)
        final random = Random();
        final bytes = Uint8List(length);
        for (var idx = 0; idx < length; idx++) {
          bytes[idx] = random.nextInt(256);
        }
        rawBytes = bytes;
        break;
      case 0x9F33: // Terminal Capabilities
        rawBytes = HexUtils.hexToBytes(config.terminalCapabilities);
        break;
      case 0x9F40: // Additional Terminal Capabilities
        rawBytes = HexUtils.hexToBytes(config.additionalTerminalCapabilities);
        break;
      case 0x9F1E: // Interface Device (IFD) Serial Number
        rawBytes = HexUtils.hexToBytes(config.interfaceDeviceSerialNumber);
        break;
      case 0x9F35: // Terminal Type
        rawBytes = HexUtils.hexToBytes(config.terminalType);
        break;
      default:
        // Fill unknown tags with zeroes
        rawBytes = Uint8List(length);
        break;
    }

    // Standardize output bytes to match the requested length exactly
    if (rawBytes.length > length) {
      return Uint8List.sublistView(rawBytes, 0, length);
    } else if (rawBytes.length < length) {
      final padded = Uint8List(length);
      padded.setRange(0, rawBytes.length, rawBytes);
      return padded;
    }

    return rawBytes;
  }
}
