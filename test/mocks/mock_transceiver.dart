import 'dart:typed_data';
import 'package:smart_emv/src/transport/nfc_transceiver.dart';
import 'package:smart_emv/src/utils/hex_utils.dart';

/// A programmable mock implementation of [NfcTransceiver] used to simulate card chip behavior in offline unit tests.
class MockTransceiver implements NfcTransceiver {
  /// Map of hexadecimal command strings to their corresponding hexadecimal response strings.
  final Map<String, String> responses = {};

  /// Log of all hexadecimal commands sent to the transceiver in order.
  final List<String> commandsSent = [];

  /// Flag indicating if the close method was called.
  bool wasClosed = false;

  /// Registers a programmable response for a specific APDU command.
  void addResponse(String commandHex, String responseHex) {
    final cleanCmd = commandHex.toUpperCase().replaceAll(' ', '');
    final cleanRes = responseHex.toUpperCase().replaceAll(' ', '');
    responses[cleanCmd] = cleanRes;
  }

  @override
  Future<Uint8List> transceive(Uint8List command) async {
    final hexCmd = HexUtils.bytesToHex(command);
    commandsSent.add(hexCmd);

    final match = responses[hexCmd];
    if (match != null) {
      return HexUtils.hexToBytes(match);
    }

    // Return standard ISO 7816 error status "6A82" (File/Application not found) as fallback
    return HexUtils.hexToBytes('6A82');
  }

  @override
  Future<void> close() async {
    wasClosed = true;
  }
}
