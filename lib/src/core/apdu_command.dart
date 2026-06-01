import 'dart:typed_data';
import '../utils/hex_utils.dart';

/// Helper class to construct standard ISO 7816 / EMV APDU (Application Protocol Data Unit) command bytes.
class ApduCommand {
  /// Builds a command to select the PPSE (Proximity Payment System Environment) DDF: "2PAY.SYS.DDF01".
  static Uint8List selectPpse() {
    return HexUtils.hexToBytes('00A404000E325041592E5359532E444446303100');
  }

  /// Builds a command to select a specific card Application Identifier (AID) represented in hex.
  static Uint8List selectAid(String aidHex) {
    final aidBytes = HexUtils.hexToBytes(aidHex);
    final lenHex = aidBytes.length
        .toRadixString(16)
        .padLeft(2, '0')
        .toUpperCase();
    return HexUtils.hexToBytes(
      '00A40400$lenHex${HexUtils.bytesToHex(aidBytes)}00',
    );
  }

  /// Builds a Get Processing Options (GPO) command payload.
  /// Constructs the payload using Tag 83 (Command Template).
  static Uint8List getProcessingOptions(Uint8List pdolData) {
    final builder = BytesBuilder();
    builder.addByte(0x83); // Command Template Tag

    // Length formatting
    if (pdolData.length > 0x7F) {
      builder.addByte(0x81);
    }
    builder.addByte(pdolData.length);
    builder.add(pdolData);

    final gpoPayload = builder.toBytes();
    final lenHex = gpoPayload.length
        .toRadixString(16)
        .padLeft(2, '0')
        .toUpperCase();

    final header = HexUtils.hexToBytes('80A80000$lenHex');
    final cmd = BytesBuilder();
    cmd.add(header);
    cmd.add(gpoPayload);
    cmd.addByte(0x00); // Le

    return cmd.toBytes();
  }

  /// Builds a GPO command payload without any PDOL data (fallback case).
  static Uint8List getFallbackGpo() {
    return HexUtils.hexToBytes('80A8000002830000');
  }

  /// Builds a READ RECORD command for a specific SFI (Short File Identifier) and record index.
  static Uint8List readRecord(int sfi, int recordIndex) {
    final p2 = (sfi << 3) | 4;
    final recHex = recordIndex.toRadixString(16).padLeft(2, '0').toUpperCase();
    final p2Hex = p2.toRadixString(16).padLeft(2, '0').toUpperCase();
    return HexUtils.hexToBytes('00B2$recHex${p2Hex}00');
  }

  /// Builds a GET DATA command for a particular two-byte EMV tag.
  static Uint8List getData(int tag) {
    final tagHex = tag.toRadixString(16).padLeft(4, '0').toUpperCase();
    return HexUtils.hexToBytes('80CA${tagHex}00');
  }
}
