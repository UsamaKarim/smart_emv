import 'dart:typed_data';

/// Abstract interface layer that decouples the core EMV parsing logic from the concrete NFC hardware library.
/// This allows the core parser to remain fully unit-testable offline by mocking the transceive connection.
abstract class NfcTransceiver {
  /// Transmits raw APDU command bytes and returns raw response bytes (including status words SW1/SW2).
  Future<Uint8List> transceive(Uint8List command);

  /// Closes the transceiver channel and finishes the NFC session.
  Future<void> close();
}
