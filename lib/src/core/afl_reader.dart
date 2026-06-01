import 'dart:typed_data';
import '../models/apdu_response.dart';
import '../transport/nfc_transceiver.dart';
import '../utils/emv_logger.dart';
import '../utils/hex_utils.dart';
import '../utils/nfc_error_utils.dart';
import 'apdu_command.dart';
import 'emv_tag_mapper.dart';
import 'tlv_parser.dart';

/// Reads records specified in the card's AFL (Application File Locator) table.
class AflReader {
  /// Scans and parses records in AFL byte list, mapping the extracted tags to the data map.
  static Future<void> readAflRecords({
    required NfcTransceiver transceiver,
    required Uint8List afl,
    required Map<String, String> accumulator,
    required EmvLogger logger,
  }) async {
    if (afl.isEmpty) return;

    // Each AFL entry is exactly 4 bytes
    for (var i = 0; i < afl.length; i += 4) {
      if (i + 4 > afl.length) break;

      final sfi = afl[i] >> 3;
      final first = afl[i + 1] & 0xFF;
      final last = afl[i + 2] & 0xFF;

      logger.log(
        'AFL entry found: SFI=$sfi, First Record=$first, Last Record=$last',
        name: 'SmartEmv.AflReader',
      );

      for (var record = first; record <= last; record++) {
        final command = ApduCommand.readRecord(sfi, record);

        try {
          final resBytes = await transceiver.transceive(command);
          final response = ApduResponse(resBytes);

          logger.logApdu(
            HexUtils.bytesToHex(command),
            HexUtils.bytesToHex(resBytes),
          );

          if (response.isSuccess) {
            final node = TlvParser.parse(response.payload);
            if (node != null) {
              EmvTagMapper.mapTagData(node, accumulator);
            }
          } else {
            logger.log(
              'Failed to read record $record for SFI $sfi. SW1=${response.sw1.toRadixString(16)}, SW2=${response.sw2.toRadixString(16)}',
              name: 'SmartEmv.AflReader',
            );
          }
        } catch (e, stackTrace) {
          logger.log(
            'Error reading record $record for SFI $sfi',
            name: 'SmartEmv.AflReader',
            error: e,
            stackTrace: stackTrace,
          );
          if (NfcErrorUtils.isTagLost(e)) {
            if (accumulator.containsKey('pan')) {
              break;
            }
            rethrow;
          }
        }
      }
    }
  }
}
