import 'models/emv_aid.dart';
import 'models/terminal_config.dart';
import 'transport/nfc_transceiver.dart';

/// Configuration parameters for customizing the [SmartEmv] reading session.
class SmartEmvConfig {
  /// Terminal configuration parameters (country code, capabilities, etc.).
  final TerminalConfig terminalConfig;

  /// Custom list of AIDs to try instead of the default payment networks list.
  final List<EmvAid>? customAids;

  /// Injected custom transceiver. If null, the default `FlutterNfcKitTransceiver` is utilized.
  final NfcTransceiver? customTransceiver;

  /// If true, logs all transceive hex commands and parsing traces to developer console.
  final bool enableLogging;

  /// Total duration in seconds before the scanning session cancels automatically. Default: 30.
  final int timeoutSeconds;

  /// Message displayed to the user on the system NFC dialog sheet on iOS devices.
  final String iosAlertMessage;

  /// Whether to parse historical transaction records if present on the card. Default: true.
  final bool readTransactions;

  /// Whether to issue single GET DATA queries for supplementary card metadata. Default: true.
  final bool fetchAdditionalData;

  /// Creates a [SmartEmvConfig] instance with customizable EMV session options.
  const SmartEmvConfig({
    this.terminalConfig = const TerminalConfig.defaultConfig(),
    this.customAids,
    this.customTransceiver,
    this.enableLogging = false,
    this.timeoutSeconds = 30,
    this.iosAlertMessage =
        'Approach an EMV payment card to the back of the device.',
    this.readTransactions = true,
    this.fetchAdditionalData = true,
  });

  /// Factory creating standard default settings.
  const SmartEmvConfig.defaultConfig()
    : terminalConfig = const TerminalConfig.defaultConfig(),
      customAids = null,
      customTransceiver = null,
      enableLogging = false,
      timeoutSeconds = 30,
      iosAlertMessage =
          'Approach an EMV payment card to the back of the device.',
      readTransactions = true,
      fetchAdditionalData = true;
}
