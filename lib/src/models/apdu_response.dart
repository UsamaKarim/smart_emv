import 'dart:typed_data';

/// Encapsulates a smart card response to an APDU (Application Protocol Data Unit) command.
class ApduResponse {
  /// The full raw response bytes, containing the payload and the final status bytes (SW1, SW2).
  final Uint8List data;

  /// Creates a new [ApduResponse] instance with the raw [data] bytes.
  const ApduResponse(this.data);

  /// Status Word 1 (the second to last byte in the response).
  int get sw1 {
    if (data.length < 2) return 0x00;
    return data[data.length - 2];
  }

  /// Status Word 2 (the final byte in the response).
  int get sw2 {
    if (data.length < 2) return 0x00;
    return data[data.length - 1];
  }

  /// Returns true if the status words indicate standard successful execution (e.g. 0x9000 or 0x91XX).
  bool get isSuccess {
    if (data.length < 2) return false;
    return (sw1 == 0x90 && sw2 == 0x00) || sw1 == 0x91;
  }

  /// The raw payload payload without the trailing status bytes (SW1, SW2).
  Uint8List get payload {
    if (data.length <= 2) return Uint8List(0);
    return Uint8List.sublistView(data, 0, data.length - 2);
  }
}
