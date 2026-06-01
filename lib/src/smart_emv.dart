import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'core/emv_processor.dart';
import 'models/emv_aid.dart';
import 'models/emv_card.dart';
import 'models/smart_emv_exception.dart';
import 'smart_emv_config.dart';
import 'transport/flutter_nfc_kit_transceiver.dart';
import 'transport/nfc_transceiver.dart';
import 'utils/emv_logger.dart';

/// Main public interface for the SmartEmv NFC card reader.
class SmartEmv {
  /// Session configuration settings.
  final SmartEmvConfig config;

  /// Logger instance configured by [config.enableLogging].
  final EmvLogger _logger;

  /// Holds the reference to the active NFC transceiver during a scanning session.
  NfcTransceiver? _activeTransceiver;

  /// Creates a [SmartEmv] coordinator instance with the specified [config].
  SmartEmv({this.config = const SmartEmvConfig.defaultConfig()})
    : _logger = EmvLogger(enabled: config.enableLogging);

  /// Checks if NFC hardware is present and enabled on this device.
  Future<bool> isNfcAvailable() async {
    try {
      final state = await FlutterNfcKit.nfcAvailability;
      return state == NFCAvailability.available;
    } catch (_) {
      return false;
    }
  }

  /// Begins polling for a contactless EMV card. Once discovered, reads standard
  /// and custom fields, and returns a strongly-typed [EmvCard].
  /// Throws [SmartEmvException] if an error occurs.
  Future<EmvCard> readCard() async {
    _logger.log('Starting NFC EMV card reading session...', name: 'SmartEmv');

    // 1. Verify NFC State
    NFCAvailability nfcState;
    try {
      nfcState = await FlutterNfcKit.nfcAvailability;
    } catch (e) {
      nfcState = NFCAvailability.not_supported;
    }

    if (nfcState == NFCAvailability.not_supported) {
      throw const SmartEmvException(
        code: SmartEmvErrorCode.nfcNotAvailable,
        message: 'NFC reader hardware is not available on this device.',
      );
    } else if (nfcState == NFCAvailability.disabled) {
      throw const SmartEmvException(
        code: SmartEmvErrorCode.nfcNotEnabled,
        message:
            'NFC is turned off in settings. Please enable NFC on your device.',
      );
    }

    NfcTransceiver? transceiver;

    try {
      // 2. Poll for NFC tag (IsoDep / ISO7816 cards)
      _logger.log(
        'Polling for contactless tag. Timeout: ${config.timeoutSeconds}s',
        name: 'SmartEmv',
      );

      final tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: config.timeoutSeconds),
        iosAlertMessage: config.iosAlertMessage,
        readIso15693: false,
      );

      _logger.log(
        'Tag discovered successfully: Type=${tag.type}, ID=${tag.id}',
        name: 'SmartEmv',
      );

      // 3. Setup transceiver
      transceiver =
          config.customTransceiver ?? const FlutterNfcKitTransceiver();
      _activeTransceiver = transceiver;

      // 4. Initialize EMV Processor and execute the EMV sequence
      final processor = EmvProcessor(
        transceiver: transceiver,
        terminalConfig: config.terminalConfig,
        logger: _logger,
        fallbackAids: config.customAids ?? EmvAid.defaultAids,
        readTransactions: config.readTransactions,
        fetchAdditionalData: config.fetchAdditionalData,
      );

      final card = await processor.readCard();

      // Complete transceiver connection successfully
      try {
        await transceiver.close();
      } catch (e) {
        _logger.log(
          'Error closing transceiver gracefully: $e',
          name: 'SmartEmv',
        );
      }
      _activeTransceiver = null;

      return card;
    } on PlatformException catch (pe) {
      _logger.log(
        'Platform error occurred during NFC scan: ${pe.code} - ${pe.message}',
        name: 'SmartEmv',
        error: pe,
      );

      // Gracefully release transceiver connection
      if (transceiver != null) {
        try {
          await transceiver.close();
        } catch (_) {}
      }
      _activeTransceiver = null;

      // Map standard flutter_nfc_kit and platform error codes to SmartEmvErrorCodes
      if (pe.code == '409' || pe.code == '500') {
        if (pe.message?.toLowerCase().contains('timeout') ?? false) {
          throw SmartEmvException(
            code: SmartEmvErrorCode.timeout,
            message: 'NFC session timed out before a card was read.',
            originalError: pe,
          );
        } else if (pe.message?.toLowerCase().contains('user cancel') ?? false) {
          throw SmartEmvException(
            code: SmartEmvErrorCode.userCancelled,
            message: 'NFC scanning session was cancelled by the user.',
            originalError: pe,
          );
        }
      }

      throw SmartEmvException(
        code: SmartEmvErrorCode.connectionFailed,
        message:
            pe.message ?? 'NFC reader encountered a platform connection error.',
        originalError: pe,
      );
    } catch (e) {
      _logger.log(
        'Unexpected error reading EMV card: $e',
        name: 'SmartEmv',
        error: e,
      );

      if (transceiver != null) {
        try {
          await transceiver.close();
        } catch (_) {}
      }
      _activeTransceiver = null;

      if (e is SmartEmvException) {
        rethrow;
      }

      throw SmartEmvException(
        code: SmartEmvErrorCode.unknown,
        message: 'An unexpected error occurred during card reading.',
        originalError: e,
      );
    }
  }

  /// Cancels any ongoing NFC scanning/polling session manually.
  Future<void> stopSession() async {
    try {
      if (_activeTransceiver != null) {
        await _activeTransceiver!.close();
        _activeTransceiver = null;
        _logger.log(
          'NFC session finished/stopped successfully.',
          name: 'SmartEmv',
        );
      } else {
        // No active session to close — log and return without touching the NFC stack.
        _logger.log(
          'stopSession called but no active NFC session exists. Ignoring.',
          name: 'SmartEmv',
        );
      }
    } catch (e, stackTrace) {
      _logger.log(
        'Error stopping NFC session',
        name: 'SmartEmv',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
