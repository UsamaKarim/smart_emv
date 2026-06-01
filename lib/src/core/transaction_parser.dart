import 'dart:typed_data';
import '../models/apdu_response.dart';
import '../models/emv_transaction.dart';
import '../transport/nfc_transceiver.dart';
import '../utils/emv_logger.dart';
import '../utils/hex_utils.dart';
import '../utils/nfc_error_utils.dart';
import 'apdu_command.dart';

/// Class for parsing transaction log formats.
class LogFormatItem {
  /// The integer value of the EMV Tag inside the log template.
  final int tag;

  /// The expected byte length of this tag's value inside log records.
  final int length;

  /// Creates a new [LogFormatItem] instance.
  const LogFormatItem(this.tag, this.length);
}

/// Decodes card transaction records indicated in log entry templates (tags 9F4D and 9F4F).
class TransactionParser {
  /// Reads transaction log files from the card using the specified log format.
  static Future<List<EmvTransaction>> readTransactions({
    required NfcTransceiver transceiver,
    required String logEntryHex,
    required String logFormatHex,
    required EmvLogger logger,
  }) async {
    final transactions = <EmvTransaction>[];

    try {
      final logEntry = HexUtils.hexToBytes(logEntryHex);
      if (logEntry.length < 2) return transactions;

      final sfi = logEntry[0];
      final recordCount = logEntry[1] & 0xFF;

      final format = logFormatHex.isNotEmpty
          ? _parseLogFormat(HexUtils.hexToBytes(logFormatHex))
          : const <LogFormatItem>[];

      logger.log(
        'Reading transactions: SFI=$sfi, Records=$recordCount',
        name: 'SmartEmv.TransactionParser',
      );

      for (var record = 1; record <= recordCount; record++) {
        final command = ApduCommand.readRecord(sfi, record);

        try {
          final resBytes = await transceiver.transceive(command);
          final response = ApduResponse(resBytes);

          if (response.isSuccess) {
            // Subtract trailing SW1/SW2 status bytes to get raw record data
            final recordData = response.payload;

            if (format.isNotEmpty) {
              final tx = _parseTransactionRecord(recordData, format);
              transactions.add(tx);
            } else {
              transactions.add(
                EmvTransaction(raw: HexUtils.bytesToHex(recordData)),
              );
            }
          }
        } catch (e, stackTrace) {
          logger.log(
            'Error reading transaction record $record',
            name: 'SmartEmv.TransactionParser',
            error: e,
            stackTrace: stackTrace,
          );
          if (NfcErrorUtils.isTagLost(e)) {
            rethrow;
          }
        }
      }
    } catch (e, stackTrace) {
      logger.log(
        'Failed to parse transactions',
        name: 'SmartEmv.TransactionParser',
        error: e,
        stackTrace: stackTrace,
      );
      if (NfcErrorUtils.isTagLost(e)) {
        rethrow;
      }
    }

    return transactions;
  }

  /// Parses the binary template detailing the format layout of each transaction.
  static List<LogFormatItem> _parseLogFormat(Uint8List formatBytes) {
    final list = <LogFormatItem>[];
    var i = 0;

    while (i < formatBytes.length) {
      var tag = formatBytes[i] & 0xFF;
      i++;

      // Multi-byte tags (bits 1-5 set to 1)
      if ((tag & 0x1F) == 0x1F) {
        if (i >= formatBytes.length) break;
        tag = (tag << 8) | (formatBytes[i] & 0xFF);
        i++;
      }

      if (i >= formatBytes.length) break;
      final len = formatBytes[i] & 0xFF;
      i++;

      list.add(LogFormatItem(tag, len));
    }
    return list;
  }

  /// Extracts specific fields from a raw transaction record based on the card's defined log format template.
  static EmvTransaction _parseTransactionRecord(
    Uint8List recordData,
    List<LogFormatItem> format,
  ) {
    var offset = 0;

    String? date;
    String? time;
    String? amount;
    String? currency;
    String? type;

    for (final item in format) {
      final tag = item.tag;
      final len = item.length;

      if (offset + len > recordData.length) break;

      final chunk = Uint8List.sublistView(recordData, offset, offset + len);
      final hexVal = HexUtils.bytesToHex(chunk);

      switch (tag) {
        case 0x9A: // Date (YYMMDD format in hex)
          if (hexVal.length >= 6) {
            final y = hexVal.substring(0, 2);
            final m = hexVal.substring(2, 4);
            final d = hexVal.substring(4, 6);
            date = '$y/$m/$d';
          } else {
            date = hexVal;
          }
          break;
        case 0x9F21: // Time (HHMMSS format in hex)
          if (hexVal.length >= 6) {
            final h = hexVal.substring(0, 2);
            final m = hexVal.substring(2, 4);
            final s = hexVal.substring(4, 6);
            time = '$h:$m:$s';
          } else {
            time = hexVal;
          }
          break;
        case 0x9F02: // Amount, Authorized (Numeric)
          final parsedLong = int.tryParse(hexVal);
          if (parsedLong != null) {
            final padded = parsedLong.toString().padLeft(3, '0');
            final cents = padded.substring(padded.length - 2);
            final major = padded.substring(0, padded.length - 2);
            amount = '$major.$cents';
          } else {
            amount = hexVal;
          }
          break;
        case 0x5F2A: // Transaction Currency Code
          currency = hexVal;
          break;
        case 0x9C: // Transaction Type
          type = hexVal;
          break;
      }
      offset += len;
    }

    return EmvTransaction(
      date: date,
      time: time,
      amount: amount,
      currency: currency,
      type: type,
      // raw is intentionally NOT set for successfully parsed records.
      // It is only populated in the fallback path (empty format) above.
    );
  }
}
