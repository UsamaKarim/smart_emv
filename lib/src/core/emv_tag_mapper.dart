import 'dart:convert';
import 'dart:typed_data';
import '../models/tlv_node.dart';
import '../utils/hex_utils.dart';

/// Decodes binary EMV tags and maps them to standard, friendly textual card fields.
class EmvTagMapper {
  /// Recursively decodes a [TlvNode] structure and saves all extracted values in the [accumulator] map.
  static void mapTagData(TlvNode node, Map<String, String> accumulator) {
    final hexTag = node.tag.toRadixString(16).toUpperCase();
    final hexVal = HexUtils.bytesToHex(node.value);

    // Save every single raw tag parsed for advanced users
    accumulator[hexTag] = hexVal;

    switch (node.tag) {
      case 0x5A: // PAN (Primary Account Number)
        accumulator['pan'] = HexUtils.formatPan(
          hexVal.replaceAll(RegExp(r'[Ff]$'), ''),
        );
        break;
      case 0x5F24: // Expiry Date (YYMMDD format in hex)
        accumulator['expiry'] = HexUtils.formatExpiry(hexVal);
        break;
      case 0x5F20: // Cardholder Name
        accumulator['cardholder'] = _decodeAscii(node.value);
        break;
      case 0x5F53: // IBAN
        accumulator['iban'] = _decodeAscii(node.value);
        break;
      case 0x5F54: // BIC
        accumulator['bic'] = _decodeAscii(node.value);
        break;
      case 0x5F2D: // Language Preference
        accumulator['language'] = _decodeAscii(node.value);
        break;
      case 0x5F28: // Issuer Country Code
        accumulator['country'] = hexVal;
        break;
      case 0x9F36: // Application Transaction Counter (ATC)
        accumulator['atc'] = int.parse(hexVal, radix: 16).toString();
        break;
      case 0x9F17: // PIN Try Counter
        accumulator['pinTry'] = int.parse(hexVal, radix: 16).toString();
        break;
      case 0x9F13: // Last Online ATC
        accumulator['lastOnlineAtc'] = int.parse(hexVal, radix: 16).toString();
        break;
      case 0x9F12: // Preferred Name
        accumulator['preferredName'] = _decodeAscii(node.value);
        break;
      case 0x50: // Application Label
        accumulator['label'] = _decodeAscii(node.value);
        break;
      case 0x9F4D: // Log Entry configuration
        accumulator['logEntry'] = hexVal;
        break;
      case 0x9F4F: // Log Format layout
        accumulator['logFormat'] = hexVal;
        break;
      case 0x5F34: // PAN Sequence Number
        accumulator['panSequenceNumber'] = hexVal;
        break;
      case 0x9F6E: // Third-Party Form Factor
        accumulator['formFactor'] = hexVal;
        break;
      case 0x9F10: // Issuer Application Data (IAD)
        accumulator['issuerData'] = hexVal;
        break;
      case 0x5F42: // Application Currency Code
        accumulator['currencyCode'] = hexVal;
        break;
      case 0x9F5D: // Available Offline Spending Amount
        accumulator['offlineBalance'] = hexVal;
        break;
      case 0x9F52: // Application Default Action
        accumulator['applicationDefaultAction'] = hexVal;
        break;
      case 0x9F6C: // Card Transaction Qualifiers
        accumulator['cardTransactionQualifiers'] = hexVal;
        break;

      case 0x57: // Track 2 Equivalent Data
        final dIndex = hexVal.indexOf('D');
        if (dIndex != -1) {
          if (!accumulator.containsKey('pan')) {
            accumulator['pan'] = HexUtils.formatPan(
              hexVal.substring(0, dIndex).replaceAll(RegExp(r'[Ff]$'), ''),
            );
          }
          if (!accumulator.containsKey('expiry') &&
              hexVal.length >= dIndex + 5) {
            final expiryHex = hexVal.substring(dIndex + 1, dIndex + 5);
            accumulator['expiry'] =
                '${expiryHex.substring(2, 4)}/${expiryHex.substring(0, 2)}';
          }
        }
        break;

      case 0x56: // Track 1 Data
        try {
          final track1Str = _decodeAscii(node.value);
          final caret1 = track1Str.indexOf('^');
          final caret2 = track1Str.indexOf('^', caret1 + 1);
          if (caret1 != -1 && caret2 != -1) {
            final name = track1Str.substring(caret1 + 1, caret2).trim();
            if (name.isNotEmpty) {
              accumulator['cardholder'] = name;
            }
          }
        } catch (_) {}
        break;
    }

    // Traverse children recursively
    for (final child in node.children) {
      mapTagData(child, accumulator);
    }
  }

  /// Converts a raw byte array to an ASCII string, filtering out non-printable characters.
  static String _decodeAscii(Uint8List bytes) {
    try {
      final decoded = ascii.decode(bytes, allowInvalid: true).trim();
      // Remove any non-printable/null control characters
      return decoded.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '');
    } catch (_) {
      return '';
    }
  }
}
