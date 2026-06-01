import 'dart:typed_data';
import '../models/apdu_response.dart';
import '../models/emv_aid.dart';
import '../models/emv_card.dart';
import '../models/emv_transaction.dart';
import '../models/terminal_config.dart';
import '../models/tlv_node.dart';
import '../models/smart_emv_exception.dart';
import '../transport/nfc_transceiver.dart';
import '../utils/emv_logger.dart';
import '../utils/hex_utils.dart';
import '../utils/nfc_error_utils.dart';
import 'afl_reader.dart';
import 'apdu_command.dart';
import 'emv_tag_mapper.dart';
import 'pdol_builder.dart';
import 'tlv_parser.dart';
import 'transaction_parser.dart';

/// Orchestrates the standard EMV contactless card reading sequence using raw APDUs.
class EmvProcessor {
  /// Injected transceiver utilized for transmitting raw command bytes.
  final NfcTransceiver transceiver;

  /// Custom terminal configuration parameters (country, currency, capabilities).
  final TerminalConfig terminalConfig;

  /// Logger instance utilized for outputting processing traces.
  final EmvLogger logger;

  /// Priority list of Application Identifiers (AIDs) to try if PPSE fails.
  final List<EmvAid> fallbackAids;

  /// Flag indicating if transaction history records should be extracted.
  final bool readTransactions;

  /// Flag indicating if supplementary card metadata should be fetched.
  final bool fetchAdditionalData;

  /// Creates a new [EmvProcessor] instance.
  const EmvProcessor({
    required this.transceiver,
    required this.terminalConfig,
    required this.logger,
    this.fallbackAids = EmvAid.defaultAids,
    this.readTransactions = true,
    this.fetchAdditionalData = true,
  });

  /// Starts the primary EMV sequence.
  Future<EmvCard> readCard() async {
    // Step 1: Select PPSE to discover card AIDs
    logger.log('Step 1: Selecting PPSE...', name: 'SmartEmv.EmvProcessor');
    final ppseCmd = ApduCommand.selectPpse();

    List<String> discoveredAids = [];
    try {
      final resBytes = await transceiver.transceive(ppseCmd);
      final response = ApduResponse(resBytes);
      logger.logApdu(
        HexUtils.bytesToHex(ppseCmd),
        HexUtils.bytesToHex(resBytes),
      );

      if (response.isSuccess) {
        final node = TlvParser.parse(response.payload);
        if (node != null) {
          discoveredAids = _extractAidsFromPpse(node);
          logger.log(
            'PPSE Success. AIDs discovered on card: $discoveredAids',
            name: 'SmartEmv.EmvProcessor',
          );
        }
      }
    } catch (e, stackTrace) {
      logger.log(
        'PPSE Selection error or not supported by card.',
        name: 'SmartEmv.EmvProcessor',
        error: e,
        stackTrace: stackTrace,
      );
      if (_isTagLost(e)) {
        rethrow;
      }
    }

    // Step 2: Assemble the priority list of AIDs to attempt reading
    final List<EmvAid> aidsToTry = [];

    if (discoveredAids.isNotEmpty) {
      // Prioritize AIDs found in PPSE
      for (final hex in discoveredAids) {
        final known = fallbackAids.firstWhere(
          (element) => element.hex.toUpperCase() == hex.toUpperCase(),
          orElse: () => EmvAid(hex: hex, name: 'Unknown Application'),
        );
        aidsToTry.add(known);
      }
    }

    // Add rest of default/fallback AIDs to ensure we try them all if PPSE failed or missed any
    for (final fa in fallbackAids) {
      if (!aidsToTry.contains(fa)) {
        aidsToTry.add(fa);
      }
    }

    logger.log(
      'AIDs list to attempt sequence: ${aidsToTry.map((e) => e.toString()).toList()}',
      name: 'SmartEmv.EmvProcessor',
    );

    // Step 3: Loop through AIDs until a PAN is successfully parsed
    for (final targetAid in aidsToTry) {
      logger.log(
        '------------------------------------------------',
        name: 'SmartEmv.EmvProcessor',
      );
      logger.log(
        'Attempting selection for AID: $targetAid',
        name: 'SmartEmv.EmvProcessor',
      );

      final selectCmd = ApduCommand.selectAid(targetAid.hex);

      try {
        final resBytes = await transceiver.transceive(selectCmd);
        final response = ApduResponse(resBytes);
        logger.logApdu(
          HexUtils.bytesToHex(selectCmd),
          HexUtils.bytesToHex(resBytes),
        );

        if (response.isSuccess) {
          logger.log(
            'AID $targetAid Select Success!',
            name: 'SmartEmv.EmvProcessor',
          );

          final accumulator = <String, String>{};

          // Parse select response data
          final selectTlv = TlvParser.parse(response.payload);
          if (selectTlv != null) {
            EmvTagMapper.mapTagData(selectTlv, accumulator);
          }

          // Step 4: Perform Get Processing Options (GPO)
          final aflBytes = await _performGpo(response.payload, accumulator);

          if (aflBytes != null && aflBytes.isNotEmpty) {
            // Step 5: Read records from AFL (Application File Locator) table
            logger.log(
              'AFL discovered: ${HexUtils.bytesToHex(aflBytes)}. Reading records...',
              name: 'SmartEmv.EmvProcessor',
            );
            await AflReader.readAflRecords(
              transceiver: transceiver,
              afl: aflBytes,
              accumulator: accumulator,
              logger: logger,
            );
          } else {
            logger.log(
              'No AFL returned during GPO. Skipping record scanning.',
              name: 'SmartEmv.EmvProcessor',
            );
          }

          // Step 6: Attempt GET DATA for additional standard tags if requested
          if (fetchAdditionalData) {
            try {
              await _tryGetData(accumulator);
            } catch (e) {
              if (!accumulator.containsKey('pan')) {
                rethrow;
              }
              logger.log(
                'Tag lost or error during optional GET DATA. Proceeding with already parsed card data.',
                name: 'SmartEmv.EmvProcessor',
                error: e,
              );
            }
          }

          // Step 7: Read transaction history logs if available and requested
          List<EmvTransaction>? parsedTransactions;
          if (readTransactions && accumulator.containsKey('logEntry')) {
            try {
              parsedTransactions = await TransactionParser.readTransactions(
                transceiver: transceiver,
                logEntryHex: accumulator['logEntry']!,
                logFormatHex: accumulator['logFormat'] ?? '',
                logger: logger,
              );
            } catch (e) {
              if (!accumulator.containsKey('pan')) {
                rethrow;
              }
              logger.log(
                'Tag lost or error during optional transaction log reading. Proceeding with already parsed card data.',
                name: 'SmartEmv.EmvProcessor',
                error: e,
              );
            }
          }

          // Step 8: Build and validate the final EmvCard response
          if (accumulator.containsKey('pan')) {
            logger.log(
              'PAN extracted successfully! Stopping selection.',
              name: 'SmartEmv.EmvProcessor',
            );

            // Try parsing numeric fields
            final atcVal = accumulator.containsKey('atc')
                ? int.tryParse(accumulator['atc']!)
                : null;
            final pinTries = accumulator.containsKey('pinTry')
                ? int.tryParse(accumulator['pinTry']!)
                : null;
            final lastOnline = accumulator.containsKey('lastOnlineAtc')
                ? int.tryParse(accumulator['lastOnlineAtc']!)
                : null;

            // Filter out friendly keys to keep rawTags clean and avoid toMap duplication
            final rawTagsOnly = Map<String, String>.from(accumulator);
            const friendlyKeys = {
              'pan',
              'expiry',
              'cardholder',
              'preferredName',
              'label',
              'iban',
              'bic',
              'language',
              'country',
              'atc',
              'pinTry',
              'lastOnlineAtc',
              'panSequenceNumber',
              'formFactor',
              'issuerData',
              'offlineBalance',
              'applicationDefaultAction',
              'cardTransactionQualifiers',
              'transactions',
              'aid',
              // Intermediate friendly keys that must also be excluded
              'logEntry',
              'logFormat',
              'currencyCode',
            };
            rawTagsOnly.removeWhere((k, v) => friendlyKeys.contains(k));

            return EmvCard(
              pan: accumulator['pan'],
              expiry: accumulator['expiry'],
              cardholderName: accumulator['cardholder'],
              preferredName: accumulator['preferredName'],
              label: accumulator['label'] ?? targetAid.name,
              iban: accumulator['iban'],
              bic: accumulator['bic'],
              language: accumulator['language'],
              countryCode: accumulator['country'],
              currencyCode: accumulator['currencyCode'],
              atc: atcVal,
              pinTriesRemaining: pinTries,
              lastOnlineAtc: lastOnline,
              panSequenceNumber: accumulator['panSequenceNumber'],
              formFactor: accumulator['formFactor'],
              issuerData: accumulator['issuerData'],
              offlineBalance: accumulator['offlineBalance'],
              applicationDefaultAction: accumulator['applicationDefaultAction'],
              cardTransactionQualifiers:
                  accumulator['cardTransactionQualifiers'],
              transactions: parsedTransactions,
              aid: targetAid.hex,
              rawTags: rawTagsOnly,
            );
          } else {
            logger.log(
              'PAN not found in records for AID ${targetAid.name}',
              name: 'SmartEmv.EmvProcessor',
            );
          }
        } else {
          logger.log(
            'AID Select rejected with SW1=${response.sw1.toRadixString(16)}, SW2=${response.sw2.toRadixString(16)}',
            name: 'SmartEmv.EmvProcessor',
          );
        }
      } catch (e, stackTrace) {
        logger.log(
          'Exception processing AID $targetAid',
          name: 'SmartEmv.EmvProcessor',
          error: e,
          stackTrace: stackTrace,
        );
        if (_isTagLost(e)) {
          rethrow;
        }
      }
    }

    // If we exit loop without successfully reading a card
    throw const SmartEmvException(
      code: SmartEmvErrorCode.cardReadFailed,
      message: 'Failed to extract credit card details from the NFC card.',
    );
  }

  /// Sends a Get Processing Options (GPO) command to the card using standard or fallback commands.
  Future<Uint8List?> _performGpo(
    Uint8List selectPayload,
    Map<String, String> accumulator,
  ) async {
    final selectTlv = TlvParser.parse(selectPayload);
    if (selectTlv == null) return null;

    // Find PDOL (Processing Options Data Object List) Tag: 0x9F38
    final pdolNode = selectTlv.find(0x9F38);
    final pdolData = pdolNode != null
        ? PdolBuilder.buildPdolResponse(pdolNode.value, terminalConfig)
        : Uint8List(0);

    logger.log(
      'PDOL data generated: ${HexUtils.bytesToHex(pdolData)}',
      name: 'SmartEmv.EmvProcessor',
    );

    final gpoCmd = ApduCommand.getProcessingOptions(pdolData);

    try {
      final resBytes = await transceiver.transceive(gpoCmd);
      final response = ApduResponse(resBytes);
      logger.logApdu(
        HexUtils.bytesToHex(gpoCmd),
        HexUtils.bytesToHex(resBytes),
      );

      if (response.isSuccess) {
        // Parse raw tags from successful GPO response
        final gpoTlv = TlvParser.parse(response.payload);
        if (gpoTlv != null) {
          EmvTagMapper.mapTagData(gpoTlv, accumulator);
        }
        return _extractAflFromGpo(response.data);
      } else {
        // Fallback case: try empty GPO command if standard GPO failed
        if (pdolData.isEmpty) {
          logger.log(
            'GPO failed. Attempting fallback GPO...',
            name: 'SmartEmv.EmvProcessor',
          );
          final fallbackCmd = ApduCommand.getFallbackGpo();
          final fallbackBytes = await transceiver.transceive(fallbackCmd);
          final fallbackRes = ApduResponse(fallbackBytes);
          logger.logApdu(
            HexUtils.bytesToHex(fallbackCmd),
            HexUtils.bytesToHex(fallbackBytes),
          );

          if (fallbackRes.isSuccess) {
            final fallbackTlv = TlvParser.parse(fallbackRes.payload);
            if (fallbackTlv != null) {
              EmvTagMapper.mapTagData(fallbackTlv, accumulator);
            }
            return _extractAflFromGpo(fallbackRes.data);
          }
        }
      }
    } catch (e, stackTrace) {
      logger.log(
        'GPO transmission error',
        name: 'SmartEmv.EmvProcessor',
        error: e,
        stackTrace: stackTrace,
      );
      if (_isTagLost(e)) {
        rethrow;
      }
    }

    return null;
  }

  /// Extracts Afl records array from a raw GPO response.
  Uint8List? _extractAflFromGpo(Uint8List responseBytes) {
    if (responseBytes.isEmpty) return null;

    final responsePayload = responseBytes.sublist(0, responseBytes.length - 2);

    // GPO Format 1 (begins with Template Tag 0x80)
    if (responseBytes[0] == 0x80) {
      // Layout: Tag (80) + Len + AIP (2 bytes) + AFL
      if (responsePayload.length > 4) {
        return responsePayload.sublist(4);
      }
      return null;
    }
    // GPO Format 2 (begins with Constructed Template Tag 0x77)
    else if (responseBytes[0] == 0x77) {
      final tlv = TlvParser.parse(responsePayload);
      // Find Tag 0x94 (Application File Locator) in response
      final aflNode = tlv?.find(0x94);
      return aflNode?.value;
    }

    return null;
  }

  /// Extracts AIDs list from the PPSE select response.
  List<String> _extractAidsFromPpse(TlvNode node) {
    final list = <String>[];
    // Tag 4F represents Application Identifier (AID)
    final nodes = node.findAll(0x4F);
    for (final element in nodes) {
      list.add(HexUtils.bytesToHex(element.value));
    }
    return list;
  }

  /// Attempts to query additional card metadata via single GET DATA commands.
  Future<void> _tryGetData(Map<String, String> accumulator) async {
    const tagsToTry = [
      0x9F17, // PIN Try Counter
      0x9F13, // Last Online ATC
      0x9F36, // ATC
      0x9F4D, // Log Entry (SFI + record count for transaction history)
      0x5F50, // Issuer URL
      0x5F53, // IBAN
      0x5F54, // BIC
      0x9F4F, // Log Format
      0x5F34, // PAN Sequence Number
      0x9F6E, // Form Factor Indicator
      0x9F6D, // Merchant Identifier
      0x9F5D, // Available Offline Spending Amount
      0x9F52, // Application Default Action
      0x9F5B, // Issuer Script Results
      0x9F10, // Issuer Application Data
      0x5F2D, // Language Preference
      0x5F42, // Application Currency Code
    ];

    for (final tag in tagsToTry) {
      // Only request tag if it wasn't already successfully scanned in records
      final hexTag = tag.toRadixString(16).toUpperCase();
      if (accumulator.containsKey(hexTag)) continue;

      final command = ApduCommand.getData(tag);
      try {
        final resBytes = await transceiver.transceive(command);
        final response = ApduResponse(resBytes);

        if (response.isSuccess) {
          final node = TlvParser.parse(response.payload);
          if (node != null) {
            EmvTagMapper.mapTagData(node, accumulator);
          }
        }
      } catch (e) {
        if (_isTagLost(e)) {
          rethrow;
        }
      }
    }
  }

  /// Helper to check if a thrown error represents a physical/transport tag loss.
  /// Delegates to [NfcErrorUtils.isTagLost] for consistent detection across the package.
  bool _isTagLost(Object e) => NfcErrorUtils.isTagLost(e);
}
