/// Categorized error codes representing failure modes of the EMV NFC process.
enum SmartEmvErrorCode {
  /// Near Field Communication (NFC) hardware is not present on this device.
  nfcNotAvailable,

  /// Near Field Communication (NFC) is turned off in settings on this device.
  nfcNotEnabled,

  /// Failed to establish communication session with the card/tag.
  connectionFailed,

  /// The card did not return any readable card numbers (PAN) or expired.
  cardReadFailed,

  /// No valid supported AID (Application Identifier) could be selected from the card.
  noAidFound,

  /// GPO (Get Processing Options) command was rejected by the card.
  gpoFailed,

  /// Operation timed out.
  timeout,

  /// The NFC scanning session was cancelled by the user.
  userCancelled,

  /// Unknown system or protocol error occurred.
  unknown,
}

/// Custom structured exception thrown when a failure occurs during the EMV NFC card reading process.
class SmartEmvException implements Exception {
  /// High-level categorized error code.
  final SmartEmvErrorCode code;

  /// Human-readable explanation of what went wrong.
  final String message;

  /// Original lower-level exception if available.
  final Object? originalError;

  /// Creates a [SmartEmvException] with a specific error code and user-facing message.
  const SmartEmvException({
    required this.code,
    required this.message,
    this.originalError,
  });

  @override
  String toString() {
    final originalStr = originalError != null
        ? ' (Original: $originalError)'
        : '';
    return 'SmartEmvException [${code.name}]: $message$originalStr';
  }
}
