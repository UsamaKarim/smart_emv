import 'dart:typed_data';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import '../utils/hex_utils.dart';
import 'nfc_transceiver.dart';

/// Default concrete implementation of [NfcTransceiver] using the external [flutter_nfc_kit] package.
class FlutterNfcKitTransceiver implements NfcTransceiver {
  /// Creates a standard [FlutterNfcKitTransceiver] wrapper.
  const FlutterNfcKitTransceiver();

  @override
  Future<Uint8List> transceive(Uint8List command) async {
    final hexCommand = HexUtils.bytesToHex(command);
    final hexResponse = await FlutterNfcKit.transceive(hexCommand);
    return HexUtils.hexToBytes(hexResponse);
  }

  @override
  Future<void> close() async {
    await FlutterNfcKit.finish();
  }
}
