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

  /// Android-specific NFC reader mode flags passed to [NfcAdapter.enableReaderMode].
  ///
  /// These flags allow performance and UX tuning on Android. Common values:
  /// - `0x80` (`FLAG_READER_SKIP_NDEF_CHECK`): Skip automatic NDEF discovery for
  ///   approximately 500ms faster tag detection — highly recommended for EMV scanning.
  /// - `0x100` (`FLAG_READER_NO_PLATFORM_SOUNDS`): Suppress the system beep/vibration
  ///   on tag detection so you can provide custom audio or haptic feedback.
  ///
  /// To combine flags use bitwise OR: `0x80 | 0x100 = 0x180` (recommended for EMV).
  ///
  /// Set to `0` to use Android platform defaults (NDEF check enabled, system sounds on).
  /// Has no effect on iOS.
  ///
  /// See: https://developer.android.com/reference/android/nfc/NfcAdapter#enableReaderMode
  final int androidReaderModeFlags;

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
    this.androidReaderModeFlags = 0x80 | 0x100,
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
      fetchAdditionalData = true,
      // Skip NDEF discovery + suppress platform sounds for faster, silent EMV scanning
      androidReaderModeFlags = 0x80 | 0x100;
}
